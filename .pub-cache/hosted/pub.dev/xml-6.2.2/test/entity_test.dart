import 'package:test/test.dart';
import 'package:xml/src/xml/utils/character_data_parser.dart';
import 'package:xml/xml.dart';

void testDefaultMapping(XmlEntityMapping entityMapping) {
  group('decode', () {
    test('&#xHHHH;', () {
      expect(entityMapping.decode('&#X41;'), 'A');
      expect(entityMapping.decode('&#x61;'), 'a');
      expect(entityMapping.decode('&#x7A;'), 'z');
    });
    test('&#dddd;', () {
      expect(entityMapping.decode('&#65;'), 'A');
      expect(entityMapping.decode('&#97;'), 'a');
      expect(entityMapping.decode('&#122;'), 'z');
    });
    test('&named;', () {
      expect(entityMapping.decode('&lt;'), '<');
      expect(entityMapping.decode('&gt;'), '>');
      expect(entityMapping.decode('&amp;'), '&');
      expect(entityMapping.decode('&apos;'), '\'');
      expect(entityMapping.decode('&quot;'), '"');
    });
    test('invalid', () {
      expect(entityMapping.decode('&Invalid;'), '&Invalid;');
      expect(entityMapping.decode('&#Invalid;'), '&#Invalid;');
      expect(entityMapping.decode('&#xInvalid;'), '&#xInvalid;');
      expect(entityMapping.decode('&#XInvalid;'), '&#XInvalid;');
    });
    test('unicode', () {
      // https://www.compart.com/en/unicode/U+0000
      expect(entityMapping.decode('&#0;'), '\u0000');
      expect(entityMapping.decode('&#x0000;'), '\u0000');
      // https://www.compart.com/en/unicode/U+10FFFF
      expect(entityMapping.decode('&#1114111;'), '\uDBFF\uDFFF');
      expect(entityMapping.decode('&#x10FFFF;'), '\uDBFF\uDFFF');
    });
    test('unicode invalid', () {
      expect(entityMapping.decode('&#-1;'), '&#-1;');
      expect(entityMapping.decode('&#x-1;'), '&#x-1;');
      expect(entityMapping.decode('&#1114112;'), '&#1114112;');
      expect(entityMapping.decode('&#x110000;'), '&#x110000;');
    });
    test('incomplete', () {
      expect(entityMapping.decode('&'), '&');
      expect(entityMapping.decode('&amp'), '&amp');
      expect(entityMapping.decode('a&b'), 'a&b');
      expect(entityMapping.decode('&&gt;'), '&>');
    });
    test('empty', () {
      expect(entityMapping.decode('&;'), '&;');
    });
    test('none', () {
      expect(entityMapping.decode(''), '');
      expect(entityMapping.decode('Hello'), 'Hello');
      expect(entityMapping.decode('Hello World'), 'Hello World');
    });
    test('surrounded', () {
      expect(entityMapping.decode('a&amp;b'), 'a&b');
      expect(entityMapping.decode('&amp;a&amp;'), '&a&');
      expect(entityMapping.decode('a&amp;b&amp;c'), 'a&b&c');
      expect(entityMapping.decode('&amp;a&amp;b&amp;'), '&a&b&');
      expect(entityMapping.decode('a&amp;b&amp;c&amp;d'), 'a&b&c&d');
    });
    test('sequence', () {
      expect(entityMapping.decode('&amp;&amp;'), '&&');
      expect(entityMapping.decode('&lt;&amp;&gt;'), '<&>');
    });
  });
  group('encode', () {
    test('text', () {
      expect(entityMapping.encodeText('<'), '&lt;');
      expect(entityMapping.encodeText('&'), '&amp;');
      expect(entityMapping.encodeText('\u0000\u0008\u0009\u0084\u0085\u0086'),
          '\u0000&#x8;\u0009&#x84;\u0085&#x86;');
      expect(entityMapping.encodeText('hello'), 'hello');
      expect(entityMapping.encodeText('<foo &amp;>'), '&lt;foo &amp;amp;>');
    });
    test('attribute (single quote)', () {
      expect(
          entityMapping.encodeAttributeValue(
              "'", XmlAttributeType.SINGLE_QUOTE),
          '&apos;');
      expect(
          entityMapping.encodeAttributeValue(
              '"', XmlAttributeType.SINGLE_QUOTE),
          '"');
      expect(
          entityMapping.encodeAttributeValue(
              '\t', XmlAttributeType.SINGLE_QUOTE),
          '&#x9;');
      expect(
          entityMapping.encodeAttributeValue(
              '\n', XmlAttributeType.SINGLE_QUOTE),
          '&#xA;');
      expect(
          entityMapping.encodeAttributeValue(
              '\r', XmlAttributeType.SINGLE_QUOTE),
          '&#xD;');
      expect(
          entityMapping.encodeAttributeValue(
              '\u0000\u0008\u0009\u0084\u0085\u0086',
              XmlAttributeType.SINGLE_QUOTE),
          '\u0000&#x8;&#x9;&#x84;\u0085&#x86;');
      expect(
          entityMapping.encodeAttributeValue(
              'hello', XmlAttributeType.SINGLE_QUOTE),
          'hello');
      expect(
          entityMapping.encodeAttributeValue(
              "'hello'", XmlAttributeType.SINGLE_QUOTE),
          '&apos;hello&apos;');
      expect(
          entityMapping.encodeAttributeValue(
              '"hello"', XmlAttributeType.SINGLE_QUOTE),
          '"hello"');
    });
    test('encode attribute (double quote)', () {
      expect(
          entityMapping.encodeAttributeValue(
              "'", XmlAttributeType.DOUBLE_QUOTE),
          "'");
      expect(
          entityMapping.encodeAttributeValue(
              '"', XmlAttributeType.DOUBLE_QUOTE),
          '&quot;');
      expect(
          entityMapping.encodeAttributeValue(
              '\t', XmlAttributeType.DOUBLE_QUOTE),
          '&#x9;');
      expect(
          entityMapping.encodeAttributeValue(
              '\n', XmlAttributeType.DOUBLE_QUOTE),
          '&#xA;');
      expect(
          entityMapping.encodeAttributeValue(
              '\r', XmlAttributeType.DOUBLE_QUOTE),
          '&#xD;');
      expect(
          entityMapping.encodeAttributeValue(
              '\u0000\u0008\u0009\u0084\u0085\u0086',
              XmlAttributeType.DOUBLE_QUOTE),
          '\u0000&#x8;&#x9;&#x84;\u0085&#x86;');
      expect(
          entityMapping.encodeAttributeValue(
              'hello', XmlAttributeType.DOUBLE_QUOTE),
          'hello');
      expect(
          entityMapping.encodeAttributeValue(
              "'hello'", XmlAttributeType.DOUBLE_QUOTE),
          "'hello'");
      expect(
          entityMapping.encodeAttributeValue(
              '"hello"', XmlAttributeType.DOUBLE_QUOTE),
          '&quot;hello&quot;');
    });
  });
}

void main() {
  group('xml', () {
    testDefaultMapping(defaultEntityMapping);
  });
  group('html', () {
    const entityMapping = XmlDefaultEntityMapping.html();
    testDefaultMapping(entityMapping);
    test('special', () {
      expect(entityMapping.decode('&eacute;'), 'é');
      expect(entityMapping.decode('&Eacute;'), 'É');
    });
  });
  group('html5', () {
    const entityMapping = XmlDefaultEntityMapping.html5();
    testDefaultMapping(entityMapping);
    test('special', () {
      expect(entityMapping.decode('&bigstar;'), '★');
      expect(entityMapping.decode('&block;'), '█');
    });
  });
  group('null', () {
    const entityMapping = XmlNullEntityMapping();
    group('decode', () {
      test('basic', () {
        expect(entityMapping.decodeEntity(''), isNull);
        expect(entityMapping.decodeEntity('amp'), isNull);
        expect(entityMapping.decodeEntity('#X41'), isNull);
        expect(entityMapping.decodeEntity('#65'), isNull);
      });
      test('entities', () {
        expect(entityMapping.decode('&#X41;'), '&#X41;');
        expect(entityMapping.decode('&#65;'), '&#65;');
        expect(entityMapping.decode('&amp;'), '&amp;');
      });
      test('invalid entities', () {
        expect(entityMapping.decode('&;'), '&;');
        expect(entityMapping.decode('&invalid;'), '&invalid;');
        expect(entityMapping.decode('&incomplete'), '&incomplete');
      });
      test('combinations', () {
        expect(entityMapping.decode('a&amp;b'), 'a&amp;b');
        expect(entityMapping.decode('&amp;x&amp;'), '&amp;x&amp;');
        expect(entityMapping.decode('&amp;&amp;'), '&amp;&amp;');
      });
    });
    group('encode', () {
      test('text', () {
        expect(entityMapping.encodeText('<'), '<');
        expect(entityMapping.encodeText('&'), '&');
        expect(entityMapping.encodeText('hello'), 'hello');
        expect(entityMapping.encodeText('<foo &amp;>'), '<foo &amp;>');
      });
      test('attribute', () {
        expect(
            entityMapping.encodeAttributeValue(
                '<>&\'"', XmlAttributeType.SINGLE_QUOTE),
            '<>&\'"');
        expect(
            entityMapping.encodeAttributeValue(
                '<>&\'"', XmlAttributeType.DOUBLE_QUOTE),
            '<>&\'"');
      });
    });
  });
  group('character parser', () {
    final parser = XmlCharacterDataParser('*', 1);
    test('parse without stopper', () {
      final result1 = parser.parse('');
      expect(result1.isFailure, isTrue);
      expect(result1.position, 0);

      final result2 = parser.parse('a');
      expect(result2.isSuccess, isTrue);
      expect(result2.position, 1);
      expect(result2.value, 'a');

      final result3 = parser.parse('ab');
      expect(result3.isSuccess, isTrue);
      expect(result3.position, 2);
      expect(result3.value, 'ab');
    });
    test('parse with stopper', () {
      final result1 = parser.parse('*');
      expect(result1.isFailure, isTrue);
      expect(result1.position, 0);

      final result2 = parser.parse('a*');
      expect(result2.isSuccess, isTrue);
      expect(result2.position, 1);
      expect(result2.value, 'a');

      final result3 = parser.parse('ab*');
      expect(result3.isSuccess, isTrue);
      expect(result3.position, 2);
      expect(result3.value, 'ab');
    });
    test('fast parse without stopper', () {
      final result1 = parser.fastParseOn('', 0);
      expect(result1, -1);

      final result2 = parser.fastParseOn('a', 0);
      expect(result2, 1);

      final result3 = parser.fastParseOn('ab', 0);
      expect(result3, 2);
    });
    test('fast parse with stopper', () {
      final result1 = parser.fastParseOn('*', 0);
      expect(result1, -1);

      final result2 = parser.fastParseOn('a*', 0);
      expect(result2, 1);

      final result3 = parser.fastParseOn('ab*', 0);
      expect(result3, 2);
    });
    test('copy and equality', () {
      expect(parser.isEqualTo(parser), isTrue);
      expect(parser.isEqualTo(parser.copy()), isTrue);
      expect(parser.isEqualTo(XmlCharacterDataParser('%', 1)), isFalse);
      expect(parser.isEqualTo(XmlCharacterDataParser('*', 2)), isFalse);
    });
  });
}
