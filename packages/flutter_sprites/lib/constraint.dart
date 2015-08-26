part of skysprites;

abstract class Constraint {
  void preUpdate(Node node, double dt) {
  }

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

class ConstraintRotationToMovement extends Constraint {
  ConstraintRotationToMovement([this.baseRotation = 0.0, this.dampening]);

  final double dampening;
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

class ConstraintRotationToNode extends Constraint {
  ConstraintRotationToNode(this.targetNode, [this.baseRotation, this.dampening]);

  final Node targetNode;
  final double baseRotation;
  final double dampening;

  void constrain(Node node, double dt) {
    Offset offset;

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
