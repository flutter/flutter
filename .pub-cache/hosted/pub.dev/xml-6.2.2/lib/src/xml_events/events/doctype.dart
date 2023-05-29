import '../../xml/dtd/external_id.dart';
import '../../xml/enums/node_type.dart';
import '../event.dart';
import '../visitor.dart';

/// Event of an XML doctype node.
class XmlDoctypeEvent extends XmlEvent {
  XmlDoctypeEvent(this.name, [this.externalId, this.internalSubset]);

  /// The name of the declaration.
  final String name;

  /// The external ID of the declaration, or `null`.
  final DtdExternalId? externalId;

  /// The complete internal subset of the declaration as a [String], or `null`.
  final String? internalSubset;

  @override
  XmlNodeType get nodeType => XmlNodeType.DOCUMENT_TYPE;

  @override
  void accept(XmlEventVisitor visitor) => visitor.visitDoctypeEvent(this);

  @override
  int get hashCode => Object.hash(nodeType, name, externalId, internalSubset);

  @override
  bool operator ==(Object other) =>
      other is XmlDoctypeEvent &&
      name == other.name &&
      externalId == other.externalId &&
      internalSubset == other.internalSubset;
}
