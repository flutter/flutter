part of flutter_sprites;

/// A constraint limits or otherwise controls a [Node]'s properties, such as
/// position or rotation. Add a list of constraints by setting the [Node]'s
/// constraints property.
///
/// Constrains are applied after the update calls are
/// completed. They can also be applied at any time by calling a [Node]'s
/// [applyConstraints] method. It's possible to create custom constraints by
/// overriding this class and implementing the [constrain] method.
abstract class Constraint {
  /// Called before the node's update method is called. This method can be
  /// overridden to create setup work that needs to happen before the the
  /// node is updated, e.g. to calculate the node's speed.
  void preUpdate(Node node, double dt) {
  }

  /// Called after update is complete, if the constraint has been added to a
  /// [Node]. Override this method to modify the node's property according to
  /// the constraint.
  void constrain(Node node, double dt);
}

double _dampenRotation(double src, double dst, double dampening) {
  if (dampening == null)
    return dst;

  double delta = dst - src;
  while (delta > 180.0) delta -= 360;
  while (delta < -180) delta += 360;
  delta *= dampening;

  return src + delta;
}

/// A [Constraint] that aligns a nodes rotation to its movement.
class ConstraintRotationToMovement extends Constraint {
  /// Creates a new constraint the aligns a nodes rotation to its movement
  /// vector. A [baseRotation] and [dampening] can optionally be set.
  ConstraintRotationToMovement({this.baseRotation: 0.0, this.dampening});

  /// The filter factor used when constraining the rotation of the node. Valid
  /// values are in the range 0.0 to 1.0
  final double dampening;

  /// The base rotation will be added to a the movement vectors rotation.
  final double baseRotation;

  Point _lastPosition;

  void preUpdate(Node node, double dt) {
    _lastPosition = node.position;
  }

  void constrain(Node node, double dt) {
    if (_lastPosition == null) return;
    if (_lastPosition == node.position) return;

    // Get the target angle
    Offset offset = node.position - _lastPosition;
    double target = degrees(GameMath.atan2(offset.dy, offset.dx)) + baseRotation;

    node.rotation = _dampenRotation(node.rotation, target, dampening);
  }
}

/// A [Constraint] that rotates a node to point towards another node. The target
/// node is allowed to have a different parent, but they must be in the same
/// [SpriteBox].
class ConstraintRotationToNode extends Constraint {
  /// Creates a new [Constraint] that rotates the node towards the [targetNode].
  /// The [baseRotation] will be added to the nodes rotation, and [dampening]
  /// can be used to ease the rotation.
  ConstraintRotationToNode(this.targetNode, {this.baseRotation: 0.0, this.dampening});

  /// The node to rotate towards.
  final Node targetNode;

  /// The base rotation will be added after the target rotation is calculated.
  final double baseRotation;

  /// The filter factor used when constraining the rotation of the node. Valid
  /// values are in the range 0.0 to 1.0
  final double dampening;

  void constrain(Node node, double dt) {
    Offset offset;

    if (targetNode.spriteBox != node.spriteBox) {
      // The target node is in another sprite box or has been removed
      return;
    }

    if (targetNode.parent == node.parent) {
      offset = targetNode.position - node.position;
    } else {
      offset = node.convertPointToBoxSpace(Point.origin)
        - targetNode.convertPointToBoxSpace(Point.origin);
    }

    double target = degrees(GameMath.atan2(offset.dy, offset.dx)) + baseRotation;

    node.rotation = _dampenRotation(node.rotation, target, dampening);
  }
}

/// A [Constraint] that constrains the position of a node to equal the position
/// of another node, optionally with dampening.
class ConstraintPositionToNode extends Constraint {
  /// Creates a new [Constraint] that constrains the poistion of a node to be
  /// equal to the position of the [targetNode]. Optionally an [offset] can
  /// be used and also [dampening]. The targetNode doesn't need to have the
  /// same parent, but they need to be added to the same [SpriteBox].
  ConstraintPositionToNode(this.targetNode, {this.dampening, this.offset: Offset.zero});

  final Node targetNode;
  final Offset offset;
  final double dampening;

  void constrain(Node node, double dt) {
    Point targetPosition;

    if (targetNode.spriteBox != node.spriteBox || node.parent == null) {
      // The target node is in another sprite box or has been removed
      return;
    }

    if (targetNode.parent == node.parent) {
      targetPosition = targetNode.position;
    } else {
      targetPosition = node.parent.convertPointFromNode(Point.origin, targetNode);
    }

    if (offset != null)
      targetPosition += offset;

    if (dampening == null)
      node.position = targetPosition;
    else
      node.position = GameMath.filterPoint(node.position, targetPosition, dampening);
  }
}
