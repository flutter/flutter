// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An abstract node in a tree
///
/// AbstractNode has as notion of depth, attachment, and parent, but does not
/// have a model for children.
///
/// * When a subclass is changing the parent of a child, it should
///   call either parent.adoptChild(child) or parent.dropChild(child)
///   as appropriate. Subclasses should expose an API for
///   manipulating the tree if you want to (e.g. a setter for a
///   'child' property, or an 'add()' method to manipulate a list).
///
/// * You can see the current parent by querying 'parent'.
///
/// * You can see the current attachment state by querying
///   'attached'. The root of any tree that is to be considered
///   attached should be manually attached by calling 'attach()'.
///   Other than that, don't call 'attach()' or 'detach()'. This is
///   all managed automatically assuming you call the 'adoptChild()'
///   and 'dropChild()' methods appropriately.
///
/// * Subclasses that have children must override 'attach()' and
///   'detach()' as described below.
///
/// * Nodes always have a 'depth' greater than their ancestors'.
///   There's no guarantee regarding depth between siblings. The
///   depth of a node is used to ensure that nodes are processed in
///   depth order. The 'depth' of a child can be more than one
///   greater than the 'depth' of the parent, because the 'depth'
///   values are never decreased: all that matters is that it's
///   greater than the parent. Consider a tree with a root node A, a
///   child B, and a grandchild C. Initially, A will have 'depth' 0,
///   B 'depth' 1, and C 'depth' 2. If C is moved to be a child of A,
///   sibling of B, then the numbers won't change. C's 'depth' will
///   still be 2. This is all managed automatically assuming you call
///   'adoptChild()' and 'dropChild()' appropriately.
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
  /// Typically called only from the parent's attach(), and to mark the root of
  /// a tree attached.
  void attach() {
    _attached = true;
  }

  /// Mark this node as detached.
  ///
  /// Typically called only from the parent's detach(), and to mark the root of
  /// a tree detached.
  void detach() {
    _attached = false;
  }

  AbstractNode _parent;
  /// The parent of this node in the tree.
  AbstractNode get parent => _parent;

  /// Subclasses should call this function when they acquire a new child.
  void adoptChild(AbstractNode child) {
    assert(child != null);
    assert(child._parent == null);
    assert(() {
      AbstractNode node = this;
      while (node.parent != null)
        node = node.parent;
      assert(node != child); // indicates we are about to create a cycle
      return true;
    });
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
