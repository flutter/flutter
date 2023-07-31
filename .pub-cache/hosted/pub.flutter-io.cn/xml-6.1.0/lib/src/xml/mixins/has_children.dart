import '../nodes/element.dart';
import '../nodes/node.dart';
import '../utils/name_matcher.dart';
import '../utils/node_list.dart';

/// Children interface for nodes.
mixin XmlChildrenBase {
  /// Return the direct children of this node in document order.
  List<XmlNode> get children => const [];

  /// Return an [Iterable] over the [XmlElement] children of this node.
  Iterable<XmlElement> get childElements => const [];

  /// Return the first child element with the given `name`, or `null`.
  XmlElement? getElement(String name, {String? namespace}) => null;

  /// Return the first child of this node, or `null` if there are no children.
  XmlNode? get firstChild => null;

  /// Return the first child [XmlElement], or `null` if there are none.
  XmlElement? get firstElementChild => null;

  /// Return the last child of this node, or `null` if there are no children.
  XmlNode? get lastChild => null;

  /// Return the last child [XmlElement], or `null` if there are none.
  XmlElement? get lastElementChild => null;
}

/// Mixin for nodes with children.
mixin XmlHasChildren<T extends XmlNode> implements XmlChildrenBase {
  @override
  final XmlNodeList<T> children = XmlNodeList<T>();

  @override
  Iterable<XmlElement> get childElements => children.whereType<XmlElement>();

  @override
  XmlElement? getElement(String name, {String? namespace}) {
    final tester = createNameMatcher(name, namespace);
    for (final node in children) {
      if (node is XmlElement && tester(node)) {
        return node;
      }
    }
    return null;
  }

  @override
  T? get firstChild => children.isEmpty ? null : children.first;

  @override
  XmlElement? get firstElementChild {
    for (final node in children) {
      if (node is XmlElement) {
        return node;
      }
    }
    return null;
  }

  @override
  T? get lastChild => children.isEmpty ? null : children.last;

  @override
  XmlElement? get lastElementChild {
    for (final node in children.reversed) {
      if (node is XmlElement) {
        return node;
      }
    }
    return null;
  }
}
