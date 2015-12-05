part of flutter_sprites;

class _PhysicsDebugDraw extends box2d.DebugDraw {
  _PhysicsDebugDraw(
    box2d.ViewportTransform transform,
    this.physicsWorld
  ) : super(transform) {
    appendFlags(
      box2d.DebugDraw.JOINT_BIT |
      box2d.DebugDraw.CENTER_OF_MASS_BIT |
      box2d.DebugDraw.WIREFRAME_DRAWING_BIT
    );
  }

  PhysicsWorld physicsWorld;

  Canvas canvas;

  void drawSegment(Vector2 p1, Vector2 p2, box2d.Color3i color) {
    Paint paint = new Paint()
      ..color = _toColor(color)
      ..strokeWidth = 1.0;
    canvas.drawLine(_toPoint(p1), _toPoint(p2), paint);
  }

  void drawSolidPolygon(
    List<Vector2> vertices,
    int vertexCount,
    box2d.Color3i color
  ) {
    Path path = new Path();
    Point pt = _toPoint(vertices[0]);
    path.moveTo(pt.x, pt.y);
    for (int i = 1; i < vertexCount; i++) {
      pt = _toPoint(vertices[i]);
      path.lineTo(pt.x, pt.y);
    }

    Paint paint = new Paint()..color = _toColor(color);
    canvas.drawPath(path, paint);
  }

  void drawCircle(Vector2 center, num radius, box2d.Color3i color, [Vector2 axis]) {
    Paint paint = new Paint()
      ..color = _toColor(color)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(_toPoint(center), _scale(radius), paint);
  }

  void drawSolidCircle(Vector2 center, num radius, Vector2 axis, box2d.Color3i color) {
    Paint paint = new Paint()
      ..color = _toColor(color);

    canvas.drawCircle(_toPoint(center), _scale(radius), paint);
  }

  void drawPoint(Vector2 point, num radiusOnScreen, box2d.Color3i color) {
    drawSolidCircle(point, radiusOnScreen, null, color);
  }

  void drawParticles(
    List<Vector2> centers,
    double radius,
    List<box2d.ParticleColor> colors,
    int count
  ) {
    // TODO: Implement
  }

  void drawParticlesWireframe(
    List<Vector2> centers,
    double radius,
    List<box2d.ParticleColor> colors,
    int count
  ) {
    // TODO: Implement
  }

  void drawTransform(box2d.Transform xf, box2d.Color3i color) {
    drawCircle(xf.p, 0.1, color);
    // TODO: Improve
  }

  void drawStringXY(num x, num y, String s, box2d.Color3i color) {
    // TODO: Implement
  }

  Color _toColor(box2d.Color3i color) {
    return new Color.fromARGB(255, color.x, color.y, color.z);
  }

  Point _toPoint(Vector2 vec) {
    return new Point(
      vec.x * physicsWorld.b2WorldToNodeConversionFactor,
      vec.y * physicsWorld.b2WorldToNodeConversionFactor
    );
  }

  double _scale(double value) {
    return value * physicsWorld.b2WorldToNodeConversionFactor;
  }
}
