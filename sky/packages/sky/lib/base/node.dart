// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An abstract node in a tree
///
/// AbstractNode has as notion of depth, attachment, and parent, but does not
/// have a model for children.
class AbstractNode {

  // AbstractNode represents a node in a tree.
  // The AbstractNode protocol is described in README.md.

  int _depth = 0;
  /// The depth of this node in the tree.
  ///
  /// The depth of nodes in a tree monotonically increases as you traverse down
  /// the trees.
  int get depth => _depth;

  /// Call only from overrides of [redepthChildren]
  void redepthChild(AbstractNode child) {
    assert(child._attached == _attached);
    if (child._depth <= _depth) {
      child._depth = _depth + 1;
      child.redepthChildren();
    }
  }

  /// Override this function in subclasses with child nodes to call
  /// redepthChild(child) for each child. Do not call directly.
  void redepthChildren() { }

  bool _attached = false;
  /// Whether this node is in a tree whose root is attached to something.
  bool get attached => _attached;

  /// Mark this node as attached.
  ///
  /// Typically called only from overrides of [attachChildren] and to mark the
  /// root of a tree attached.
  void attach() {
    _attached = true;
    attachChildren();
  }

  /// Override this function in subclasses with child to call attach() for each
  /// child. Do not call directly.
  attachChildren() { }

  /// Mark this node as detached.
  ///
  /// Typically called only from overrides for [detachChildren] and to mark the
  /// root of a tree detached.
  void detach() {
    _attached = false;
    detachChildren();
  }

  /// Override this function in subclasses with child to call detach() for each
  /// child. Do not call directly.
  detachChildren() { }

  // TODO(ianh): remove attachChildren()/detachChildren() workaround once mixins can use super.

  AbstractNode _parent;
  /// The parent of this node in the tree.
  AbstractNode get parent => _parent;

  /// Subclasses should call this function when they acquire a new child.
  void adoptChild(AbstractNode child) {
    assert(child != null);
    assert(child._parent == null);
    child._parent = this;
    if (attached)
      child.attach();
    redepthChild(child);
  }

  /// Subclasses should call this function when they lose a child.
  void dropChild(AbstractNode child) {
    assert(child != null);
    assert(child._parent == this);
    assert(child.attached == attached);
    child._parent = null;
    if (attached)
      child.detach();
  }

}
