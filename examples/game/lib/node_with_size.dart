part of sprites;

abstract class NodeWithSize extends Node {
  Size size;
  Point pivot;

  NodeWithSize() {
    size = Size.zero;
    pivot = Point.origin;
  }

  NodeWithSize.withSize(Size this.size, [Point this.pivot]) {
    if (pivot == null) pivot = Point.origin;
  }

  void applyTransformForPivot(PictureRecorder canvas) {
    if (pivot.x != 0 || pivot.y != 0) {
      double pivotInPointsX = size.width * pivot.x;
      double pivotInPointsY = size.height * pivot.y;
      canvas.translate(-pivotInPointsX, -pivotInPointsY);
    }
  }

  bool hitTest (Point nodePoint) {

    double minX = -size.width * pivot.x;
    double minY = -size.height * pivot.y;
    double maxX = minX + size.width;
    double maxY = minY + size.height;
    return (nodePoint.x >= minX && nodePoint.x < maxX &&
            nodePoint.y >= minY && nodePoint.y < maxY);
  }
}
