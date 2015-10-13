part of flutter_sprites;

abstract class PhysicsShape {

  box2d.Shape _b2Shape;

  Object userObject;

  box2d.Shape getB2Shape(PhysicsNode node) {
    if (_b2Shape == null) {
      _b2Shape = _createB2Shape(node);
    }
    return _b2Shape;
  }

  box2d.Shape _createB2Shape(PhysicsNode node);
}

class PhysicsShapeCircle extends PhysicsShape {
  PhysicsShapeCircle(this.point, this.radius);

  final Point point;
  final double radius;

  box2d.Shape _createB2Shape(PhysicsNode node) {
    box2d.CircleShape shape = new box2d.CircleShape();
    shape.p.x = point.x / node.b2WorldToNodeConversionFactor;
    shape.p.y = point.y / node.b2WorldToNodeConversionFactor;
    shape.radius = radius / node.b2WorldToNodeConversionFactor;
    return shape;
  }
}

class PhysicsShapePolygon extends PhysicsShape {

  PhysicsShapePolygon(this.points);

  final List<Point> points;

  box2d.Shape _createB2Shape(PhysicsNode node) {
    List<Vector2> vectors = [];
    for (Point point in points) {
      Vector2 vec = new Vector2(
        point.x / node.b2WorldToNodeConversionFactor,
        point.y / node.b2WorldToNodeConversionFactor
      );
      vectors.add(vec);
    }

    box2d.PolygonShape shape = new box2d.PolygonShape();
    shape.set(vectors, vectors.length);
    return shape;
  }
}

class PhysicsShapeGroup extends PhysicsShape {

  PhysicsShapeGroup(this.shapes);

  final List<PhysicsShape> shapes;

  box2d.Shape _createB2Shape(PhysicsNode node) {
    return null;
  }
}
