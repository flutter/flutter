part of flutter_sprites;

typedef void PhysicsJointBreakCallback(PhysicsJoint joint);

/// A joint connects two physics bodies and restricts their movements. Some
/// types of joints also support motors that adds forces to the connected
/// bodies.
abstract class PhysicsJoint {
  PhysicsJoint(this._bodyA, this._bodyB, this.breakingForce, this.breakCallback) {
    bodyA._joints.add(this);
    bodyB._joints.add(this);
  }

  PhysicsBody _bodyA;

  /// The first body connected to the joint.
  ///
  ///     PhysicsBody body = myJoint.bodyA;
  PhysicsBody get bodyA => _bodyA;

  PhysicsBody _bodyB;

  /// The second body connected to the joint.
  ///
  ///     PhysicsBody body = myJoint.bodyB;
  PhysicsBody get bodyB => _bodyB;

  /// The maximum force the joint can handle before it breaks. If set to null,
  /// the joint will never break.
  final double breakingForce;

  final PhysicsJointBreakCallback breakCallback;

  bool _active = true;
  box2d.Joint _joint;

  PhysicsWorld _physicsWorld;

  void _completeCreation() {
    if (bodyA._attached && bodyB._attached) {
      _attach(bodyA._physicsWorld);
    }
  }

  void _attach(PhysicsWorld physicsNode) {
    if (_joint == null) {
      _physicsWorld = physicsNode;
      _joint = _createB2Joint(physicsNode);
      _physicsWorld._joints.add(this);
    }
  }

  void _detach() {
    if (_joint != null && _active) {
      _physicsWorld.b2World.destroyJoint(_joint);
      _joint = null;
      _physicsWorld._joints.remove(this);
    }
    _active = false;
  }

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode);

  /// If the joint is no longer needed, call the the [destroy] method to detach
  /// if from its connected bodies.
  void destroy() {
    _detach();
  }

  void _checkBreakingForce(double dt) {
    if (breakingForce == null) return;

    if (_joint != null && _active) {
      Vector2 reactionForce = new Vector2.zero();
      _joint.getReactionForce(1.0 / dt, reactionForce);

      if (breakingForce * breakingForce < reactionForce.length2) {
        // Destroy the joint
        destroy();

        // Notify any observer
        if (breakCallback != null)
          breakCallback(this);
      }
    }
  }
}

/// The revolute joint can be thought of as a hinge, a pin, or an axle.
/// An anchor point is defined in global space.
///
/// Revolute joints can be given limits so that the bodies can rotate only to a
/// certain point using [lowerAngle], [upperAngle], and [enableLimit].
/// They can also be given a motor using [enableMotore] together with
/// [motorSpeed] and [maxMotorTorque] so that the bodies will try
/// to rotate at a given speed, with a given torque.
///
/// Common uses for revolute joints include:
/// - wheels or rollers
/// - chains or swingbridges (using multiple revolute joints)
/// - rag-doll joints
/// - rotating doors, catapults, levers
///
///     new PhysicsJointRevolute(
///       nodeA.physicsBody,
///       nodeB.physicsBody,
///       nodeB.position
///     );
class PhysicsJointRevolute extends PhysicsJoint {
  PhysicsJointRevolute(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this._worldAnchor, {
      this.lowerAngle: 0.0,
      this.upperAngle: 0.0,
      this.enableLimit: false,
      PhysicsJointBreakCallback breakCallback,
      double breakingForce,
      bool enableMotor: false,
      double motorSpeed: 0.0,
      double maxMotorTorque: 0.0
    }) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _enableMotor = enableMotor;
    _motorSpeed = motorSpeed;
    _maxMotorTorque = maxMotorTorque;
    _completeCreation();
  }

  final Point _worldAnchor;

  /// The lower angle of the limits of this joint, only used if [enableLimit]
  /// is set to true.
  final double lowerAngle;

  /// The upper angle of the limits of this joint, only used if [enableLimit]
  /// is set to true.
  final double upperAngle;

  /// If set to true, the rotation will be limited to a value between
  /// [lowerAngle] and [upperAngle].
  final bool enableLimit;

  bool _enableMotor;

  /// By setting enableMotor to true, the joint will automatically rotate, e.g.
  /// this can be used for creating an engine for a wheel. For this to be
  /// useful you also need to set [motorSpeed] and [maxMotorTorque].
  bool get enableMotor => _enableMotor;

  set enableMotor(bool enableMotor) {
    _enableMotor = enableMotor;
    if (_joint != null) {
      box2d.RevoluteJoint revoluteJoint = _joint;
      revoluteJoint.enableMotor(enableMotor);
    }
  }

  double _motorSpeed;

  /// Sets the motor speed of this joint, will only work if [enableMotor] is
  /// set to true and [maxMotorTorque] is set to a non zero value.
  double get motorSpeed => _motorSpeed;

  set motorSpeed(double motorSpeed) {
    _motorSpeed = motorSpeed;
    if (_joint != null) {
      box2d.RevoluteJoint revoluteJoint = _joint;
      revoluteJoint.setMotorSpeed(radians(motorSpeed));
    }
  }

  double _maxMotorTorque;

  double get maxMotorTorque => _maxMotorTorque;

  /// Sets the motor torque of this joint, will only work if [enableMotor] is
  /// set to true and [motorSpeed] is set to a non zero value.
  set maxMotorTorque(double maxMotorTorque) {
    _maxMotorTorque = maxMotorTorque;
    if (_joint != null) {
      box2d.RevoluteJoint revoluteJoint = _joint;
      revoluteJoint.setMaxMotorTorque(maxMotorTorque);
    }
  }

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
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

    b2Def.enableMotor = _enableMotor;
    b2Def.motorSpeed = _motorSpeed;
    b2Def.maxMotorTorque = _maxMotorTorque;

    // Create joint
    return physicsNode.b2World.createJoint(b2Def);
  }
}

/// The prismatic joint is probably more commonly known as a slider joint.
/// The two joined bodies have their rotation held fixed relative to each
/// other, and they can only move along a specified axis.
///
/// Prismatic joints can be given limits so that the bodies can only move
/// along the axis within a specific range. They can also be given a motor so
/// that the bodies will try to move at a given speed, with a given force.
///
/// Common uses for prismatic joints include:
/// - elevators
/// - moving platforms
/// - sliding doors
/// - pistons
///
///     new PhysicsJointPrismatic(
///       nodeA.physicsBody,
///       nodeB.physicsBody,
///       new Offset(0.0, 1.0)
///     );
class PhysicsJointPrismatic extends PhysicsJoint {
  PhysicsJointPrismatic(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.axis, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      bool enableMotor: false,
      double motorSpeed: 0.0,
      double maxMotorForce: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _enableMotor = enableMotor;
    _motorSpeed = motorSpeed;
    _maxMotorForce = maxMotorForce;
    _completeCreation();
  }

  /// Axis that the movement is restricted to (in global space at the time of
  /// creation)
  final Offset axis;

  bool _enableMotor;

  /// For the motor to be effective you also need to set [motorSpeed] and
  /// [maxMotorForce].
  bool get enableMotor => _enableMotor;

  set enableMotor(bool enableMotor) {
    _enableMotor = enableMotor;
    if (_joint != null) {
      box2d.PrismaticJoint prismaticJoint = _joint;
      prismaticJoint.enableMotor(enableMotor);
    }
  }

  double _motorSpeed;

  /// Sets the motor speed of this joint, will only work if [enableMotor] is
  /// set to true and [maxMotorForce] is set to a non zero value.
  double get motorSpeed => _motorSpeed;

  set motorSpeed(double motorSpeed) {
    _motorSpeed = motorSpeed;
    if (_joint != null) {
      box2d.PrismaticJoint prismaticJoint = _joint;
      prismaticJoint.setMotorSpeed(motorSpeed / _physicsWorld.b2WorldToNodeConversionFactor);
    }
  }

  double _maxMotorForce;

  /// Sets the motor force of this joint, will only work if [enableMotor] is
  /// set to true and [motorSpeed] is set to a non zero value.
  double get maxMotorForce => _maxMotorForce;

  set maxMotorForce(double maxMotorForce) {
    _maxMotorForce = maxMotorForce;
    if (_joint != null) {
      box2d.PrismaticJoint prismaticJoint = _joint;
      prismaticJoint.setMaxMotorForce(maxMotorForce / _physicsWorld.b2WorldToNodeConversionFactor);
    }
  }

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.PrismaticJointDef b2Def = new box2d.PrismaticJointDef();
    b2Def.initialize(bodyA._body, bodyB._body, bodyA._body.position, new Vector2(axis.dx, axis.dy));
    b2Def.enableMotor = _enableMotor;
    b2Def.motorSpeed = _motorSpeed;
    b2Def.maxMotorForce = _maxMotorForce;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

/// The weld joint attempts to constrain all relative motion between two bodies.
///
///     new PhysicsJointWeld(bodyA.physicsJoint, bodyB.physicsJoint)
class PhysicsJointWeld extends PhysicsJoint {
  PhysicsJointWeld(
    PhysicsBody bodyA,
    PhysicsBody bodyB, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
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

/// A pulley is used to create an idealized pulley. The pulley connects two
/// bodies to ground and to each other. As one body goes up, the other goes
/// down.
///
/// The total length of the pulley rope is conserved according to the initial
/// configuration.
///
///     new PhysicsJointPulley(
///       nodeA.physicsBody,
///       nodeB.physicsBody,
///       new Point(0.0, 100.0),
///       new Point(100.0, 100.0),
///       nodeA.position,
///       nodeB.position,
///       1.0
///     );
class PhysicsJointPulley extends PhysicsJoint {
  PhysicsJointPulley(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.groundAnchorA,
    this.groundAnchorB,
    this.anchorA,
    this.anchorB,
    this.ratio, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final Point groundAnchorA;
  final Point groundAnchorB;
  final Point anchorA;
  final Point anchorB;
  final double ratio;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
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

/// The gear joint can only connect revolute and/or prismatic joints.
///
/// Like the pulley ratio, you can specify a gear ratio. However, in this case
/// the gear ratio can be negative. Also keep in mind that when one joint is a
/// revolute joint (angular) and the other joint is prismatic (translation),
/// and then the gear ratio will have units of length or one over length.
///
///     new PhysicsJointGear(nodeA.physicsBody, nodeB.physicsBody);
class PhysicsJointGear extends PhysicsJoint {
  PhysicsJointGear(
    PhysicsBody bodyA,
    PhysicsBody bodyB, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.ratio: 1.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  /// The ratio of the rotation for bodyA relative bodyB.
  final double ratio;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.GearJointDef b2Def = new box2d.GearJointDef();
    b2Def.bodyA = bodyA._body;
    b2Def.bodyB = bodyB._body;
    b2Def.ratio = ratio;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

/// Keeps a fixed distance between two bodies, [anchorA] and [anchorB] are
/// defined in world coordinates.
class PhysicsJointDistance extends PhysicsJoint {
  PhysicsJointDistance(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchorA,
    this.anchorB, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.length,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  /// The anchor of bodyA in world coordinates at the time of creation.
  final Point anchorA;

  /// The anchor of bodyB in world coordinates at the time of creation.
  final Point anchorB;

  /// The desired distance between the joints, if not passed in at creation
  /// it will be set automatically to the distance between the anchors at the
  /// time of creation.
  final double length;

  /// Dampening factor.
  final double dampening;

  /// Dampening frequency.
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.DistanceJointDef b2Def = new box2d.DistanceJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(anchorA, physicsNode),
      _convertPosToVec(anchorB, physicsNode)
    );
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;
    if (length != null)
      b2Def.length = length / physicsNode.b2WorldToNodeConversionFactor;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

/// The wheel joint restricts a point on bodyB to a line on bodyA. The wheel
/// joint also optionally provides a suspension spring.
class PhysicsJointWheel extends PhysicsJoint {
  PhysicsJointWheel(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchor,
    this.axis, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  /// The rotational point in global space at the time of creation.
  final Point anchor;

  /// The axis which to restrict the movement to.
  final Offset axis;

  /// Dampening factor.
  final double dampening;

  /// Dampening frequency.
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.WheelJointDef b2Def = new box2d.WheelJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(anchor, physicsNode),
      new Vector2(axis.dx, axis.dy)
    );
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

/// The friction joint is used for top-down friction. The joint provides 2D
/// translational friction and angular friction.
class PhysicsJointFriction extends PhysicsJoint {
  PhysicsJointFriction(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchor, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.maxForce: 0.0,
      this.maxTorque: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final Point anchor;
  final double maxForce;
  final double maxTorque;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.FrictionJointDef b2Def = new box2d.FrictionJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(anchor, physicsNode)
    );
    b2Def.maxForce = maxForce / physicsNode.b2WorldToNodeConversionFactor;
    b2Def.maxTorque = maxTorque / physicsNode.b2WorldToNodeConversionFactor;
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointConstantVolume extends PhysicsJoint {
  PhysicsJointConstantVolume(
    this.bodies, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.dampening,
      this.frequency
    }
  ) : super(null, null, breakingForce, breakCallback) {
    assert(bodies.length > 2);
    _bodyA = bodies[0];
    _bodyB = bodies[1];
    _completeCreation();
  }

  final List<PhysicsBody> bodies;
  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.ConstantVolumeJointDef b2Def = new box2d.ConstantVolumeJointDef();
    for (PhysicsBody body in bodies) {
      b2Def.addBody(body._body);
    }
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;
    return physicsNode.b2World.createJoint(b2Def);
  }
}

Vector2 _convertPosToVec(Point pt, PhysicsWorld physicsNode) {
  return new Vector2(
    pt.x / physicsNode.b2WorldToNodeConversionFactor,
    pt.y / physicsNode.b2WorldToNodeConversionFactor
  );
}
