import '../exceptions/type_exception.dart';
import '../nodes/document_fragment.dart';
import '../nodes/node.dart';
import 'has_children.dart';
import 'has_parent.dart';
import 'has_writer.dart';

/// Mixin for nodes with XML contents.
mixin XmlHasXml implements XmlChildrenBase, XmlParentBase, XmlHasWriter {
  /// Return the markup representing this node and all its child nodes.
  String get outerXml => toXmlString();

  /// Replaces the markup representing this node and all its child nodes.
  set outerXml(String value) => replace(XmlDocumentFragment.parse(value));

  /// Return the markup representing the child nodes of this node.
  String get innerXml => children.map((node) => node.toXmlString()).join();

  /// Replaces the markup representing the child nodes of this node.
  set innerXml(String value) {
    XmlNodeTypeException.checkHasChildren(this as XmlNode);
    children.clear();
    if (value.isNotEmpty) {
      children.add(XmlDocumentFragment.parse(value));
    }
  }
}
