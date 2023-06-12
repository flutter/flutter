import '../color/color.dart';

/// Provides information about the image being decoded.
abstract class DecodeInfo {
  /// The width of the image canvas.
  int get width;

  /// The height of the image canvas.
  int get height;

  /// The suggested background color of the canvas.
  Color? get backgroundColor;

  /// The number of frames that can be decoded.
  int get numFrames;
}
