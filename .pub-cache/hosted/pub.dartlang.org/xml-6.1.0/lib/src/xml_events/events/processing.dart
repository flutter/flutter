import '../../xml/enums/node_type.dart';
import '../event.dart';
import '../visitor.dart';

/// Event of an XML processing node.
class XmlProcessingEvent extends XmlEvent {
  XmlProcessingEvent(this.target, this.text);

  final String target;

  final String text;

  @override
  XmlNodeType get nodeType => XmlNodeType.PROCESSING;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitProcessingEvent(this);

  @override
  int get hashCode => Object.hash(nodeType, text, target);

  @override
  bool operator ==(Object other) =>
      other is XmlProcessingEvent &&
      other.target == target &&
      other.text == text;
}
