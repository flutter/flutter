import '../../image.dart';

class TiffDecoder extends Decoder {
  TiffInfo? info;
  ExifData? exif;

  /// Is the given file a valid TIFF image?
  @override
  bool isValidFile(List<int> data) => _readHeader(InputBuffer(data)) != null;

  /// Validate the file is a TIFF image and get information about it.
  /// If the file is not a valid TIFF image, null is returned.
  @override
  TiffInfo? startDecode(List<int> bytes) {
    _input = InputBuffer(bytes);
    info = _readHeader(_input);
    if (info != null) {
      exif = ExifData.fromInputBuffer(InputBuffer(bytes));
    }
    return info;
  }

  /// How many frames are available to be decoded. [startDecode] should have
  /// been called first. Non animated image files will have a single frame.
  @override
  int numFrames() => info != null ? info!.images.length : 0;

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0. An [AnimationFrame]
  /// is returned, which provides the image, and top-left coordinates of the
  /// image, as animated frames may only occupy a subset of the canvas.
  @override
  Image? decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    final image = info!.images[frame].decode(_input);
    if (exif != null) {
      image.exif = exif!;
    }
    return image;
  }

  HdrImage? decodeFrameHdr(int frame) {
    if (info == null) {
      return null;
    }
    return info!.images[frame].decodeHdr(_input);
  }

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    _input = InputBuffer(bytes);

    info = _readHeader(_input);
    if (info == null) {
      return null;
    }

    final image = info!.images[frame].decode(_input);
    image.exif = ExifData.fromInputBuffer(InputBuffer(bytes));

    return image;
  }

  @override
  HdrImage? decodeHdrImage(List<int> bytes, {int frame = 0}) {
    _input = InputBuffer(bytes);

    info = _readHeader(_input);
    if (info == null) {
      return null;
    }

    final image = info!.images[frame].decodeHdr(_input);
    image.exif = ExifData.fromInputBuffer(InputBuffer(bytes));

    return image;
  }

  /// Decode all of the frames from an animation. If the file is not an
  /// animation, a single frame animation is returned. If there was a problem
  /// decoding the file, null is returned.
  @override
  Animation? decodeAnimation(List<int> data) {
    if (startDecode(data) == null) {
      return null;
    }

    final anim = Animation();
    anim.width = info!.width;
    anim.height = info!.height;
    anim.frameType = FrameType.page;
    for (var i = 0, len = numFrames(); i < len; ++i) {
      final image = decodeFrame(i);
      anim.addFrame(image!);
    }

    return anim;
  }

  // Read the TIFF header and IFD blocks.
  TiffInfo? _readHeader(InputBuffer p) {
    final info = TiffInfo();
    final byteOrder = p.readUint16();
    if (byteOrder != TIFF_LITTLE_ENDIAN && byteOrder != TIFF_BIG_ENDIAN) {
      return null;
    }

    if (byteOrder == TIFF_BIG_ENDIAN) {
      p.bigEndian = true;
      info.bigEndian = true;
    } else {
      p.bigEndian = false;
      info.bigEndian = false;
    }

    info.signature = p.readUint16();
    if (info.signature != TIFF_SIGNATURE) {
      return null;
    }

    var offset = p.readUint32();
    info.ifdOffset = offset;

    final p2 = InputBuffer.from(p);
    p2.offset = offset;

    while (offset != 0) {
      TiffImage img;
      try {
        img = TiffImage(p2);
        if (!img.isValid) {
          break;
        }
      } catch (error) {
        break;
      }
      info.images.add(img);
      if (info.images.length == 1) {
        info.width = info.images[0].width;
        info.height = info.images[0].height;
      }

      offset = p2.readUint32();
      if (offset != 0) {
        p2.offset = offset;
      }
    }

    return info.images.isNotEmpty ? info : null;
  }

  late InputBuffer _input;

  static const TIFF_SIGNATURE = 42;
  static const TIFF_LITTLE_ENDIAN = 0x4949;
  static const TIFF_BIG_ENDIAN = 0x4d4d;
}
