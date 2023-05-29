import '../enums/node_type.dart';
import '../mixins/has_attributes.dart';
import '../mixins/has_children.dart';
import '../mixins/has_name.dart';
import '../mixins/has_parent.dart';
import '../utils/name.dart';
import '../visitors/visitor.dart';
import 'attribute.dart';
import 'node.dart';

/// XML element node.
class XmlElement extends XmlNode
    with
        XmlHasName,
        XmlHasParent<XmlNode>,
        XmlHasAttributes,
        XmlHasChildren<XmlNode> {
  /// Create an element node with the provided [name], [attributes], and
  /// [children].
  XmlElement(this.name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> childrenIterable = const [],
      this.isSelfClosing = true]) {
    name.attachParent(this);
    attributes.initialize(this, attributeNodeTypes);
    attributes.addAll(attributesIterable);
    children.initialize(this, childrenNodeTypes);
    children.addAll(childrenIterable);
  }

  /// Defines whether the element should be self-closing when empty.
  bool isSelfClosing;

  @override
  final XmlName name;

  @override
  XmlNodeType get nodeType => XmlNodeType.ELEMENT;

  @override
  XmlElement copy() => XmlElement(
      name.copy(),
      attributes.map((each) => each.copy()),
      children.map((each) => each.copy()),
      isSelfClosing);

  @override
  void accept(XmlVisitor visitor) => visitor.visitElement(this);
}

/// Supported child node types.
const Set<XmlNodeType> childrenNodeTypes = {
  XmlNodeType.CDATA,
  XmlNodeType.COMMENT,
  XmlNodeType.ELEMENT,
  XmlNodeType.PROCESSING,
  XmlNodeType.TEXT,
};

/// Supported attribute node types.
const Set<XmlNodeType> attributeNodeTypes = {
  XmlNodeType.ATTRIBUTE,
};
