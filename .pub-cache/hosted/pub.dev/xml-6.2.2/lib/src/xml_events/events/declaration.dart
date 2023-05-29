import 'package:collection/collection.dart' show ListEquality;

import '../../xml/enums/node_type.dart';
import '../event.dart';
import '../utils/event_attribute.dart';
import '../visitor.dart';

/// Event of an XML declaration.
class XmlDeclarationEvent extends XmlEvent {
  XmlDeclarationEvent(this.attributes);

  final List<XmlEventAttribute> attributes;

  @override
  XmlNodeType get nodeType => XmlNodeType.DECLARATION;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitDeclarationEvent(this);

  @override
  int get hashCode =>
      Object.hash(nodeType, const ListEquality().hash(attributes));

  @override
  bool operator ==(Object other) =>
      other is XmlDeclarationEvent &&
      const ListEquality().equals(other.attributes, attributes);
}
