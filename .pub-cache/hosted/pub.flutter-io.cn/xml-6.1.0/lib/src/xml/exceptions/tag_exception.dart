import 'exception.dart';
import 'format_exception.dart';

/// Exception thrown when the end tag does not match the open tag.
class XmlTagException extends XmlException with XmlFormatException {
  /// Creates a new XmlTagException.
  XmlTagException(
    super.message, {
    this.expectedName,
    this.actualName,
    this.buffer,
    this.position,
  });

  /// Creates a new XmlTagException where [expectedName] was expected, but
  /// instead we found [actualName].
  factory XmlTagException.mismatchClosingTag(
          String expectedName, String actualName,
          {String? buffer, int? position}) =>
      XmlTagException('Expected </$expectedName>, but found </$actualName>',
          expectedName: expectedName,
          actualName: actualName,
          buffer: buffer,
          position: position);

  /// Creates a new XmlTagException for an unexpected closing tag.
  factory XmlTagException.unexpectedClosingTag(String actualName,
          {String? buffer, int? position}) =>
      XmlTagException('Unexpected </$actualName>',
          actualName: actualName, buffer: buffer, position: position);

  /// Creates a new XmlTagException for a missing closing tag.
  factory XmlTagException.missingClosingTag(String expectedName,
          {String? buffer, int? position}) =>
      XmlTagException('Missing </$expectedName>',
          expectedName: expectedName, buffer: buffer, position: position);

  /// Ensure that the [expected] tag matches the [actual] one.
  static void checkClosingTag(String expectedName, String actualName,
      {String? buffer, int? position}) {
    if (expectedName != actualName) {
      throw XmlTagException.mismatchClosingTag(expectedName, actualName,
          buffer: buffer, position: position);
    }
  }

  /// The tag name that was expected, or `null`.
  final String? expectedName;

  /// The tag name that was found, or `null`.
  final String? actualName;

  @override
  String? buffer;

  @override
  int? position;

  @override
  String toString() => 'XmlTagException: $message at $locationString';
}
