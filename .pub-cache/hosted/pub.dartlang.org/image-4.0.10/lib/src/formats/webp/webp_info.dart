import 'dart:typed_data';

import '../../color/color.dart';
import '../../util/_internal.dart';
import '../../util/input_buffer.dart';
import '../decode_info.dart';
import 'webp_frame.dart';

enum WebPFormat { undefined, lossy, lossless, animated }

/// Features gathered from the bitstream
class WebPInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  @override
  Color? backgroundColor;

  /// True if the bitstream contains an alpha channel.
  bool hasAlpha = false;

  /// True if the bitstream is an animation.
  bool hasAnimation = false;

  /// 0 = undefined (/mixed), 1 = lossy, 2 = lossless, 3 = animated
  WebPFormat format = WebPFormat.undefined;

  /// ICCP data.
  Uint8List? iccp;

  /// EXIF data string.
  String exif = '';

  /// XMP data string.
  String xmp = '';

  /// How many times the animation should loop.
  int animLoopCount = 0;

  /// Information about each animation frame.
  List<WebPFrame> frames = [];

  @override
  int get numFrames => frames.length;

  int _frame = 0;
  int _numFrames = 0;

  InputBuffer? _alphaData;
  int _alphaSize = 0;
  int _vp8Position = 0;
  int _vp8Size = 0;
}

@internal
class InternalWebPInfo extends WebPInfo {
  int get frame => _frame;
  set frame(int value) => _frame = value;

  @override
  int get numFrames => _numFrames;
  set numFrames(int value) => _numFrames = value;

  InputBuffer? get alphaData => _alphaData;
  set alphaData(InputBuffer? buffer) => _alphaData = buffer;

  int get alphaSize => _alphaSize;
  set alphaSize(int value) => _alphaSize = value;

  int get vp8Position => _vp8Position;
  set vp8Position(int value) => _vp8Position = value;

  int get vp8Size => _vp8Size;
  set vp8Size(int value) => _vp8Size = value;
}
