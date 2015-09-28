part of skysprites;

enum PhysicsBodyType {
    static,
    dynamic
}

class PhysicsBody {
  PhysicsBody(this.shape, {
    this.tag: null,
    this.type: PhysicsBodyType.dynamic,
    this.density: 1.0,
    this.friction: 0.0,
    this.restitution: 0.0,
    this.isSensor: false,
    this.linearVelocity: Offset.zero,
    this.angularVelocity: 0.0,
    this.linearDampening: 0.0,
    this.angularDampening: 0.0,
    this.allowSleep: true,
    this.awake: true,
    this.fixedRotation: false,
    this.bullet: false,
    this.active: true,
    this.gravityScale: 1.0
  });

  Object tag;

  PhysicsShape shape;

  PhysicsBodyType type;

  double density;
  double friction;
  double restitution;
  bool isSensor;

  Offset linearVelocity;
  double angularVelocity;

  double linearDampening;

  double angularDampening;

  bool allowSleep;

  bool awake;

  bool fixedRotation;

  bool bullet;

  bool active;

  double gravityScale;

  PhysicsNode _physicsNode;
  Node _node;

  box2d.Body _body;

  bool _attached = false;

  void _attach(PhysicsNode physicsNode, Node node) {
    assert(_attached == false);

    // Create BodyDef
    box2d.BodyDef bodyDef = new box2d.BodyDef();
    bodyDef.linearVelocity = new Vector2(linearVelocity.dx, linearVelocity.dy);
    bodyDef.angularVelocity = angularVelocity;
    bodyDef.linearDamping = linearDampening;
    bodyDef.angularDamping = angularDampening;
    bodyDef.allowSleep = allowSleep;
    bodyDef.awake = awake;
    bodyDef.fixedRotation = fixedRotation;
    bodyDef.bullet = bullet;
    bodyDef.active = active;
    bodyDef.gravityScale = gravityScale;
    if (type == PhysicsBodyType.dynamic)
      bodyDef.type = box2d.BodyType.DYNAMIC;
    else
      bodyDef.type = box2d.BodyType.STATIC;

    double conv = physicsNode.b2WorldToNodeConversionFactor;
    bodyDef.position = new Vector2(node.position.x / conv, node.position.y / conv);
    bodyDef.angle = radians(node.rotation);

    // Create Body
    _body = physicsNode.b2World.createBody(bodyDef);

    // Create FixtureDef
    box2d.FixtureDef fixtureDef = new box2d.FixtureDef();
    fixtureDef.friction = friction;
    fixtureDef.restitution = restitution;
    fixtureDef.density = density;
    fixtureDef.isSensor = isSensor;

    // Get shapes
    List<box2d.Shape> b2Shapes = [];
    List<PhysicsShape> physicsShapes = [];
    _addB2Shapes(physicsNode, shape, b2Shapes, physicsShapes);

    // Create fixtures
    for (int i = 0; i < b2Shapes.length; i++) {
      box2d.Shape b2Shape = b2Shapes[i];
      PhysicsShape physicsShape = physicsShapes[i];

      fixtureDef.shape = b2Shape;
      box2d.Fixture fixture = _body.createFixtureFromFixtureDef(fixtureDef);
      fixture.userData = physicsShape;
    }
    _body.userData = this;

    _physicsNode = physicsNode;
    _node = node;

    _attached = true;
  }

  void _detach() {
    if (_attached) {
      _physicsNode.b2World.destroyBody(_body);
      _attached = false;
    }
  }

  void _addB2Shapes(PhysicsNode physicsNode, PhysicsShape shape, List<box2d.Shape> b2Shapes, List<PhysicsShape> physicsShapes) {
    if (shape is PhysicsShapeGroup) {
      for (PhysicsShape child in shape.shapes) {
        _addB2Shapes(physicsNode, child, b2Shapes, physicsShapes);
      }
    } else {
      b2Shapes.add(shape.getB2Shape(physicsNode));
      physicsShapes.add(shape);
    }
  }
}
