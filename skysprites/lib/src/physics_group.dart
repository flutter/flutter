part of flutter_sprites;

/// A [Node] that acts as a middle layer between a [PhysicsWorld] and a node
/// with an assigned [PhysicsBody]. The group's transformations are limited to
/// [position], [rotation], and uniform [scale].
///
///     PhysicsGroup group = new PhysicsGroup();
///     myWorld.addChild(group);
///     group.addChild(myNode);
class PhysicsGroup extends Node {

  set scaleX(double scaleX) {
    assert(false);
  }

  set scaleY(double scaleX) {
    assert(false);
  }

  set skewX(double scaleX) {
    assert(false);
  }

  set skewY(double scaleX) {
    assert(false);
  }

  set physicsBody(PhysicsBody body) {
    assert(false);
  }

  set position(Point position) {
    super.position = position;
    _invalidatePhysicsBodies(this);
  }

  set rotation(double rotation) {
    super.rotation = rotation;
    _invalidatePhysicsBodies(this);
  }

  set scale(double scale) {
    super.scale = scale;
    _invalidatePhysicsBodies(this);
  }

  void _invalidatePhysicsBodies(Node node) {
    if (_world == null) return;

    if (node.physicsBody != null) {
      // TODO: Add to list
      _world._bodiesScheduledForUpdate.add(node.physicsBody);
    }

    for (Node child in node.children) {
      _invalidatePhysicsBodies(child);
    }
  }

  void addChild(Node node) {
    super.addChild(node);

    PhysicsWorld world = _world;
    if (node.physicsBody != null && world != null) {
      node.physicsBody._attach(world, node);
    }

    if (node is PhysicsGroup) {
      _attachGroup(this, world);
    }
  }

  void _attachGroup(PhysicsGroup group, PhysicsWorld world) {
    for (Node child in group.children) {
      if (child is PhysicsGroup) {
        _attachGroup(child, world);
      } else if (child.physicsBody != null) {
        child.physicsBody._attach(world, child);
      }
    }
  }

  void removeChild(Node node) {
    super.removeChild(node);

    if (node.physicsBody != null) {
      node.physicsBody._detach();
    }

    if (node is PhysicsGroup) {
      _detachGroup(this);
    }
  }

  void _detachGroup(PhysicsGroup group) {
    for (Node child in group.children) {
      if (child is PhysicsGroup) {
        _detachGroup(child);
      } else if (child.physicsBody != null) {
        child.physicsBody._detach();
      }
    }
  }

  PhysicsWorld get _world {
    if (this.parent is PhysicsWorld)
      return this.parent;
    if (this.parent is PhysicsGroup) {
      PhysicsGroup group = this.parent;
      return group._world;
    }
    return null;
  }
}
