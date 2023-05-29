import '../enums/attribute_type.dart';
import '../utils/token.dart';

/// Describes the decoding and encoding of character entities.
abstract class XmlEntityMapping {
  const XmlEntityMapping();

  /// Decodes a string, resolving all possible entities.
  String decode(String input) {
    // If we obviously have no entities, return the input string.
    var start = input.indexOf(XmlToken.entityStart, 0);
    if (start < 0) return input;
    // Otherwise traverse the input and decode all entities.
    final buffer = StringBuffer(input.substring(0, start));
    while (true) {
      final index = input.indexOf(XmlToken.entityEnd, start + 1);
      if (start + 1 < index) {
        final entity = input.substring(start + 1, index);
        final value = decodeEntity(entity);
        if (value != null) {
          // Valid entity found, write the transformed value.
          buffer.write(value);
          start = index + 1;
        } else {
          buffer.write(XmlToken.entityStart);
          start++;
        }
      } else {
        buffer.write(XmlToken.entityStart);
        start++;
      }
      // Find the next possible start position of an entity.
      final next = input.indexOf(XmlToken.entityStart, start);
      if (next == -1) {
        // Reached the end of the input.
        buffer.write(input.substring(start));
        break;
      }
      buffer.write(input.substring(start, next));
      start = next;
    }
    return buffer.toString();
  }

  /// Decodes a single character entity, returns the decoded entity or `null` if
  /// the input is invalid.
  String? decodeEntity(String input);

  /// Encodes a string to be serialized as XML text.
  String encodeText(String input);

  /// Encodes a string to be serialized as XML attribute value.
  String encodeAttributeValue(String input, XmlAttributeType type);

  /// Encodes a string to be serialized as XML attribute value together with
  /// its corresponding quotes.
  String encodeAttributeValueWithQuotes(String input, XmlAttributeType type) =>
      '${type.token}${encodeAttributeValue(input, type)}${type.token}';
}
