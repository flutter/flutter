part of flutter_sprites;

enum PhysicsContactType {
  preSolve,
  postSolve,
  begin,
  end
}

typedef void PhysicsContactCallback(PhysicsContactType type, PhysicsContact contact);

/// A [Node] that performs a 2D physics simulation on any children with a
/// [PhysicsBody] attached. To simulate grand children, they need to be placed
/// in a [PhysicsGroup].
///
/// The PhysicsWorld uses Box2D.dart to perform the actual simulation, but
/// wraps its behavior in a way that is more integrated with the sprite node
/// tree. If needed, you can still access the Box2D world through the [b2World]
/// property.
class PhysicsWorld extends Node {
  PhysicsWorld(Offset gravity) {
    b2World = new box2d.World.withGravity(
      new Vector2(
        gravity.dx / b2WorldToNodeConversionFactor,
        gravity.dy / b2WorldToNodeConversionFactor));
    _init();
  }

  PhysicsWorld.fromB2World(this.b2World, this.b2WorldToNodeConversionFactor) {
    _init();
  }

  void _init() {
    _contactHandler = new _ContactHandler(this);
    b2World.setContactListener(_contactHandler);

    box2d.ViewportTransform transform = new box2d.ViewportTransform(
      new Vector2.zero(),
      new Vector2.zero(),
      1.0
    );
    _debugDraw = new _PhysicsDebugDraw(transform, this);
    b2World.debugDraw = _debugDraw;
  }

  /// The Box2D world used to perform the physics simulations.
  box2d.World b2World;

  _ContactHandler _contactHandler;

  _PhysicsCollisionGroups _collisionGroups = new _PhysicsCollisionGroups();

  List<PhysicsJoint> _joints = <PhysicsJoint>[];

  List<box2d.Body> _bodiesScheduledForDestruction = <box2d.Body>[];

  List<PhysicsBody> _bodiesScheduledForUpdate = <PhysicsBody>[];

  /// If set to true, a debug image of all physics shapes and joints will
  /// be drawn on top of the [SpriteBox].
  bool drawDebug = false;

  Matrix4 _debugDrawTransform ;

  _PhysicsDebugDraw _debugDraw;

  /// The conversion factor that is used to convert points in the physics world
  /// node to points in the Box2D physics simulation.
  double b2WorldToNodeConversionFactor = 10.0;

  /// The gravity vector used in the simulation.
  Offset get gravity {
    Vector2 g = b2World.getGravity();
    return new Offset(g.x, g.y);
  }

  set gravity(Offset gravity) {
    // Convert from points/s^2 to m/s^2
    b2World.setGravity(new Vector2(gravity.dx / b2WorldToNodeConversionFactor,
      gravity.dy / b2WorldToNodeConversionFactor));
  }

  /// If set to true, objects can fall asleep if the haven't moved in a while.
  bool get allowSleep => b2World.isAllowSleep();

  set allowSleep(bool allowSleep) {
    b2World.setAllowSleep(allowSleep);
  }

  /// True if sub stepping should be used in the simulation.
  bool get subStepping => b2World.isSubStepping();

  set subStepping(bool subStepping) {
    b2World.setSubStepping(subStepping);
  }

  void _stepPhysics(double dt) {
    // Update transformations of bodies whose groups have moved
    for (PhysicsBody body in _bodiesScheduledForUpdate) {
      Node node = body._node;
      node._updatePhysicsPosition(body, node.position, node.parent);
      node._updatePhysicsRotation(body, node.rotation, node.parent);
    }
    _bodiesScheduledForUpdate.clear();

    // Remove bodies that were marked for destruction during the update phase
    _removeBodiesScheduledForDestruction();

    // Assign velocities and momentum to static and kinetic bodies
    for (box2d.Body b2Body = b2World.bodyList; b2Body != null; b2Body = b2Body.getNext()) {
      // Fetch body
      PhysicsBody body = b2Body.userData;

      // Skip all dynamic bodies
      if (b2Body.getType() == box2d.BodyType.DYNAMIC) {
        body._lastPosition = null;
        body._lastRotation = null;
        continue;
      }

      // Update linear velocity
      if (body._lastPosition == null || body._targetPosition == null) {
        b2Body.linearVelocity.setZero();
      } else {
        Vector2 velocity = (body._targetPosition - body._lastPosition) / dt;
        b2Body.linearVelocity = velocity;
        body._lastPosition = null;
      }

      // Update angular velocity
      if (body._lastRotation == null || body._targetAngle == null) {
        b2Body.angularVelocity = 0.0;
      } else {
        double angularVelocity = (body._targetAngle - body._lastRotation) / dt;
        b2Body.angularVelocity = angularVelocity;
        body._lastRotation = 0.0;
      }
    }

    // Calculate a step in the simulation
    b2World.stepDt(dt, 10, 10);

    // Iterate over the bodies
    for (box2d.Body b2Body = b2World.bodyList; b2Body != null; b2Body = b2Body.getNext()) {
      // Update visual position and rotation
      PhysicsBody body = b2Body.userData;

      if (b2Body.getType() == box2d.BodyType.KINEMATIC) {
        body._targetPosition = null;
        body._targetAngle = null;
      }

      // Update visual position and rotation
      if (body.type == PhysicsBodyType.dynamic) {
        body._node._setPositionFromPhysics(
          new Point(
            b2Body.position.x * b2WorldToNodeConversionFactor,
            b2Body.position.y * b2WorldToNodeConversionFactor
          ),
          body._node.parent
        );

        body._node._setRotationFromPhysics(
          degrees(b2Body.getAngle()),
          body._node.parent
        );
      }
    }

    // Break joints
    for (PhysicsJoint joint in _joints) {
      joint._checkBreakingForce(dt);
    }

    // Remove bodies that were marked for destruction during the simulation
    _removeBodiesScheduledForDestruction();
  }

  void _removeBodiesScheduledForDestruction() {
    for (box2d.Body b2Body in _bodiesScheduledForDestruction) {
      // Destroy any joints before destroying the body
      PhysicsBody body = b2Body.userData;
      for (PhysicsJoint joint in body._joints) {
        joint._detach();
      }

      // Destroy the body
      b2World.destroyBody(b2Body);
    }
    _bodiesScheduledForDestruction.clear();
  }

  void _updatePosition(PhysicsBody body, Point position) {
    if (body._lastPosition == null && body.type == PhysicsBodyType.static) {
      body._lastPosition = new Vector2.copy(body._body.position);
      body._body.setType(box2d.BodyType.KINEMATIC);
    }

    Vector2 newPos = new Vector2(
      position.x / b2WorldToNodeConversionFactor,
      position.y / b2WorldToNodeConversionFactor
    );
    double angle = body._body.getAngle();

    if (body.type == PhysicsBodyType.dynamic) {
      body._body.setTransform(newPos, angle);
    } else {
      body._targetPosition = newPos;
      body._targetAngle = angle;
    }
    body._body.setAwake(true);
  }

  void _updateRotation(PhysicsBody body, double rotation) {
    if (body._lastRotation == null)
      body._lastRotation = body._body.getAngle();

    Vector2 pos = body._body.position;
    double newAngle = radians(rotation);
    body._body.setTransform(pos, newAngle);
    body._body.setAwake(true);
  }

  void _updateScale(PhysicsBody body, double scale) {
    body._scale = scale;

    if (body._attached) {
      body._updateScale(this);
    }
  }

  void addChild(Node node) {
    super.addChild(node);
    if (node.physicsBody != null) {
      node.physicsBody._attach(this, node);
    }
  }

  void removeChild(Node node) {
    super.removeChild(node);
    if (node.physicsBody != null) {
      node.physicsBody._detach();
    }
  }

  /// Adds a contact callback, the callback will be invoked when bodies collide
  /// in the world.
  ///
  /// To match specific sets bodies, use the [tagA] and [tagB]
  /// which will be matched to the tag property that is set on the
  /// [PhysicsBody]. If [tagA] or [tagB] is set to null, it will match any
  /// body.
  ///
  /// By default, callbacks are made at four different times during a
  /// collision; preSolve, postSolve, begin, and end. If you are only interested
  /// in one of these events you can pass in a [type].
  ///
  ///     myWorld.addContactCallback(
  ///       (PhysicsContactType type, PhysicsContact contact) {
  ///         print("Collision between ship and asteroid");
  ///       },
  ///       "Ship",
  ///       "Asteroid",
  ///       PhysicsContactType.begin
  ///     );
  void addContactCallback(PhysicsContactCallback callback, Object tagA, Object tagB, [PhysicsContactType type]) {
    _contactHandler.addContactCallback(callback, tagA, tagB, type);
  }

  void paint(Canvas canvas) {
    if (drawDebug) {
      _debugDrawTransform = new Matrix4.fromFloat64List(canvas.getTotalMatrix());
    }
    super.paint(canvas);
  }

  /// Draws the debug data of the physics world, normally this method isn't
  /// invoked directly. Instead, set the [drawDebug] property to true.
  void paintDebug(Canvas canvas) {
    _debugDraw.canvas = canvas;
    b2World.drawDebugData();
  }
}

/// Contains information about a physics collision and is normally passed back
/// in callbacks from the [PhysicsWorld].
///
///     void myCallback(PhysicsContactType type, PhysicsContact contact) {
///       if (contact.isTouching)
///         print("Bodies are touching");
///     }
class PhysicsContact {
  PhysicsContact(
    this.nodeA,
    this.nodeB,
    this.shapeA,
    this.shapeB,
    this.isTouching,
    this.isEnabled,
    this.touchingPoints,
    this.touchingNormal
  );

  /// The first node as matched in the rules set when adding the callback.
  final Node nodeA;

  /// The second node as matched in the rules set when adding the callback.
  final Node nodeB;

  /// The first shape as matched in the rules set when adding the callback.
  final PhysicsShape shapeA;

  /// The second shape as matched in the rules set when adding the callback.
  final PhysicsShape shapeB;

  /// True if the two nodes are touching.
  final isTouching;

  /// To ignore the collision to take place, you can set isEnabled to false
  /// during the preSolve phase.
  bool isEnabled;

  /// List of points that are touching, in world coordinates.
  final List<Point> touchingPoints;

  /// The normal from [shapeA] to [shapeB] at the touchingPoint.
  final Offset touchingNormal;
}

class _ContactCallbackInfo {
  _ContactCallbackInfo(this.callback, this.tagA, this.tagB, this.type);

  PhysicsContactCallback callback;
  Object tagA;
  Object tagB;
  PhysicsContactType type;
}

class _ContactHandler extends box2d.ContactListener {
  _ContactHandler(this.physicsNode);

  PhysicsWorld physicsNode;

  List<_ContactCallbackInfo> callbackInfos = <_ContactCallbackInfo>[];

  void addContactCallback(PhysicsContactCallback callback, Object tagA, Object tagB, PhysicsContactType type) {
    callbackInfos.add(new _ContactCallbackInfo(callback, tagA, tagB, type));
  }

  void handleCallback(PhysicsContactType type, box2d.Contact b2Contact, box2d.Manifold oldManifold, box2d.ContactImpulse impulse) {
    // Get info about the contact
    PhysicsBody bodyA = b2Contact.fixtureA.getBody().userData;
    PhysicsBody bodyB = b2Contact.fixtureB.getBody().userData;
    box2d.Fixture fixtureA = b2Contact.fixtureA;
    box2d.Fixture fixtureB = b2Contact.fixtureB;

    // Match callback with added callbacks
    for (_ContactCallbackInfo info in callbackInfos) {
      // Check that type is matching
      if (info.type != null && info.type != type)
        continue;

      // Check if there is a match
      bool matchA = (info.tagA == null) || info.tagA == bodyA.tag;
      bool matchB = (info.tagB == null) || info.tagB == bodyB.tag;

      bool match = (matchA && matchB);
      if (!match) {
        // Check if there is a match if we swap a & b
        bool matchA = (info.tagA == null) || info.tagA == bodyB.tag;
        bool matchB = (info.tagB == null) || info.tagB == bodyA.tag;

        match = (matchA && matchB);
        if (match) {
          // Swap a & b
          PhysicsBody tempBody = bodyA;
          bodyA = bodyB;
          bodyB = tempBody;

          box2d.Fixture tempFixture = fixtureA;
          fixtureA = fixtureB;
          fixtureB = tempFixture;
        }
      }

      if (match) {
        // We have contact and a matched callback, setup contact info
        List<Point> touchingPoints = null;
        Offset touchingNormal = null;

        // Fetch touching points, if any
        if (b2Contact.isTouching()) {
          box2d.WorldManifold manifold = new box2d.WorldManifold();
          b2Contact.getWorldManifold(manifold);
          touchingNormal = new Offset(manifold.normal.x, manifold.normal.y);
          touchingPoints = <Point>[];
          for (Vector2 vec in manifold.points) {
            touchingPoints.add(new Point(
              vec.x * physicsNode.b2WorldToNodeConversionFactor,
              vec.y * physicsNode.b2WorldToNodeConversionFactor
            ));
          }
        }

        // Create the contact
        PhysicsContact contact = new PhysicsContact(
          bodyA._node,
          bodyB._node,
          fixtureA.userData,
          fixtureB.userData,
          b2Contact.isTouching(),
          b2Contact.isEnabled(),
          touchingPoints,
          touchingNormal
        );

        // Make callback
        info.callback(type, contact);

        // Update Box2D contact
        b2Contact.setEnabled(contact.isEnabled);
      }
    }
  }

  void beginContact(box2d.Contact contact) {
    handleCallback(PhysicsContactType.begin, contact, null, null);
  }

  void endContact(box2d.Contact contact) {
    handleCallback(PhysicsContactType.end, contact, null, null);
  }

  void preSolve(box2d.Contact contact, box2d.Manifold oldManifold) {
    handleCallback(PhysicsContactType.preSolve, contact, oldManifold, null);
  }
  void postSolve(box2d.Contact contact, box2d.ContactImpulse impulse) {
    handleCallback(PhysicsContactType.postSolve, contact, null, impulse);
  }
}
