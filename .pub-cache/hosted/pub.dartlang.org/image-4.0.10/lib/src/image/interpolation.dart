/// Interpolation method to use when resizing images.
enum Interpolation {
  /// Select the closest pixel. Fastest, lowest quality.
  nearest,

  /// Linearly blend between the neighboring pixels.
  linear,

  /// Cubic blend between the neighboring pixels. Slowest, highest Quality.
  cubic,

  /// Average the colors of the neighboring pixels.
  average
}
