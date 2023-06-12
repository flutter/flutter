/// Provides information about the image being decoded.
abstract class DecodeInfo {
  /// The width of the image canvas.
  int width = 0;

  /// The height of the image canvas.
  int height = 0;

  /// The suggested background color of the canvas.
  int backgroundColor = 0xffffffff;

  /// The number of frames that can be decoded.
  int get numFrames;
}
