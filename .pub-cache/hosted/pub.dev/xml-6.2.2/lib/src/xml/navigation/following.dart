import 'dart:collection';

import '../nodes/attribute.dart';
import '../nodes/element.dart';
import '../nodes/node.dart';

extension XmlFollowingExtension on XmlNode {
  /// Return a lazy [Iterable] of the nodes following this node in document
  /// order.
  Iterable<XmlNode> get following => XmlFollowingIterable(this);

  /// Return a lazy [Iterable] of the [XmlElement] nodes following this node
  /// in document order.
  Iterable<XmlElement> get followingElements =>
      following.whereType<XmlElement>();
}

/// Iterable to walk over the followers of a node.
class XmlFollowingIterable extends IterableBase<XmlNode> {
  XmlFollowingIterable(this._start);

  final XmlNode _start;

  @override
  Iterator<XmlNode> get iterator => XmlFollowingIterator(_start);
}

/// Iterator to walk over the followers of a node.
class XmlFollowingIterator extends Iterator<XmlNode> {
  XmlFollowingIterator(XmlNode start) {
    final following = <XmlNode>[];
    for (var parent = start.parent, child = start;
        parent != null;
        parent = parent.parent, child = child.parent!) {
      if (child is XmlAttribute) {
        final attributesIndex = parent.attributes.indexOf(child);
        following.addAll(parent.attributes.sublist(attributesIndex + 1));
        following.addAll(parent.children);
      } else {
        final childrenIndex = parent.children.indexOf(child);
        following.addAll(parent.children.sublist(childrenIndex + 1));
      }
    }
    _todo.addAll(following.reversed);
  }

  final List<XmlNode> _todo = [];
  XmlNode? _current;

  @override
  XmlNode get current => _current!;

  @override
  bool moveNext() {
    if (_todo.isEmpty) {
      _current = null;
      return false;
    } else {
      _current = _todo.removeLast();
      _todo.addAll(_current!.children.reversed);
      _todo.addAll(_current!.attributes.reversed);
      return true;
    }
  }
}
