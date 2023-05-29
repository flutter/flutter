import '../enums/node_type.dart';
import '../mixins/has_attributes.dart';
import '../mixins/has_parent.dart';
import '../visitors/visitor.dart';
import 'attribute.dart';
import 'node.dart';

/// XML document declaration.
class XmlDeclaration extends XmlNode
    with XmlHasParent<XmlNode>, XmlHasAttributes {
  XmlDeclaration([Iterable<XmlAttribute> attributesIterable = const []]) {
    attributes.initialize(this, attributeNodeTypes);
    attributes.addAll(attributesIterable);
  }

  /// Return the XML version of the document, or `null`.
  String? get version => getAttribute(versionAttribute);

  /// Set the XML version of the document.
  set version(String? value) => setAttribute(versionAttribute, value);

  /// Return the encoding of the document, or `null`.
  String? get encoding => getAttribute(encodingAttribute);

  /// Set the encoding of the document.
  set encoding(String? value) => setAttribute(encodingAttribute, value);

  /// Return the value of the standalone directive.
  bool get standalone => getAttribute(standaloneAttribute) == 'yes';

  /// Set the value of the standalone directive.
  set standalone(bool? value) => setAttribute(
      standaloneAttribute,
      value == null
          ? null
          : value
              ? 'yes'
              : 'no');

  @override
  XmlNodeType get nodeType => XmlNodeType.DECLARATION;

  @override
  XmlDeclaration copy() =>
      XmlDeclaration(attributes.map((each) => each.copy()));

  @override
  void accept(XmlVisitor visitor) => visitor.visitDeclaration(this);
}

/// Supported attribute node types.
const Set<XmlNodeType> attributeNodeTypes = {
  XmlNodeType.ATTRIBUTE,
};

/// Known attribute names.
const versionAttribute = 'version';
const encodingAttribute = 'encoding';
const standaloneAttribute = 'standalone';
