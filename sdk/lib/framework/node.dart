library node;

class Node {

  // Nodes always have a 'depth' greater than their ancestors'.
  // There's no guarantee regarding depth between siblings. The depth
  // of a node is used to ensure that nodes are processed in depth
  // order. The 'depth' of a child can be more than one greater than
  // the 'depth' of the parent, because the 'depth' values are never
  // decreased: all that matters is that it's greater than the parent.
  // Consider a tree with a root node A, a child B, and a grandchild
  // C. Initially, A will have 'depth' 0, B 'depth' 1, and C 'depth'
  // 2. If C is moved to be a child of A, sibling of B, then the
  // numbers won't change. C's 'depth' will still be 2.

  int _depth = 0;
  int get depth => _depth;
  void redepthChild(Node child) { // internal, do not call
    assert(child._attached == _attached);
    if (child._depth <= _depth) {
      child._depth = _depth + 1;
      child.redepthChildren();
    }
  }
  void redepthChildren() { // internal, do not call
    // override this in subclasses with child nodes
    // simply call redepthChild(child) for each child
  }

  bool _attached = false;
  bool get attached => _attached;
  void attach() {
    // override this in subclasses with child nodes
    // simply call attach() for each child then call your superclass
    _attached = true;
    attachChildren();
  }
  attachChildren() { } // workaround for lack of inter-class mixins in Dart
  void detach() {
    // override this in subclasses with child nodes
    // simply call detach() for each child then call your superclass
    _attached = false;
    detachChildren();
  }
  detachChildren() { } // workaround for lack of inter-class mixins in Dart

  Node _parent;
  Node get parent => _parent;
  void adoptChild(Node child) { // only for use by subclasses
    assert(child != null);
    assert(child._parent == null);
    child._parent = this;
    if (attached)
      child.attach();
    redepthChild(child);
  }
  void dropChild(Node child) { // only for use by subclasses
    assert(child != null);
    assert(child._parent == this);
    assert(child.attached == attached);
    child._parent = null;
    if (attached)
      child.detach();
  }

}
