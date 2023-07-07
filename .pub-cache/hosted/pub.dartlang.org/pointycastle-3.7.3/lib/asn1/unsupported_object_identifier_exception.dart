///
/// Exception that indicates that the given object identifier is not supported
///
class UnsupportedObjectIdentifierException implements Exception {
  String? oiString;

  UnsupportedObjectIdentifierException(this.oiString);

  @override
  String toString() =>
      'UnsupportedObjectIdentifierException: ObjectIdentifier $oiString is not supported yet';
}
