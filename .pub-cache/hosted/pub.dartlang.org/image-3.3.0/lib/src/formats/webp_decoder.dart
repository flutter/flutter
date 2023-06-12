import '../animation.dart';
import '../color.dart';
import '../image.dart';
import '../transform/copy_into.dart';
import '../util/input_buffer.dart';
import 'decoder.dart';
import 'webp/vp8.dart';
import 'webp/vp8l.dart';
import 'webp/webp_frame.dart';
import 'webp/webp_info.dart';

/// Decode a WebP formatted image. This supports lossless (vp8l), lossy (vp8),
/// lossy+alpha, and animated WebP images.
class WebPDecoder extends Decoder {
  InternalWebPInfo? _info;

  WebPDecoder([List<int>? bytes]) {
    if (bytes != null) {
      startDecode(bytes);
    }
  }

  WebPInfo? get info => _info;

  /// Is the given file a valid WebP image?
  @override
  bool isValidFile(List<int> bytes) {
    _input = InputBuffer(bytes);
    if (!_getHeader(_input!)) {
      return false;
    }
    return true;
  }

  /// How many frames are available to decode?
  ///
  /// You should have prepared the decoder by either passing the file bytes
  /// to the constructor, or calling getInfo.
  @override
  int numFrames() => (_info != null) ? _info!.numFrames : 0;

  /// Validate the file is a WebP image and get information about it.
  /// If the file is not a valid WebP image, null is returned.
  @override
  WebPInfo? startDecode(List<int> bytes) {
    _input = InputBuffer(bytes);

    if (!_getHeader(_input!)) {
      return null;
    }

    _info = InternalWebPInfo();
    if (!_getInfo(_input!, _info)) {
      return null;
    }

    switch (_info!.format) {
      case WebPInfo.FORMAT_ANIMATED:
        _info!.numFrames = _info!.frames.length;
        return _info;
      case WebPInfo.FORMAT_LOSSLESS:
        _input!.offset = _info!.vp8Position;
        final vp8l = VP8L(_input!, _info!);
        if (!vp8l.decodeHeader()) {
          return null;
        }
        _info!.numFrames = _info!.frames.length;
        return _info;
      case WebPInfo.FORMAT_LOSSY:
        _input!.offset = _info!.vp8Position;
        final vp8 = VP8(_input!, _info!);
        if (!vp8.decodeHeader()) {
          return null;
        }
        _info!.numFrames = _info!.frames.length;
        return _info;
    }

    return null;
  }

  @override
  Image? decodeFrame(int frame) {
    if (_input == null || _info == null) {
      return null;
    }

    if (_info!.hasAnimation) {
      if (frame >= _info!.frames.length || frame < 0) {
        return null;
      }

      final f = _info!.frames[frame] as InternalWebPFrame;
      final frameData = _input!.subset(f.frameSize, position: f.framePosition);

      return _decodeFrame(frameData, frame: frame);
    }

    if (_info!.format == WebPInfo.FORMAT_LOSSLESS) {
      final data = _input!.subset(_info!.vp8Size, position: _info!.vp8Position);
      return VP8L(data, _info!).decode();
    } else if (_info!.format == WebPInfo.FORMAT_LOSSY) {
      final data = _input!.subset(_info!.vp8Size, position: _info!.vp8Position);
      return VP8(data, _info!).decode();
    }

    return null;
  }

  /// Decode a WebP formatted file stored in [bytes] into an Image.
  /// If it's not a valid webp file, null is returned.
  /// If the webp file stores animated frames, only the first image will
  /// be returned. Use [decodeAnimation] to decode the full animation.
  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    startDecode(bytes);
    _info!.frame = 0;
    _info!.numFrames = 1;
    return decodeFrame(frame);
  }

  /// Decode all of the frames of an animated webp. For single image webps,
  /// this will return an animation with a single frame.
  @override
  Animation? decodeAnimation(List<int> bytes) {
    if (startDecode(bytes) == null) {
      return null;
    }

    final anim = Animation();
    anim.width = _info!.width;
    anim.height = _info!.height;
    anim.loopCount = _info!.animLoopCount;

    if (_info!.hasAnimation) {
      var lastImage = Image(_info!.width, _info!.height);
      for (var i = 0; i < _info!.numFrames; ++i) {
        _info!.frame = i;
        lastImage = Image.from(lastImage);

        final frame = _info!.frames[i];
        final image = decodeFrame(i);
        if (image == null) {
          return null;
        }

        if (frame.clearFrame) {
          lastImage.fill(0);
        }
        copyInto(lastImage, image, dstX: frame.x, dstY: frame.y);

        lastImage.duration = frame.duration;
        anim.addFrame(lastImage);
      }
    } else {
      final image = decodeImage(bytes);
      if (image == null) {
        return null;
      }

      anim.addFrame(image);
    }

    return anim;
  }

  Image? _decodeFrame(InputBuffer input, {int frame = 0}) {
    final webp = InternalWebPInfo();
    if (!_getInfo(input, webp)) {
      return null;
    }

    if (webp.format == 0) {
      return null;
    }

    webp.frame = _info!.frame;
    webp.numFrames = _info!.numFrames;

    if (webp.hasAnimation) {
      if (frame >= webp.frames.length || frame < 0) {
        return null;
      }
      final f = webp.frames[frame] as InternalWebPFrame;
      final frameData = input.subset(f.frameSize, position: f.framePosition);

      return _decodeFrame(frameData, frame: frame);
    } else {
      final data = input.subset(webp.vp8Size, position: webp.vp8Position);
      if (webp.format == WebPInfo.FORMAT_LOSSLESS) {
        return VP8L(data, webp).decode();
      } else if (webp.format == WebPInfo.FORMAT_LOSSY) {
        return VP8(data, webp).decode();
      }
    }

    return null;
  }

  bool _getHeader(InputBuffer input) {
    // Validate the webp format header
    var tag = input.readString(4);
    if (tag != 'RIFF') {
      return false;
    }

    /*int fileSize =*/ input.readUint32();

    tag = input.readString(4);
    if (tag != 'WEBP') {
      return false;
    }

    return true;
  }

  bool _getInfo(InputBuffer input, InternalWebPInfo? webp) {
    var found = false;
    while (!input.isEOS && !found) {
      final tag = input.readString(4);
      final size = input.readUint32();
      // For odd sized chunks, there's a 1 byte padding at the end.
      final diskSize = ((size + 1) >> 1) << 1;
      final p = input.position;

      switch (tag) {
        case 'VP8X':
          if (!_getVp8xInfo(input, webp)) {
            return false;
          }
          break;
        case 'VP8 ':
          webp!.vp8Position = input.position;
          webp.vp8Size = size;
          webp.format = WebPInfo.FORMAT_LOSSY;
          found = true;
          break;
        case 'VP8L':
          webp!.vp8Position = input.position;
          webp.vp8Size = size;
          webp.format = WebPInfo.FORMAT_LOSSLESS;
          found = true;
          break;
        case 'ALPH':
          webp!.alphaData =
              InputBuffer(input.buffer, bigEndian: input.bigEndian);
          webp.alphaData!.offset = input.offset;
          webp.alphaSize = size;
          input.skip(diskSize);
          break;
        case 'ANIM':
          webp!.format = WebPInfo.FORMAT_ANIMATED;
          if (!_getAnimInfo(input, webp)) {
            return false;
          }
          break;
        case 'ANMF':
          if (!_getAnimFrameInfo(input, webp, size)) {
            return false;
          }
          break;
        case 'ICCP':
          webp!.iccp = input.readBytes(size).toUint8List();
          break;
        case 'EXIF':
          webp!.exif = input.readString(size);
          break;
        case 'XMP ':
          webp!.xmp = input.readString(size);
          break;
        default:
          print('UNKNOWN WEBP TAG: $tag');
          input.skip(diskSize);
          break;
      }

      final remainder = diskSize - (input.position - p);
      if (remainder > 0) {
        input.skip(remainder);
      }
    }

    /// The alpha flag might not have been set, but it does in fact have alpha
    /// if there is an ALPH chunk.
    if (!webp!.hasAlpha) {
      webp.hasAlpha = webp.alphaData != null;
    }

    return webp.format != 0;
  }

  bool _getVp8xInfo(InputBuffer input, WebPInfo? webp) {
    final b = input.readByte();
    if ((b & 0xc0) != 0) {
      return false;
    }
    //int icc = (b >> 5) & 0x1;
    final alpha = (b >> 4) & 0x1;
    //int exif = (b >> 3) & 0x1;
    //int xmp = (b >> 2) & 0x1;
    final a = (b >> 1) & 0x1;

    if (b & 0x1 != 0) {
      return false;
    }

    if (input.readUint24() != 0) {
      return false;
    }
    final w = input.readUint24() + 1;
    final h = input.readUint24() + 1;

    webp!.width = w;
    webp.height = h;
    webp.hasAnimation = a != 0;
    webp.hasAlpha = alpha != 0;

    return true;
  }

  bool _getAnimInfo(InputBuffer input, WebPInfo webp) {
    final c = input.readUint32();
    webp.animLoopCount = input.readUint16();

    // Color is stored in blue,green,red,alpha order.
    final a = getRed(c);
    final r = getGreen(c);
    final g = getBlue(c);
    final b = getAlpha(c);
    webp.backgroundColor = getColor(r, g, b, a);
    return true;
  }

  bool _getAnimFrameInfo(InputBuffer input, WebPInfo? webp, int size) {
    final frame = InternalWebPFrame(input, size);
    if (!frame.isValid) {
      return false;
    }
    webp!.frames.add(frame);
    return true;
  }

  InputBuffer? _input;
}
