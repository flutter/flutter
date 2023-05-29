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

/// Basic visitor over [XmlHasVisitor] nodes.
mixin XmlVisitor {
  /// Helper to dispatch the provided [node] onto this visitor.
  void visit(XmlHasVisitor node) => node.accept(this);

  /// Visit an [XmlName].
  void visitName(XmlName name) {}

  /// Visit an [XmlAttribute] node.
  void visitAttribute(XmlAttribute node) {}

  /// Visit an [XmlDeclaration] node.
  void visitDeclaration(XmlDeclaration node) {}

  /// Visit an [XmlDocument] node.
  void visitDocument(XmlDocument node) {}

  /// Visit an [XmlDocumentFragment] node.
  void visitDocumentFragment(XmlDocumentFragment node) {}

  /// Visit an [XmlElement] node.
  void visitElement(XmlElement node) {}

  /// Visit an [XmlCDATA] node.
  void visitCDATA(XmlCDATA node) {}

  /// Visit an [XmlComment] node.
  void visitComment(XmlComment node) {}

  /// Visit an [XmlDoctype] node.
  void visitDoctype(XmlDoctype node) {}

  /// Visit an [XmlProcessing] node.
  void visitProcessing(XmlProcessing node) {}

  /// Visit an [XmlText] node.
  void visitText(XmlText node) {}
}
