import '../../image.dart';
import 'bmp/bmp_info.dart';

const _TYPE_ICO = 1;
const _TYPE_CUR = 2;

class IcoDecoder extends Decoder {
  InputBuffer? _input;
  IcoInfo? _icoInfo;

  @override
  bool isValidFile(List<int> bytes) {
    _input = InputBuffer(bytes);
    _icoInfo = IcoInfo._read(_input!);
    return _icoInfo != null;
  }

  @override
  DecodeInfo? startDecode(List<int> bytes) {
    _input = InputBuffer(bytes);
    _icoInfo = IcoInfo._read(_input!);
    return _icoInfo;
  }

  @override
  Animation decodeAnimation(List<int> bytes) {
    throw UnimplementedError();
  }

  @override
  Image? decodeFrame(int frame) {
    if (_input == null || _icoInfo == null || frame >= _icoInfo!.numFrames) {
      return null;
    }
    final imageInfo = _icoInfo!.images![frame];
    final imageBuffer = _input!.buffer.sublist(
        _input!.start + imageInfo.bytesOffset,
        _input!.start + imageInfo.bytesOffset + imageInfo.bytesSize);
    final png = PngDecoder();
    if (png.isValidFile(imageBuffer)) {
      return png.decodeImage(imageBuffer);
    }
    // should be bmp.
    final dummyBmpHeader = OutputBuffer(size: 14)
      ..writeUint16(BitmapFileHeader.BMP_HEADER_FILETYPE)
      ..writeUint32(imageInfo.bytesSize)
      ..writeUint32(0)
      ..writeUint32(0);
    final bmpInfo = IcoBmpInfo(InputBuffer(imageBuffer),
        fileHeader: BitmapFileHeader(InputBuffer(dummyBmpHeader.getBytes())));
    if (bmpInfo.headerSize != 40 && bmpInfo.planes != 1) {
      // invalid header.
      return null;
    }
    int offset;
    if (bmpInfo.totalColors == 0 && bmpInfo.bpp <= 8) {
      offset = /*14 +*/ 40 + 4 * (1 << bmpInfo.bpp);
    } else {
      offset = /*14 +*/ 40 + 4 * bmpInfo.totalColors;
    }
    bmpInfo.file.offset = offset;
    dummyBmpHeader.length -= 4;
    dummyBmpHeader.writeUint32(offset);
    final inp = InputBuffer(imageBuffer);
    final bmp = DibDecoder(inp, bmpInfo);
    final image = bmp.decodeFrame(0);

    if (bmpInfo.bpp >= 32) {
      return image;
    }

    final padding = 32 - bmpInfo.width % 32;
    final rowLength =
        (padding == 32 ? bmpInfo.width : bmpInfo.width + padding) ~/ 8;

    // AND bitmask
    for (var y = 0; y < bmpInfo.height; y++) {
      final line = bmpInfo.readBottomUp ? y : image.height - 1 - y;
      final row = inp.readBytes(rowLength);
      for (var x = 0; x < bmpInfo.width;) {
        final b = row.readByte();
        for (var j = 7; j > -1 && x < bmpInfo.width; j--) {
          if (b & (1 << j) != 0) {
            // just set the pixel to completely transparent.
            image.setPixelRgba(x, line, 0, 0, 0, 0);
          }
          x++;
        }
      }
    }
    return image;
  }

  /// decodes the largest frame.
  Image? decodeImageLargest(List<int> bytes) {
    final info = startDecode(bytes);
    if (info == null) {
      return null;
    }
    var largestFrame = 0;
    var largestSize = 0;
    for (var i = 0; i < _icoInfo!.images!.length; i++) {
      final image = _icoInfo!.images![i];
      final size = image.width * image.height;
      if (size > largestSize) {
        largestSize = size;
        largestFrame = i;
      }
    }
    return decodeFrame(largestFrame);
  }

  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    final info = startDecode(bytes);
    if (info == null) {
      return null;
    }
    return decodeFrame(frame);
  }

  @override
  int numFrames() => _icoInfo?.numFrames ?? 0;
}

class IcoInfo extends DecodeInfo {
  IcoInfo({this.type, required this.numFrames, this.images});

  static IcoInfo? _read(InputBuffer input) {
    if (input.readUint16() != 0) {
      return null;
    }
    final type = input.readUint16();
    if (![_TYPE_ICO, _TYPE_CUR].contains(type)) {
      return null;
    }

    if (type == _TYPE_CUR) {
      // we currently do not support CUR format.
      return null;
    }

    final imageCount = input.readUint16();

    final images = Iterable.generate(
        imageCount,
        (e) => IcoInfoImage(
              width: input.readByte(),
              height: input.readByte(),
              colorPalette: input.readByte(),
              // ignore 1 byte
              colorPlanes: (input..skip(1)).readUint16(),
              bitsPerPixel: input.readUint16(),
              bytesSize: input.readUint32(),
              bytesOffset: input.readUint32(),
            )).toList();

    return IcoInfo(
      type: type,
      numFrames: imageCount,
      images: images,
    );
  }

  final int? type;

  @override
  final int numFrames;
  final List<IcoInfoImage>? images;
}

class IcoInfoImage {
  IcoInfoImage(
      {required this.width,
      required this.height,
      required this.colorPalette,
      required this.bytesSize,
      required this.bytesOffset,
      required this.colorPlanes,
      required this.bitsPerPixel});

  final int width;
  final int height;
  final int colorPalette;
  final int bytesSize;
  final int bytesOffset;

  final int colorPlanes;
  final int bitsPerPixel;
}

class IcoBmpInfo extends BmpInfo {
  IcoBmpInfo(InputBuffer p, {BitmapFileHeader? fileHeader})
      : super(p, fileHeader: fileHeader);

  @override
  int get height => super.height ~/ 2;

  @override
  bool get ignoreAlphaChannel =>
      headerSize == 40 && bpp == 32 ? false : super.ignoreAlphaChannel;
}
