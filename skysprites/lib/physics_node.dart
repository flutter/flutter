part of skysprites;

enum PhysicsContactType {
  preSolve,
  postSolve,
  begin,
  end
}

typedef void PhysicsContactCallback(PhysicsContactType type, PhysicsContact contact);

class PhysicsNode extends Node {
  PhysicsNode(Offset gravity) {
    b2World = new box2d.World.withGravity(
      new Vector2(
        gravity.dx / b2WorldToNodeConversionFactor,
        gravity.dy / b2WorldToNodeConversionFactor));
    _init();
  }

  PhysicsNode.fromB2World(this.b2World, this.b2WorldToNodeConversionFactor) {
    _init();
  }

  void _init() {
    _contactHandler = new _ContactHandler(this);
    b2World.setContactListener(_contactHandler);
  }

  box2d.World b2World;

  _ContactHandler _contactHandler;

  List<box2d.Body> _bodiesScheduledForDestruction = [];

  double b2WorldToNodeConversionFactor = 500.0;

  Offset get gravity {
    Vector2 g = b2World.getGravity();
    return new Offset(g.x, g.y);
  }

  set gravity(Offset gravity) {
    // Convert from points/s^2 to m/s^2
    b2World.setGravity(new Vector2(gravity.dx / b2WorldToNodeConversionFactor,
      gravity.dy / b2WorldToNodeConversionFactor));
  }

  bool get allowSleep => b2World.isAllowSleep();

  set allowSleep(bool allowSleep) {
    b2World.setAllowSleep(allowSleep);
  }

  bool get subStepping => b2World.isSubStepping();

  set subStepping(bool subStepping) {
    b2World.setSubStepping(subStepping);
  }

  void _stepPhysics(double dt) {
    // Remove bodies that were marked for destruction during the update phase
    _removeBodiesScheduledForDestruction();

    // Calculate a step in the simulation
    b2World.stepDt(dt, 10, 10);

    // Iterate over the bodies
    for (box2d.Body b2Body = b2World.bodyList; b2Body != null; b2Body = b2Body.getNext()) {
      // Update visual position and rotation
      PhysicsBody body = b2Body.userData;
      body._node._setPositionFromPhysics(new Point(
        b2Body.position.x * b2WorldToNodeConversionFactor,
        b2Body.position.y * b2WorldToNodeConversionFactor
      ));

      body._node._setRotationFromPhysics(degrees(b2Body.getAngle()));
    }

    // Remove bodies that were marked for destruction during the simulation
    _removeBodiesScheduledForDestruction();
  }

  void _removeBodiesScheduledForDestruction() {
    for (box2d.Body b2Body in _bodiesScheduledForDestruction) {
      b2World.destroyBody(b2Body);
    }
    _bodiesScheduledForDestruction.clear();
  }

  void _updatePosition(PhysicsBody body, Point position) {
    Vector2 newPos = new Vector2(
      position.x / b2WorldToNodeConversionFactor,
      position.y / b2WorldToNodeConversionFactor
    );
    double angle = body._body.getAngle();
    body._body.setTransform(newPos, angle);
    body._body.setAwake(true);
  }

  void _updateRotation(PhysicsBody body, double rotation) {
    Vector2 pos = body._body.position;
    double newAngle = radians(rotation);
    body._body.setTransform(pos, newAngle);
    body._body.setAwake(true);
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

  void addContactCallback(PhysicsContactCallback callback, Object tagA, Object tagB, [PhysicsContactType type]) {
    _contactHandler.addContactCallback(callback, tagA, tagB, type);
  }

  void paint(PaintingCanvas canvas) {
    super.paint(canvas);
    paintDebug(canvas);
  }

  void paintDebug(PaintingCanvas canvas) {
    Paint shapePaint = new Paint();
    shapePaint.setStyle(sky.PaintingStyle.stroke);
    shapePaint.strokeWidth = 1.0;

    for (box2d.Body body = b2World.bodyList; body != null; body = body.getNext()) {
      canvas.save();

      Point point = new Point(
        body.position.x * b2WorldToNodeConversionFactor,
        body.position.y * b2WorldToNodeConversionFactor);

      canvas.translate(point.x, point.y);
      canvas.rotate(body.getAngle());

      if (body.getType() == box2d.BodyType.DYNAMIC) {
        if (body.isAwake())
          shapePaint.color = new Color(0xff00ff00);
        else
          shapePaint.color = new Color(0xff666666);
      }
      else if (body.getType() == box2d.BodyType.STATIC)
        shapePaint.color = new Color(0xffff0000);
      else if (body.getType() == box2d.BodyType.KINEMATIC)
        shapePaint.color = new Color(0xffff9900);

      for (box2d.Fixture fixture = body.getFixtureList(); fixture != null; fixture = fixture.getNext()) {
        box2d.Shape shape = fixture.getShape();

        if (shape.shapeType == box2d.ShapeType.CIRCLE) {
          box2d.CircleShape circle = shape;
          Point cp = new Point(
            circle.p.x * b2WorldToNodeConversionFactor,
            circle.p.y * b2WorldToNodeConversionFactor
          );
          double radius = circle.radius * b2WorldToNodeConversionFactor;
          canvas.drawCircle(cp, radius, shapePaint);
        } else if (shape.shapeType == box2d.ShapeType.POLYGON) {
          box2d.PolygonShape poly = shape;
          List<Point> points = [];
          for (int i = 0; i < poly.getVertexCount(); i++) {
            Vector2 vertex = poly.getVertex(i);
            Point pt = new Point(
              vertex.x * b2WorldToNodeConversionFactor,
              vertex.y * b2WorldToNodeConversionFactor
            );
            points.add(pt);
          }
          if (points.length >= 2) {
            for (int i = 0; i < points.length; i++) {
              canvas.drawLine(points[i], points[(i + 1) % points.length], shapePaint);
            }
          }
        }
      }
      canvas.restore();
    }
  }
}

class PhysicsContact {
  PhysicsContact(
    this.nodeA,
    this.nodeB,
    this.shapeA,
    this.shapeB,
    this.isTouching,
    this.isEnabled
  );

  final Node nodeA;
  final Node nodeB;
  final PhysicsShape shapeA;
  final PhysicsShape shapeB;
  final isTouching;
  bool isEnabled;
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

  PhysicsNode physicsNode;

  List<_ContactCallbackInfo> callbackInfos = [];

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
        PhysicsContact contact = new PhysicsContact(
          bodyA._node,
          bodyB._node,
          fixtureA.userData,
          fixtureB.userData,
          b2Contact.isTouching(),
          b2Contact.isEnabled()
        );

        if (type == PhysicsContactType.postSolve) {

        }

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
