part of skysprites;

abstract class PhysicsJoint {
  PhysicsJoint(this.bodyA, this.bodyB) {
    bodyA._joints.add(this);
    bodyB._joints.add(this);
  }

  final PhysicsBody bodyA;
  final PhysicsBody bodyB;

  bool _active = true;
  box2d.Joint _joint;

  PhysicsNode _physicsNode;

  void _completeCreation() {
    if (bodyA._attached && bodyB._attached) {
      _attach(bodyA._physicsNode);
    }
  }

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
    this.worldAnchor, {
      this.lowerAngle: 0.0,
      this.upperAngle: 0.0,
      this.enableLimit: false
    }) : super(bodyA, bodyB) {
    _completeCreation();
  }

  final Point worldAnchor;
  final double lowerAngle;
  final double upperAngle;
  final bool enableLimit;

  box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
    // Create Joint Definition
    Vector2 vecAnchor = new Vector2(
      worldAnchor.x / physicsNode.b2WorldToNodeConversionFactor,
      worldAnchor.y / physicsNode.b2WorldToNodeConversionFactor
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

class PhysicsJointPrismatic extends PhysicsJoint {
  PhysicsJointPrismatic(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.axis
  ) : super(bodyA, bodyB) {
    _completeCreation();
  }

  Offset axis;

  box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
    box2d.PrismaticJointDef b2Def = new box2d.PrismaticJointDef();
    b2Def.initialize(bodyA._body, bodyB._body, bodyA._body.position, new Vector2(axis.dx, axis.dy));
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointWeld extends PhysicsJoint {
  PhysicsJointWeld(
    PhysicsBody bodyA,
    PhysicsBody bodyB
  ) : super(bodyA, bodyB) {
    _completeCreation();
  }

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

class PhysicsJointPulley extends PhysicsJoint {
  PhysicsJointPulley(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.groundAnchorA,
    this.groundAnchorB,
    this.anchorA,
    this.anchorB,
    this.ratio
  ) : super(bodyA, bodyB) {
    _completeCreation();
  }

  final Point groundAnchorA;
  final Point groundAnchorB;
  final Point anchorA;
  final Point anchorB;
  final double ratio;

  box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
    box2d.PulleyJointDef b2Def = new box2d.PulleyJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(groundAnchorA, physicsNode),
      _convertPosToVec(groundAnchorB, physicsNode),
      _convertPosToVec(anchorA, physicsNode),
      _convertPosToVec(anchorB, physicsNode),
      ratio
    );
    return physicsNode.b2World.createJoint(b2Def);
  }
}

Vector2 _convertPosToVec(Point pt, PhysicsNode physicsNode) {
  return new Vector2(
    pt.x / physicsNode.b2WorldToNodeConversionFactor,
    pt.y / physicsNode.b2WorldToNodeConversionFactor
  );
}
