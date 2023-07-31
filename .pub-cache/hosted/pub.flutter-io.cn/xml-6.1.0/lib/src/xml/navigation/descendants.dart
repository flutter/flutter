import 'dart:collection';

import '../nodes/element.dart';
import '../nodes/node.dart';

extension XmlDescendantsExtension on XmlNode {
  /// Return a lazy [Iterable] of the descendants of this node (attributes,
  /// children, grandchildren, ...) in document order.
  Iterable<XmlNode> get descendants => XmlDescendantsIterable(this);

  /// Return a lazy [Iterable] of the descendants [XmlElement] nodes of this
  /// node (attributes, children, grandchildren, ...) in document order.
  Iterable<XmlElement> get descendantElements =>
      descendants.whereType<XmlElement>();
}

/// Iterable to walk over the descendants of a node.
class XmlDescendantsIterable extends IterableBase<XmlNode> {
  XmlDescendantsIterable(this._start);

  final XmlNode _start;

  @override
  Iterator<XmlNode> get iterator => XmlDescendantsIterator(_start);
}

/// Iterator to walk over the descendants of a node.
class XmlDescendantsIterator extends Iterator<XmlNode> {
  XmlDescendantsIterator(XmlNode start) {
    push(start);
  }

  final List<XmlNode> _todo = [];
  late XmlNode _current;

  void push(XmlNode node) {
    _todo.addAll(node.children.reversed);
    _todo.addAll(node.attributes.reversed);
  }

  @override
  XmlNode get current => _current;

  @override
  bool moveNext() {
    if (_todo.isEmpty) {
      return false;
    } else {
      _current = _todo.removeLast();
      push(_current);
      return true;
    }
  }
}
