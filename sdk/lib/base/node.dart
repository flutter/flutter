// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class AbstractNode {

  // AbstractNode represents a node in a tree.
  // The AbstractNode protocol is described in README.md.

  int _depth = 0;
  int get depth => _depth;
  void redepthChild(AbstractNode child) { // internal, do not call
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

  AbstractNode _parent;
  AbstractNode get parent => _parent;
  void adoptChild(AbstractNode child) { // only for use by subclasses
    assert(child != null);
    assert(child._parent == null);
    child._parent = this;
    if (attached)
      child.attach();
    redepthChild(child);
  }
  void dropChild(AbstractNode child) { // only for use by subclasses
    assert(child != null);
    assert(child._parent == this);
    assert(child.attached == attached);
    child._parent = null;
    if (attached)
      child.detach();
  }

}
