import '../enums/node_type.dart';
import '../visitors/visitor.dart';
import 'data.dart';

/// XML processing instruction.
class XmlProcessing extends XmlData {
  /// Create a processing node with `target` and `text`.
  XmlProcessing(this.target, String text) : super(text);

  /// Return the processing target.
  final String target;

  @override
  XmlNodeType get nodeType => XmlNodeType.PROCESSING;

  @override
  XmlProcessing copy() => XmlProcessing(target, text);

  @override
  void accept(XmlVisitor visitor) => visitor.visitProcessing(this);
}
