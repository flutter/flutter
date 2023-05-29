import '../nodes/attribute.dart';
import '../utils/name.dart';
import '../utils/name_matcher.dart';
import '../utils/namespace.dart';
import '../utils/node_list.dart';

/// Attribute interface for nodes.
mixin XmlAttributesBase {
  /// Return the attribute nodes of this node in document order.
  List<XmlAttribute> get attributes => const [];

  /// Return the attribute value with the given `name`, or `null`.
  String? getAttribute(String name, {String? namespace}) => null;

  /// Return the attribute node with the given `name`, or `null`.
  XmlAttribute? getAttributeNode(String name, {String? namespace}) => null;

  /// Set the attribute value with the given fully qualified `name` to `value`.
  /// If an attribute with the name already exist, its value is updated.
  /// If the value is `null`, the attribute is removed.
  void setAttribute(String name, String? value, {String? namespace}) =>
      throw UnsupportedError('$this has no attributes.');

  /// Removes the attribute value with the given fully qualified `name`.
  void removeAttribute(String name, {String? namespace}) =>
      setAttribute(name, null, namespace: namespace);
}

/// Mixin for nodes with attributes.
mixin XmlHasAttributes implements XmlAttributesBase {
  @override
  final XmlNodeList<XmlAttribute> attributes = XmlNodeList<XmlAttribute>();

  @override
  String? getAttribute(String name, {String? namespace}) =>
      getAttributeNode(name, namespace: namespace)?.value;

  @override
  XmlAttribute? getAttributeNode(String name, {String? namespace}) {
    final tester = createNameMatcher(name, namespace);
    for (final attribute in attributes) {
      if (tester(attribute)) {
        return attribute;
      }
    }
    return null;
  }

  @override
  void setAttribute(String name, String? value, {String? namespace}) {
    final index = attributes.indexWhere(createNameLookup(name, namespace));
    if (index < 0) {
      if (value != null) {
        final prefix = namespace == null
            ? null
            : lookupNamespacePrefix(this as dynamic, namespace);
        attributes.add(XmlAttribute(XmlName(name, prefix), value));
      }
    } else {
      if (value != null) {
        attributes[index].value = value;
      } else {
        attributes.removeAt(index);
      }
    }
  }
}
