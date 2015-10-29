part of flutter_sprites;

enum PhysicsBodyType {
    static,
    dynamic
}

/// A physics body can be assigned to any node to make it simulated by physics.
/// The body has a shape, and physical properties such as density, friction,
/// and velocity.
///
/// Bodies can be either dynamic or static. Dynamic bodies will move and rotate
/// the nodes that are associated with it. Static bodies can be moved by moving
/// or animating the node associated with them.
///
/// For a body to be simulated it needs to be associated with a [Node], through
/// the node's physicsBody property. The node also need to be a child of either
/// a [PhysicsWorld] or a [PhysicsGroup] (which in turn is a child of a
/// [PhysicsWorld] or a [Physics Group]).
class PhysicsBody {
  PhysicsBody(this.shape, {
    this.tag: null,
    this.type: PhysicsBodyType.dynamic,
    double density: 1.0,
    double friction: 0.0,
    double restitution: 0.0,
    bool isSensor: false,
    Offset linearVelocity: Offset.zero,
    double angularVelocity: 0.0,
    this.linearDampening: 0.0,
    double angularDampening: 0.0,
    bool allowSleep: true,
    bool awake: true,
    bool fixedRotation: false,
    bool bullet: false,
    bool active: true,
    this.gravityScale: 1.0,
    collisionCategory: "Default",
    collisionMask: null
  }) {
    this.density = density;
    this.friction = friction;
    this.restitution = restitution;
    this.isSensor = isSensor;

    this.linearVelocity = linearVelocity;
    this.angularVelocity = angularVelocity;
    this.angularDampening = angularDampening;

    this.allowSleep = allowSleep;
    this.awake = awake;
    this.fixedRotation = fixedRotation;
    this.bullet = bullet;
    this.active = active;

    this.collisionCategory = collisionCategory;
    this.collisionMask = collisionMask;
  }

  Vector2 _lastPosition;
  double _lastRotation;
  Vector2 _targetPosition;
  double _targetAngle;

  double _scale;

  /// An object associated with this body, normally used for detecting
  /// collisions.
  ///
  /// myBody.tag = "SpaceShip";
  Object tag;

  /// The shape of this physics body. The shape cannot be modified once the
  /// body is created. If the shape is required to change, create a new body.
  ///
  ///     myShape = myBody.shape;
  final PhysicsShape shape;

  /// The type of the body. This is either [PhysicsBodyType.dynamic] or
  /// [PhysicsBodyType.static]. Dynamic bodies are simulated by the physics,
  /// static objects affect the physics but are not moved by the physics.
  ///
  ///     myBody.type = PhysicsBodyType.static;
  PhysicsBodyType type;

  double _density;

  /// The density of the body, default value is 1.0. The density has no specific
  /// unit, instead densities are relative to each other.
  ///
  ///     myBody.density = 0.5;
  double get density => _density;

  set density(double density) {
    _density = density;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setDensity(density);
    }
  }

  double _friction;

  /// The fricion of the body, the default is 0.0 and the value should be in
  /// the range of 0.0 to 1.0.
  ///
  ///     myBody.friction = 0.4;
  double get friction => _friction;

  set friction(double friction) {
    _friction = friction;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setFriction(friction);
    }
  }

  double _restitution;

  double get restitution => _restitution;

  /// The restitution of the body, the default is 0.0 and the value should be in
  /// the range of 0.0 to 1.0.
  ///
  ///     myBody.restitution = 0.5;
  set restitution(double restitution) {
    _restitution = restitution;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setRestitution(restitution);
    }
  }

  bool _isSensor;

  /// True if the body is a sensor. Sensors doesn't collide with other bodies,
  /// but will return collision callbacks. Use a sensor body to detect if two
  /// bodies are overlapping.
  ///
  ///     myBody.isSensor = true;
  bool get isSensor => _isSensor;

  set isSensor(bool isSensor) {
    _isSensor = isSensor;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setSensor(isSensor);
    }
  }

  Offset _linearVelocity;

  /// The current linear velocity of the body in points / second.
  ///
  ///     myBody.velocity = Offset.zero;
  Offset get linearVelocity {
    if (_body == null)
      return _linearVelocity;
    else {
      double dx = _body.linearVelocity.x * _physicsWorld.b2WorldToNodeConversionFactor;
      double dy = _body.linearVelocity.y * _physicsWorld.b2WorldToNodeConversionFactor;
      return new Offset(dx, dy);
    }
  }

  set linearVelocity(Offset linearVelocity) {
    _linearVelocity = linearVelocity;

    if (_body != null) {
      Vector2 vec = new Vector2(
        linearVelocity.dx / _physicsWorld.b2WorldToNodeConversionFactor,
        linearVelocity.dy / _physicsWorld.b2WorldToNodeConversionFactor
      );
      _body.linearVelocity = vec;
    }
  }

  double _angularVelocity;

  /// The angular velocity of the body in degrees / second.
  ///
  ///     myBody.angularVelocity = 0.0;
  double get angularVelocity {
    if (_body == null)
      return _angularVelocity;
    else
      return _body.angularVelocity;
  }

  set angularVelocity(double angularVelocity) {
    _angularVelocity = angularVelocity;

    if (_body != null) {
      _body.angularVelocity = angularVelocity;
    }
  }

  // TODO: Should this be editable in box2d.Body ?

  /// Linear dampening, in the 0.0 to 1.0 range, default is 0.0.
  ///
  ///     double dampening = myBody.linearDampening;
  final double linearDampening;

  double _angularDampening;

  /// Angular dampening, in the 0.0 to 1.0 range, default is 0.0.
  ///
  ///     myBody.angularDampening = 0.1;
  double get angularDampening => _angularDampening;

  set angularDampening(double angularDampening) {
    _angularDampening = angularDampening;

    if (_body != null)
      _body.angularDamping = angularDampening;
  }

  bool _allowSleep;

  /// Allows the body to sleep if it hasn't moved.
  ///
  ///     myBody.allowSleep = false;
  bool get allowSleep => _allowSleep;

  set allowSleep(bool allowSleep) {
    _allowSleep = allowSleep;

    if (_body != null)
      _body.setSleepingAllowed(allowSleep);
  }

  bool _awake;

  /// True if the body is currently awake.
  ///
  ///     bool isAwake = myBody.awake;
  bool get awake {
    if (_body != null)
      return _body.isAwake();
    else
      return _awake;
  }

  set awake(bool awake) {
    _awake = awake;

    if (_body != null)
      _body.setAwake(awake);
  }

  bool _fixedRotation;

  /// If true, the body cannot be rotated by the physics simulation.
  ///
  ///     myBody.fixedRotation = true;
  bool get fixedRotation => _fixedRotation;

  set fixedRotation(bool fixedRotation) {
    _fixedRotation = fixedRotation;

    if (_body != null)
      _body.setFixedRotation(fixedRotation);
  }

  bool _bullet;

  bool get bullet => _bullet;

  /// If true, the body cannot pass through other objects when moved at high
  /// speed. Bullet bodies are slower to simulate, so only use this option
  /// if neccessary.
  ///
  ///     myBody.bullet = true;
  set bullet(bool bullet) {
    _bullet = bullet;

    if (_body != null) {
      _body.setBullet(bullet);
    }
  }

  bool _active;

  /// An active body is used in the physics simulation. Set this to false if
  /// you want to temporarily exclude a body from the simulation.
  ///
  ///     myBody.active = false;
  bool get active {
    if (_body != null)
      return _body.isActive();
    else
      return _active;
  }

  set active(bool active) {
    _active = active;

    if (_body != null)
      _body.setActive(active);
  }

  double gravityScale;

  Object _collisionCategory = null;

  /// The collision category assigned to this body. The default value is
  /// "Default". The body will only collide with bodies that have the either
  /// the [collisionMask] set to null or has the category in the mask.
  ///
  ///     myBody.collisionCategory = "Air";
  Object get collisionCategory {
    return _collisionCategory;
  }

  set collisionCategory(Object collisionCategory) {
    _collisionCategory = collisionCategory;
    _updateFilter();
  }

  List<Object> _collisionMask = null;

  /// A list of collision categories that this object will collide with. If set
  /// to null (the default value) the body will collide with all other bodies.
  ///
  ///     myBody.collisionMask = ["Air", "Ground"];
  List<Object> get collisionMask => _collisionMask;

  set collisionMask(List<Object> collisionMask) {
    _collisionMask = collisionMask;
    _updateFilter();
  }

  box2d.Filter get _b2Filter {
    print("_physicsNode: $_physicsWorld groups: ${_physicsWorld._collisionGroups}");
    box2d.Filter f = new box2d.Filter();
    f.categoryBits = _physicsWorld._collisionGroups.getBitmaskForKeys([_collisionCategory]);
    f.maskBits = _physicsWorld._collisionGroups.getBitmaskForKeys(_collisionMask);

    print("Filter: $f category: ${f.categoryBits} mask: ${f.maskBits}");

    return f;
  }

  void _updateFilter() {
    if (_body != null) {
      box2d.Filter filter = _b2Filter;
      for (box2d.Fixture fixture = _body.getFixtureList(); fixture != null; fixture = fixture.getNext()) {
        fixture.setFilterData(filter);
      }
    }
  }

  PhysicsWorld _physicsWorld;
  Node _node;

  box2d.Body _body;

  List<PhysicsJoint> _joints = <PhysicsJoint>[];

  bool _attached = false;

  /// Applies a force to the body at the [worldPoint] position in world
  /// cordinates.
  ///
  ///     myBody.applyForce(new Offset(0.0, 100.0), myNode.position);
  void applyForce(Offset force, Point worldPoint) {
    assert(_body != null);

    Vector2 b2Force = new Vector2(
      force.dx / _physicsWorld.b2WorldToNodeConversionFactor,
      force.dy / _physicsWorld.b2WorldToNodeConversionFactor);

    Vector2 b2Point = new Vector2(
      worldPoint.x / _physicsWorld.b2WorldToNodeConversionFactor,
      worldPoint.y / _physicsWorld.b2WorldToNodeConversionFactor
    );

    _body.applyForce(b2Force, b2Point);
  }

  /// Applice a force to the body at the its center of gravity.
  ///
  ///     myBody.applyForce(new Offset(0.0, 100.0));
  void applyForceToCenter(Offset force) {
    assert(_body != null);

    Vector2 b2Force = new Vector2(
      force.dx / _physicsWorld.b2WorldToNodeConversionFactor,
      force.dy / _physicsWorld.b2WorldToNodeConversionFactor);

    _body.applyForceToCenter(b2Force);
  }

  /// Applies a torque to the body.
  ///
  ///     myBody.applyTorque(10.0);
  void applyTorque(double torque) {
    assert(_body != null);

    _body.applyTorque(torque / _physicsWorld.b2WorldToNodeConversionFactor);
  }

  /// Applies a linear impulse to the body at the [worldPoint] position in world
  /// cordinates.
  ///
  ///     myBody.applyLinearImpulse(new Offset(0.0, 100.0), myNode.position);
  void applyLinearImpulse(Offset impulse, Point worldPoint, [bool wake = true]) {
    assert(_body != null);

    Vector2 b2Impulse = new Vector2(
      impulse.dx / _physicsWorld.b2WorldToNodeConversionFactor,
      impulse.dy / _physicsWorld.b2WorldToNodeConversionFactor);

    Vector2 b2Point = new Vector2(
      worldPoint.x / _physicsWorld.b2WorldToNodeConversionFactor,
      worldPoint.y / _physicsWorld.b2WorldToNodeConversionFactor
    );

    _body.applyLinearImpulse(b2Impulse, b2Point, wake);
  }

  /// Applies an angular impulse to the body.
  ///
  ///     myBody.applyAngularImpulse(20.0);
  void applyAngularImpulse(double impulse) {
    assert(_body != null);

    _body.applyAngularImpulse(impulse / _physicsWorld.b2WorldToNodeConversionFactor);
  }

  void _attach(PhysicsWorld physicsNode, Node node) {
    assert(_attached == false);

    _physicsWorld = physicsNode;

    // Account for physics groups
    Point positionWorld = node._positionToPhysics(node.position, node.parent);
    double rotationWorld = node._rotationToPhysics(node.rotation, node.parent);
    double scaleWorld = node._scaleToPhysics(node.scale, node.parent);

    // Update scale
    _scale = scaleWorld;

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

    // Convert to world coordinates and set position and angle
    double conv = physicsNode.b2WorldToNodeConversionFactor;
    bodyDef.position = new Vector2(positionWorld.x / conv, positionWorld.y / conv);
    bodyDef.angle = radians(rotationWorld);

    // Create Body
    _body = physicsNode.b2World.createBody(bodyDef);

    _createFixtures(physicsNode);

    _body.userData = this;

    _node = node;

    _attached = true;

    // Attach any joints
    for (PhysicsJoint joint in _joints) {
      if (joint.bodyA._attached && joint.bodyB._attached) {
        joint._attach(physicsNode);
      }
    }
  }

  void _createFixtures(PhysicsWorld physicsNode) {
    // Create FixtureDef
    box2d.FixtureDef fixtureDef = new box2d.FixtureDef();
    fixtureDef.friction = friction;
    fixtureDef.restitution = restitution;
    fixtureDef.density = density;
    fixtureDef.isSensor = isSensor;
    fixtureDef.filter = _b2Filter;

    // Get shapes
    List<box2d.Shape> b2Shapes = <box2d.Shape>[];
    List<PhysicsShape> physicsShapes = <PhysicsShape>[];
    _addB2Shapes(physicsNode, shape, b2Shapes, physicsShapes);

    // Create fixtures
    for (int i = 0; i < b2Shapes.length; i++) {
      box2d.Shape b2Shape = b2Shapes[i];
      PhysicsShape physicsShape = physicsShapes[i];

      fixtureDef.shape = b2Shape;
      box2d.Fixture fixture = _body.createFixtureFromFixtureDef(fixtureDef);
      fixture.userData = physicsShape;
    }
  }

  void _detach() {
    if (_attached) {
      _physicsWorld._bodiesScheduledForDestruction.add(_body);
      _attached = false;
    }
  }

  void _updateScale(PhysicsWorld physicsNode) {
    // Destroy old fixtures
    for (box2d.Fixture fixture = _body.getFixtureList(); fixture != null; fixture = fixture.getNext()) {
      _body.destroyFixture(fixture);
    }

    // Make sure we create new b2Shapes
    shape._invalidate();

    // Create new fixtures
    _createFixtures(physicsNode);
  }

  void _addB2Shapes(PhysicsWorld physicsNode, PhysicsShape shape, List<box2d.Shape> b2Shapes, List<PhysicsShape> physicsShapes) {
    if (shape is PhysicsShapeGroup) {
      for (PhysicsShape child in shape.shapes) {
        _addB2Shapes(physicsNode, child, b2Shapes, physicsShapes);
      }
    } else {
      b2Shapes.add(shape.getB2Shape(physicsNode, _scale));
      physicsShapes.add(shape);
    }
  }
}
