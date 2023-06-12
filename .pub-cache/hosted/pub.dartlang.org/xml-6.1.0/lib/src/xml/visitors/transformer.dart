import '../mixins/has_visitor.dart';
import '../nodes/attribute.dart';
import '../nodes/cdata.dart';
import '../nodes/comment.dart';
import '../nodes/declaration.dart';
import '../nodes/doctype.dart';
import '../nodes/document.dart';
import '../nodes/document_fragment.dart';
import '../nodes/element.dart';
import '../nodes/processing.dart';
import '../nodes/text.dart';
import '../utils/name.dart';

/// External transformer that creates an identical copy of the visited nodes.
///
/// Subclass can override one or more of the methods to modify the generated
/// copy.
@Deprecated('Use `XmlNode.copy()` and mutate the DOM in-place, or create a '
    'strongly-typed `XmlVisitor` over your DOM.')
class XmlTransformer {
  const XmlTransformer();

  T visit<T extends XmlHasVisitor>(T node) {
    if (node is XmlAttribute) {
      return visitAttribute(node) as T;
    } else if (node is XmlCDATA) {
      return visitCDATA(node) as T;
    } else if (node is XmlComment) {
      return visitComment(node) as T;
    } else if (node is XmlDeclaration) {
      return visitDeclaration(node) as T;
    } else if (node is XmlDoctype) {
      return visitDoctype(node) as T;
    } else if (node is XmlDocument) {
      return visitDocument(node) as T;
    } else if (node is XmlDocumentFragment) {
      return visitDocumentFragment(node) as T;
    } else if (node is XmlElement) {
      return visitElement(node) as T;
    } else if (node is XmlName) {
      return visitName(node) as T;
    } else if (node is XmlProcessing) {
      return visitProcessing(node) as T;
    } else if (node is XmlText) {
      return visitText(node) as T;
    } else {
      throw StateError('Unknown node type: ${node.runtimeType}');
    }
  }

  XmlAttribute visitAttribute(XmlAttribute node) =>
      XmlAttribute(visit(node.name), node.value, node.attributeType);

  XmlCDATA visitCDATA(XmlCDATA node) => XmlCDATA(node.text);

  XmlComment visitComment(XmlComment node) => XmlComment(node.text);

  XmlDeclaration visitDeclaration(XmlDeclaration node) =>
      XmlDeclaration(node.attributes.map(visit));

  XmlDoctype visitDoctype(XmlDoctype node) => XmlDoctype(node.text);

  XmlDocument visitDocument(XmlDocument node) =>
      XmlDocument(node.children.map(visit));

  XmlDocumentFragment visitDocumentFragment(XmlDocumentFragment node) =>
      XmlDocumentFragment(node.children.map(visit));

  XmlElement visitElement(XmlElement node) => XmlElement(visit(node.name),
      node.attributes.map(visit), node.children.map(visit), node.isSelfClosing);

  XmlName visitName(XmlName name) => XmlName.fromString(name.qualified);

  XmlProcessing visitProcessing(XmlProcessing node) =>
      XmlProcessing(node.target, node.text);

  XmlText visitText(XmlText node) => XmlText(node.text);
}
