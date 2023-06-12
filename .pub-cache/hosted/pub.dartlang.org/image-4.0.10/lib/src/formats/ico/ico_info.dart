import '../../color/color.dart';
import '../../util/input_buffer.dart';
import '../bmp/bmp_info.dart';
import '../decode_info.dart';

enum IcoType { invalid, ico, cur }

class IcoInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  final IcoType type;
  @override
  final int numFrames;
  @override
  Color? get backgroundColor => null;
  final List<IcoInfoImage> images;

  IcoInfo({required this.type, required this.numFrames, required this.images});

  static IcoInfo? read(InputBuffer input) {
    if (input.readUint16() != 0) {
      return null;
    }
    final t = input.readUint16();
    if (t >= IcoType.values.length) {
      return null;
    }
    final type = IcoType.values[t];

    if (type == IcoType.cur) {
      // CUR format not yet supported.
      return null;
    }

    final imageCount = input.readUint16();

    final images = List<IcoInfoImage>.generate(
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
            ));

    return IcoInfo(type: type, numFrames: imageCount, images: images);
  }
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
  IcoBmpInfo(InputBuffer p, {BmpFileHeader? fileHeader})
      : super(p, fileHeader: fileHeader);

  @override
  int get height => super.height ~/ 2;

  @override
  bool get ignoreAlphaChannel =>
      !(headerSize == 40 && bitsPerPixel == 32) && super.ignoreAlphaChannel;
}
