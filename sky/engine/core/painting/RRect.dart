part of dart_ui;

// A rounded rectangle.
class RRect {
  RRect();

  /// Initialize with the same radii for all four corners.
  RRect.fromRectXY(Rect rect, double xRadius, double yRadius) {
    _value
      ..[0] = rect.left
      ..[1] = rect.top
      ..[2] = rect.right
      ..[3] = rect.bottom
      ..[4] = xRadius
      ..[5] = yRadius;
  }

  final Float32List _value = new Float32List(6);

  /// Returns a new RRect translated by the given offset.
  RRect shift(Offset offset) {
    result = new RRect();
    result._value
      ..[0] = _value[0] + offset.dx
      ..[1] = _value[1] + offset.dy
      ..[2] = _value[2] + offset.dx
      ..[3] = _value[3] + offset.dy
      ..[4] = _value[4]
      ..[5] = _value[5];
    return result;
  }
}
