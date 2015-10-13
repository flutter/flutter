part of skysprites;

abstract class PhysicsJoint {
  PhysicsJoint(this.bodyA, this.bodyB, this.breakingForce) {
    bodyA._joints.add(this);
    bodyB._joints.add(this);
  }

  final PhysicsBody bodyA;
  final PhysicsBody bodyB;
  final double breakingForce;

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
      _physicsNode._joints.add(this);
    }
  }

  void _detach() {
    if (_joint != null && _active) {
      _physicsNode.b2World.destroyJoint(_joint);
      _joint = null;
      _physicsNode._joints.remove(this);
    }
    _active = false;
  }

  box2d.Joint _createB2Joint(PhysicsNode physicsNode);

  void destroy() {
    _detach();
  }

  void _checkBreakingForce(double dt) {
    if (breakingForce == null) return;

    if (_joint != null && _active) {
      Vector2 reactionForce = new Vector2.zero();
      _joint.getReactionForce(1.0 / dt, reactionForce);

      if (breakingForce * breakingForce < reactionForce.length2) {
        // TODO: Add callback

        destroy();
      }
    }
  }
}

class PhysicsJointRevolute extends PhysicsJoint {
  PhysicsJointRevolute(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this._worldAnchor, {
      this.lowerAngle: 0.0,
      this.upperAngle: 0.0,
      this.enableLimit: false,
      double breakingForce
    }) : super(bodyA, bodyB, breakingForce) {
    _completeCreation();
  }

  final Point _worldAnchor;
  final double lowerAngle;
  final double upperAngle;
  final bool enableLimit;

  box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
    // Create Joint Definition
    Vector2 vecAnchor = new Vector2(
      _worldAnchor.x / physicsNode.b2WorldToNodeConversionFactor,
      _worldAnchor.y / physicsNode.b2WorldToNodeConversionFactor
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
    this.axis, {
      double breakingForce
    }
  ) : super(bodyA, bodyB, breakingForce) {
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
    PhysicsBody bodyB, {
      double breakingForce,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce) {
    _completeCreation();
  }

  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsNode physicsNode) {
    box2d.WeldJointDef b2Def = new box2d.WeldJointDef();
    Vector2 middle = new Vector2(
      (bodyA._body.position.x + bodyB._body.position.x) / 2.0,
      (bodyA._body.position.y + bodyB._body.position.y) / 2.0
    );
    b2Def.initialize(bodyA._body, bodyB._body, middle);
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;
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
    this.ratio, {
      double breakingForce
    }
  ) : super(bodyA, bodyB, breakingForce) {
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
