import '../enums/node_type.dart';
import '../visitors/visitor.dart';
import 'data.dart';

/// XML comment node.
class XmlComment extends XmlData {
  /// Create a comment section with `text`.
  XmlComment(super.text);

  @override
  XmlNodeType get nodeType => XmlNodeType.COMMENT;

  @override
  XmlComment copy() => XmlComment(text);

  @override
  void accept(XmlVisitor visitor) => visitor.visitComment(this);
}
