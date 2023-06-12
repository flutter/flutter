/// Abstract exception class.
abstract class XmlException implements Exception {
  /// Creates a new XmlException with an error [message].
  XmlException(this.message);

  /// A message describing the XML error.
  final String message;
}
