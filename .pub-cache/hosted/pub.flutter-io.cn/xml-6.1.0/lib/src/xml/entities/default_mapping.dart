import '../enums/attribute_type.dart';
import 'entity_mapping.dart';
import 'named_entities.dart';

/// The entity mapping used when nothing else is specified.
XmlEntityMapping defaultEntityMapping = const XmlDefaultEntityMapping.xml();

/// Default entity mapping for XML, HTML, and HTML5 entities.
class XmlDefaultEntityMapping extends XmlEntityMapping {
  /// Minimal entity mapping of XML character references.
  const XmlDefaultEntityMapping.xml() : this(xmlEntities);

  /// Minimal entity mapping of HTML character references.
  const XmlDefaultEntityMapping.html() : this(htmlEntities);

  /// Extensive entity mapping of HTML5 character references.
  const XmlDefaultEntityMapping.html5() : this(html5Entities);

  /// Custom entity mapping.
  const XmlDefaultEntityMapping(this.entities);

  /// Named character references.
  final Map<String, String> entities;

  @override
  String? decodeEntity(String input) {
    if (input.length > 1 && input[0] == '#') {
      if (input.length > 2 && (input[1] == 'x' || input[1] == 'X')) {
        // Hexadecimal character reference.
        return _decodeNumericEntity(input.substring(2), 16);
      } else {
        // Decimal character reference.
        return _decodeNumericEntity(input.substring(1), 10);
      }
    } else {
      // Named character reference.
      return entities[input];
    }
  }

  String? _decodeNumericEntity(String input, int radix) {
    final value = int.tryParse(input, radix: radix);
    if (value == null || value < 0 || 0x10FFFF < value) return null;
    return String.fromCharCode(value);
  }

  @override
  String encodeText(String input) =>
      input.replaceAllMapped(_textPattern, _textReplace);

  @override
  String encodeAttributeValue(String input, XmlAttributeType type) {
    switch (type) {
      case XmlAttributeType.SINGLE_QUOTE:
        return input.replaceAllMapped(
            _singeQuoteAttributePattern, _singeQuoteAttributeReplace);
      case XmlAttributeType.DOUBLE_QUOTE:
        return input.replaceAllMapped(
            _doubleQuoteAttributePattern, _doubleQuoteAttributeReplace);
    }
  }
}

// Encode XML text.

final _textPattern = RegExp(r'[&<' + _highlyDiscouragedCharClass + r']|]]>');

String _textReplace(Match match) {
  final toEscape = match.group(0)!;
  switch (toEscape) {
    case '<':
      return '&lt;';
    case '&':
      return '&amp;';
    case ']]>':
      return ']]&gt;';
    default:
      return _asNumericCharacterReferences(toEscape);
  }
}

// Encode XML attribute values (single quotes).

final _singeQuoteAttributePattern =
    RegExp(r"['&<\n\r\t" + _highlyDiscouragedCharClass + r']');

String _singeQuoteAttributeReplace(Match match) {
  final toEscape = match.group(0)!;
  switch (toEscape) {
    case "'":
      return '&apos;';
    case '&':
      return '&amp;';
    case '<':
      return '&lt;';
    default:
      return _asNumericCharacterReferences(toEscape);
  }
}

// Encode XML attribute values (double quotes).

final _doubleQuoteAttributePattern =
    RegExp(r'["&<\n\r\t' + _highlyDiscouragedCharClass + r']');

String _doubleQuoteAttributeReplace(Match match) {
  final toEscape = match.group(0)!;
  switch (toEscape) {
    case '"':
      return '&quot;';
    case '&':
      return '&amp;';
    case '<':
      return '&lt;';
    default:
      return _asNumericCharacterReferences(toEscape);
  }
}

// Lists all C0 and C1 control codes except NUL, HT, LF, CR and NEL.
//
// Sources:
// - https://www.w3.org/TR/xml/#charsets
// - https://en.wikipedia.org/wiki/XML#Valid_Unicode_characters_in_XML_1.0_and_XML_1.1
const _highlyDiscouragedCharClass =
    r'\u0001-\u0008\u000b\u000c\u000e-\u001f\u007f-\u0084\u0086-\u009f';

String _asNumericCharacterReferences(String toEscape) => toEscape.runes
    .map((rune) => '&#x${rune.toRadixString(16).toUpperCase()};')
    .join();
