import 'package:meta/meta.dart';

import '../exceptions/parent_exception.dart';
import '../nodes/node.dart';

/// Parent interface for nodes.
mixin XmlParentBase {
  /// Return the parent node of this node, or `null` if there is none.
  XmlNode? get parent => null;

  /// Test whether the node has a parent or not.
  bool get hasParent => false;

  /// Replace this node with `other`.
  void replace(XmlNode other) => _throwNoParent();

  /// Internal helper to attach a child to this parent, do not call directly.
  @internal
  void attachParent(covariant XmlNode parent) => _throwNoParent();

  /// Internal helper to detach a child from its parent, do not call directly.
  @internal
  void detachParent(covariant XmlNode parent) => _throwNoParent();

  /// Internal helper to throw an exception.
  void _throwNoParent() =>
      throw UnsupportedError('$this does not have a parent.');
}

/// Mixin for nodes with a parent.
mixin XmlHasParent<T extends XmlNode> implements XmlParentBase {
  T? _parent;

  @override
  T? get parent => _parent;

  @override
  bool get hasParent => _parent != null;

  @override
  void replace(XmlNode other) {
    if (_parent != null) {
      final siblings = _parent!.children;
      for (var i = 0; i < siblings.length; i++) {
        if (identical(siblings[i], this)) {
          siblings[i] = other;
          break;
        }
      }
    }
  }

  @override
  void attachParent(T parent) {
    XmlParentException.checkNoParent(this);
    _parent = parent;
  }

  @override
  void detachParent(T parent) {
    XmlParentException.checkMatchingParent(this, parent);
    _parent = null;
  }
}
