import '../../xml/enums/node_type.dart';
import '../event.dart';
import '../utils/named.dart';
import '../visitor.dart';

/// Event of an closing XML element node.
class XmlEndElementEvent extends XmlEvent with XmlNamed {
  XmlEndElementEvent(this.name);

  @override
  final String name;

  @override
  XmlNodeType get nodeType => XmlNodeType.ELEMENT;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitEndElementEvent(this);

  @override
  int get hashCode => Object.hash(nodeType, name);

  @override
  bool operator ==(Object other) =>
      other is XmlEndElementEvent && other.name == name;
}
