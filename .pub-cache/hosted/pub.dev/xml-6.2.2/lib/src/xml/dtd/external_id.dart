import '../enums/attribute_type.dart';
import '../utils/token.dart';

/// Immutable external ID.
class DtdExternalId {
  DtdExternalId.public(String this.publicId, XmlAttributeType this.publicIdType,
      this.systemId, this.systemIdType);

  DtdExternalId.system(this.systemId, this.systemIdType)
      : publicId = null,
        publicIdType = null;

  /// The public identifier for the external subset of the document type
  /// definition. This is a string, or `null`.
  final String? publicId;

  final XmlAttributeType? publicIdType;

  /// The system identifier for the external subset of the document type
  /// definition. This is a URI as a string, or `null`.
  final String systemId;

  final XmlAttributeType systemIdType;

  @override
  String toString() {
    final buffer = StringBuffer();
    if (publicId != null) {
      buffer.write(XmlToken.doctypePublicId);
      buffer.write(XmlToken.whitespace);
      buffer.write(publicIdType!.token);
      buffer.write(publicId);
      buffer.write(publicIdType!.token);
    } else {
      buffer.write(XmlToken.doctypeSystemId);
    }
    buffer.write(XmlToken.whitespace);
    buffer.write(systemIdType.token);
    buffer.write(systemId);
    buffer.write(systemIdType.token);
    return buffer.toString();
  }

  @override
  int get hashCode => Object.hash(systemId, publicId);

  @override
  bool operator ==(Object other) =>
      other is DtdExternalId &&
      other.publicId == other.publicId &&
      other.systemId == other.systemId;
}
