part of sprites;

abstract class NodeWithSize extends Node {
  Size size;
  Point pivot;

  NodeWithSize() {
    size = new Size(0.0, 0.0);
    pivot = new Point(0.0, 0.0);
  }

  NodeWithSize.withSize(Size size, [Point pivot]);

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
