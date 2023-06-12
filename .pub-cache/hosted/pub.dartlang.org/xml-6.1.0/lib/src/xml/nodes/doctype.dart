import '../dtd/external_id.dart';
import '../enums/node_type.dart';
import '../mixins/has_parent.dart';
import '../visitors/visitor.dart';
import 'node.dart';

/// XML doctype node.
class XmlDoctype extends XmlNode with XmlHasParent<XmlNode> {
  /// Create a doctype section.
  XmlDoctype(this.name, [this.externalId, this.internalSubset]);

  /// The name of the declaration.
  final String name;

  /// The external ID of the declaration, or `null`.
  final DtdExternalId? externalId;

  /// The complete internal subset of the declaration as a [String], or `null`.
  final String? internalSubset;

  @override
  XmlNodeType get nodeType => XmlNodeType.DOCUMENT_TYPE;

  @override
  XmlDoctype copy() => XmlDoctype(name, externalId, internalSubset);

  @override
  void accept(XmlVisitor visitor) => visitor.visitDoctype(this);
}
