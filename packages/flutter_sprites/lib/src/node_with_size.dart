part of flutter_sprites;

/// The super class of any [Node] that has a size.
///
/// NodeWithSize adds the ability for a node to have a size and a pivot point.
class NodeWithSize extends Node {

  /// Changing the size will affect the size of the rendering of the node.
  ///
  ///     myNode.size = new Size(1024.0, 1024.0);
  Size size;

  /// The normalized point which the node is transformed around.
  ///
  ///     // Position myNode from is middle top
  ///     myNode.pivot = new Point(0.5, 0.0);
  Point pivot;

  /// Creates a new NodeWithSize.
  ///
  /// The default [size] is zero and the default [pivot] point is the origin. Subclasses may change the default values.
  ///
  ///     var myNodeWithSize = new NodeWithSize(new Size(1024.0, 1024.0));
  NodeWithSize(this.size) {
    if (size == null)
      size = Size.zero;
    pivot = Point.origin;
  }

  /// Call this method in your [paint] method if you want the origin of your drawing to be the top left corner of the
  /// node's bounding box.
  ///
  /// If you use this method you will need to save and restore your canvas at the beginning and
  /// end of your [paint] method.
  ///
  ///     void paint(Canvas canvas) {
  ///       canvas.save();
  ///       applyTransformForPivot(canvas);
  ///
  ///       // Do painting here
  ///
  ///       canvas.restore();
  ///     }
  void applyTransformForPivot(Canvas canvas) {
    if (pivot.x != 0 || pivot.y != 0) {
      double pivotInPointsX = size.width * pivot.x;
      double pivotInPointsY = size.height * pivot.y;
      canvas.translate(-pivotInPointsX, -pivotInPointsY);
    }
  }

  bool isPointInside (Point nodePoint) {

    double minX = -size.width * pivot.x;
    double minY = -size.height * pivot.y;
    double maxX = minX + size.width;
    double maxY = minY + size.height;
    return (nodePoint.x >= minX && nodePoint.x < maxX &&
            nodePoint.y >= minY && nodePoint.y < maxY);
  }
}
