part of flutter_sprites;

/// Defines the shape of a  [PhysicsBody].
abstract class PhysicsShape {

  box2d.Shape _b2Shape;

  Object userObject;

  box2d.Shape getB2Shape(PhysicsWorld node, double scale) {
    if (_b2Shape == null) {
      _b2Shape = _createB2Shape(node, scale);
    }
    return _b2Shape;
  }

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale);

  void _invalidate() {
    _b2Shape = null;
  }
}

/// Defines a circle shape with a given center [point] and [radius].
///
///     var shape = PhysicsShapeCircle(Point.origin, 20.0);
class PhysicsShapeCircle extends PhysicsShape {
  PhysicsShapeCircle(this.point, this.radius);

  final Point point;
  final double radius;

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale) {
    box2d.CircleShape shape = new box2d.CircleShape();
    shape.p.x = scale * point.x / node.b2WorldToNodeConversionFactor;
    shape.p.y = scale * point.y / node.b2WorldToNodeConversionFactor;
    shape.radius = scale * radius / node.b2WorldToNodeConversionFactor;
    return shape;
  }
}

/// Defines a polygon shape from a list of [points];
///
///     var points = [
///       new Point(-10.0, 0.0),
///       new Point(0.0, 10.0),
///       new Point(10.0, 0.0)
///     ];
///     var shape = new PhysicsShapePolygon(points);
class PhysicsShapePolygon extends PhysicsShape {
  PhysicsShapePolygon(this.points);

  final List<Point> points;

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale) {
    List<Vector2> vectors = <Vector2>[];
    for (Point point in points) {
      Vector2 vec = new Vector2(
        scale * point.x / node.b2WorldToNodeConversionFactor,
        scale * point.y / node.b2WorldToNodeConversionFactor
      );
      vectors.add(vec);
    }

    box2d.PolygonShape shape = new box2d.PolygonShape();
    shape.set(vectors, vectors.length);
    return shape;
  }
}

/// Defines a box shape from a [width] and [height].
///
/// var shape = new PhysicsShapeBox(50.0, 100.0);
class PhysicsShapeBox extends PhysicsShape {
  PhysicsShapeBox(
    this.width,
    this.height, [
      this.center = Point.origin,
      this.rotation = 0.0
  ]);

  final double width;
  final double height;
  final Point center;
  final double rotation;

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale) {
    box2d.PolygonShape shape = new box2d.PolygonShape();
    shape.setAsBox(
      scale * width / node.b2WorldToNodeConversionFactor,
      scale * height / node.b2WorldToNodeConversionFactor,
      new Vector2(
        scale * center.x / node.b2WorldToNodeConversionFactor,
        scale * center.y / node.b2WorldToNodeConversionFactor
      ),
      radians(rotation)
    );
    return shape;
  }
}

/// Defines a chain shape from a set of [points]. This can be used to create
/// a continuous chain of edges or, if [loop] is set to true, concave polygons.
///
///     var points = [
///       new Point(-10.0, 0.0),
///       new Point(0.0, 10.0),
///       new Point(10.0, 0.0)
///     ];
///     var shape = new PhysicsShapeChain(points);
class PhysicsShapeChain extends PhysicsShape {
  PhysicsShapeChain(this.points, [this.loop=false]);

  final List<Point> points;
  final bool loop;

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale) {
    List<Vector2> vectors = <Vector2>[];
    for (Point point in points) {
      Vector2 vec = new Vector2(
        scale * point.x / node.b2WorldToNodeConversionFactor,
        scale * point.y / node.b2WorldToNodeConversionFactor
      );
      vectors.add(vec);
    }

    box2d.ChainShape shape = new box2d.ChainShape();
    if (loop)
      shape.createLoop(vectors, vectors.length);
    else
      shape.createChain(vectors, vectors.length);
    return shape;
  }
}

/// Defines a single edge line shape from [pointA] to [pointB].
///
///     var shape = new PhysicsShapeEdge(
///       new Point(20.0, 20.0),
///       new Point(50.0, 20.0)
///     );
class PhysicsShapeEdge extends PhysicsShape {
  PhysicsShapeEdge(this.pointA, this.pointB);

  final Point pointA;
  final Point pointB;

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale) {
    box2d.EdgeShape shape = new box2d.EdgeShape();
    shape.set(
      new Vector2(
        scale * pointA.x / node.b2WorldToNodeConversionFactor,
        scale * pointA.y / node.b2WorldToNodeConversionFactor
      ),
      new Vector2(
        scale * pointB.x / node.b2WorldToNodeConversionFactor,
        scale * pointB.y / node.b2WorldToNodeConversionFactor
      )
    );
    return shape;
  }
}

/// A group combines several [shapes] into a single shape.
///
///     var s0 = new PhysicsShapeCircle(new Point(-10.0, 0.0), 20.0);
///     var s1 = new PhysicsShapeCircle(new Point(10.0, 0.0), 20.0);
///     var shape = new PhysicsShapeGroup([s0, s1]);
class PhysicsShapeGroup extends PhysicsShape {

  PhysicsShapeGroup(this.shapes);

  final List<PhysicsShape> shapes;

  box2d.Shape _createB2Shape(PhysicsWorld node, double scale) {
    return null;
  }

  void _invalidate() {
    for (PhysicsShape shape in shapes) {
      shape._invalidate();
    }
  }
}
