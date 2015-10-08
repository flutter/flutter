part of skysprites;

abstract class PhysicsJoint {
  PhysicsJoint(this.bodyA, this.bodyB) {
    bodyA._joints.add(this);
    bodyB._joints.add(this);

    if (bodyA._attached && bodyB._attached) {
      _attach(bodyA._physicsNode);
    }
  }

  PhysicsBody bodyA;
  PhysicsBody bodyB;

  bool _active = true;
  box2d.Joint _joint;

  PhysicsNode _physicsNode;

  void _attach(PhysicsNode physicsNode) {
    if (_joint == null) {
      _physicsNode = physicsNode;
      _joint = _createB2Joint(physicsNode);
    }
  }

  void _detach() {
    if (_joint != null && _active) {
      _physicsNode.b2World.destroyJoint(_joint);
      _joint = null;
    }
    _active = false;
  }

  box2d.Joint _createB2Joint(PhysicsNode physicsNode);
}

class PhysicsJointRevolute extends PhysicsJoint {
  PhysicsJointRevolute(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchorWorld, {
      double lowerAngle: 0.0,
      double upperAngle: 0.0,
      bool enableLimit: false
    }) : super(bodyA, bodyB) {
    this.lowerAngle = lowerAngle;
    this.upperAngle = upperAngle;
    this.enableLimit = enableLimit;
  }

  Point anchorWorld;
  double lowerAngle;
  double upperAngle;
  bool enableLimit;

  box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
    // Create Joint Definition
    Vector2 vecAnchor = new Vector2(
      anchorWorld.x / physicsNode.b2WorldToNodeConversionFactor,
      anchorWorld.y / physicsNode.b2WorldToNodeConversionFactor
    );

    box2d.RevoluteJointDef b2Def = new box2d.RevoluteJointDef();
    b2Def.initialize(bodyA._body, bodyB._body, vecAnchor);
    b2Def.enableLimit = enableLimit;
    b2Def.lowerAngle = lowerAngle;
    b2Def.upperAngle = upperAngle;

    // Create joint
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointWeld extends PhysicsJoint {
  PhysicsJointWeld(
    PhysicsBody bodyA,
    PhysicsBody bodyB) : super(bodyA, bodyB);

    box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
      box2d.WeldJointDef b2Def = new box2d.WeldJointDef();
      Vector2 middle = new Vector2(
        (bodyA._body.position.x + bodyB._body.position.x) / 2.0,
        (bodyA._body.position.y + bodyB._body.position.y) / 2.0
      );
      b2Def.initialize(bodyA._body, bodyB._body, middle);
      return physicsNode.b2World.createJoint(b2Def);
    }
}
