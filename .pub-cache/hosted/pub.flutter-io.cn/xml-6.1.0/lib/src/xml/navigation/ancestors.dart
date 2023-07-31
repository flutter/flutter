import 'dart:collection';

import '../nodes/element.dart';
import '../nodes/node.dart';

extension XmlAncestorsExtension on XmlNode {
  /// Return a lazy [Iterable] of the ancestors of this node (parent,
  /// grandparent, ...) in reverse document order.
  Iterable<XmlNode> get ancestors => XmlAncestorsIterable(this);

  /// Return a lazy [Iterable] of the ancestor [XmlElement] nodes of this
  /// node (parent, grandparent, ...) in reverse document order.
  Iterable<XmlElement> get ancestorElements =>
      ancestors.whereType<XmlElement>();
}

/// Iterable to walk over the ancestors of a node.
class XmlAncestorsIterable extends IterableBase<XmlNode> {
  XmlAncestorsIterable(this._start);

  final XmlNode _start;

  @override
  Iterator<XmlNode> get iterator => XmlAncestorsIterator(_start);
}

/// Iterator to walk over the ancestors of a node.
class XmlAncestorsIterator extends Iterator<XmlNode> {
  XmlAncestorsIterator(this._current);

  XmlNode? _current;

  @override
  XmlNode get current => _current!;

  @override
  bool moveNext() {
    if (_current != null) {
      _current = _current!.parent;
    }
    return _current != null;
  }
}
