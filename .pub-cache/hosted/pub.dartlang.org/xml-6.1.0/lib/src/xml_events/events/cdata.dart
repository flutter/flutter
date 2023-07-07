import '../../xml/enums/node_type.dart';
import '../event.dart';
import '../visitor.dart';

/// Event of an XML CDATA node.
class XmlCDATAEvent extends XmlEvent {
  XmlCDATAEvent(this.text);

  final String text;

  @override
  XmlNodeType get nodeType => XmlNodeType.CDATA;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitCDATAEvent(this);

  @override
  int get hashCode => Object.hash(nodeType, text);

  @override
  bool operator ==(Object other) =>
      other is XmlCDATAEvent && other.text == text;
}
