import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode an image to the PNG format.
class WebPEncoder extends Encoder {
  static const LOSSLESS = 0;
  static const LOSSY = 1;

  int format;
  num quality;

  /// [format] can be [LOSSY] or [LOSSLESS].
  /// [quality] is controls lossy compression, in the range
  /// 0 (smallest file) and 100 (biggest).
  WebPEncoder({this.format = LOSSY, this.quality = 100});

  /// Add a frame to be encoded. Call [finish] to encode the added frames.
  /// If only one frame is added, a single-image WebP is encoded; otherwise
  /// if there are more than one frame, a multi-frame animated WebP is encoded.
  void addFrame(Image image, {int? duration}) {
    if (output == null) {
      output = OutputBuffer();

      if (duration != null) {
        delay = duration;
      }
      _lastImage = _encodeImage(image);
      _width = image.width;
      _height = image.height;
      return;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
    }

    _addImage(_lastImage, _width, _height);
    _encodedFrames++;

    if (duration != null) {
      delay = duration;
    }

    _lastImage = _encodeImage(image);
  }

  /// Encode the images that were added with [addFrame].
  List<int>? finish() {
    List<int>? bytes;
    if (output == null) {
      return bytes;
    }

    /*if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
    } else {
      _writeGraphicsCtrlExt();
    }

    _addImage(_lastImage, _width, _height, _lastColorMap.colorMap, 256);

    output.writeByte(TERMINATE_RECORD_TYPE);

    _lastImage = null;
    _encodedFrames = 0;*/

    bytes = output!.getBytes();
    output = null;

    return bytes;
  }

  /// Encode a single frame image.
  @override
  List<int> encodeImage(Image image) {
    addFrame(image);
    return finish()!;
  }

  /// Does this encoder support animation?
  @override
  bool get supportsAnimation => true;

  /// Encode an animation.
  @override
  List<int>? encodeAnimation(Animation anim) {
    for (var f in anim) {
      addFrame(f, duration: f.duration);
    }
    return finish();
  }

  Uint8List? _encodeImage(Image image) => null;

  void _writeHeader(int? width, int? height) {}

  void _addImage(Uint8List? image, int? width, int? height) {}

  OutputBuffer? output;
  int? delay;
  Uint8List? _lastImage;
  int? _width;
  int? _height;
  int _encodedFrames = 0;
}
