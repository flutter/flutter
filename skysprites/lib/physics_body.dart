part of skysprites;

enum PhysicsBodyType {
    static,
    dynamic
}

class PhysicsBody {
  PhysicsBody(this.shape, {
    this.tag: null,
    this.type: PhysicsBodyType.dynamic,
    double density: 1.0,
    double friction: 0.0,
    double restitution: 0.0,
    bool isSensor: false,
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
  }) {
    this.density = density;
    this.friction = friction;
    this.restitution = restitution;
    this.isSensor = isSensor;
  }

  Object tag;

  PhysicsShape shape;

  PhysicsBodyType type;

  double _density;

  double get density => _density;

  set density(double density) {
    _density = density;

    if (_body == null)
      return;
    for(box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setDensity(density);
    }
  }

  double _friction;

  double get friction => _friction;

  set friction(double friction) {
    _friction = friction;

    if (_body == null)
      return;
    for(box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setFriction(friction);
    }
  }

  double _restitution;

  double get restitution => _restitution;

  set restitution(double restitution) {
    _restitution = restitution;

    if (_body == null)
      return;
    for(box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setRestitution(restitution);
    }
  }

  bool _isSensor;

  bool get isSensor => _isSensor;

  set isSensor(bool isSensor) {
    _isSensor = isSensor;

    if (_body == null)
      return;
    for(box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setSensor(isSensor);
    }
  }

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
      _physicsNode._bodiesScheduledForDestruction.add(_body);
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
