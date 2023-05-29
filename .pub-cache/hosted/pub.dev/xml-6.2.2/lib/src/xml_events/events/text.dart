import '../../xml/entities/entity_mapping.dart';
import '../../xml/enums/node_type.dart';
import '../event.dart';
import '../visitor.dart';

/// Event of an XML text node.
class XmlTextEvent extends XmlEvent {
  XmlTextEvent(this.text);

  final String text;

  @override
  XmlNodeType get nodeType => XmlNodeType.TEXT;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitTextEvent(this);

  @override
  int get hashCode => Object.hash(nodeType, text);

  @override
  bool operator ==(Object other) => other is XmlTextEvent && other.text == text;
}

/// Internal event of an XML text node that is lazily decoded.
class XmlRawTextEvent extends XmlEvent implements XmlTextEvent {
  XmlRawTextEvent(this.raw, this.entityMapping);

  final String raw;

  final XmlEntityMapping entityMapping;

  @override
  late final String text = entityMapping.decode(raw);

  @override
  XmlNodeType get nodeType => XmlNodeType.TEXT;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitTextEvent(this);

  @override
  int get hashCode => Object.hash(nodeType, text);

  @override
  bool operator ==(Object other) => other is XmlTextEvent && other.text == text;
}
