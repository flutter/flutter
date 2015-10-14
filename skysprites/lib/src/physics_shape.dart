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

  box2d.Shape _createB2Shape(PhysicsNode node) {
    box2d.PolygonShape shape = new box2d.PolygonShape();
    shape.setAsBox(
      width / node.b2WorldToNodeConversionFactor,
      height / node.b2WorldToNodeConversionFactor,
      new Vector2(
        center.x / node.b2WorldToNodeConversionFactor,
        center.y / node.b2WorldToNodeConversionFactor
      ),
      radians(rotation)
    );
    return shape;
  }
}

class PhysicsShapeChain extends PhysicsShape {
  PhysicsShapeChain(this.points, [this.loop=false]);

  final List<Point> points;
  final bool loop;

  box2d.Shape _createB2Shape(PhysicsNode node) {
    List<Vector2> vectors = [];
    for (Point point in points) {
      Vector2 vec = new Vector2(
        point.x / node.b2WorldToNodeConversionFactor,
        point.y / node.b2WorldToNodeConversionFactor
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

class PhysicsShapeEdge extends PhysicsShape {
  PhysicsShapeEdge(this.pointA, this.pointB);

  final Point pointA;
  final Point pointB;

  box2d.Shape _createB2Shape(PhysicsNode node) {
    box2d.EdgeShape shape = new box2d.EdgeShape();
    shape.set(
      new Vector2(
        pointA.x / node.b2WorldToNodeConversionFactor,
        pointA.y / node.b2WorldToNodeConversionFactor
      ),
      new Vector2(
        pointB.x / node.b2WorldToNodeConversionFactor,
        pointB.y / node.b2WorldToNodeConversionFactor
      )
    );
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
