// ignore_for_file: deprecated_member_use_from_same_package

import 'package:test/test.dart';
import 'package:xml/xml_events.dart';

import 'utils/examples.dart';
import 'utils/matchers.dart';

void assertComplete(Iterator<XmlEvent> iterator) {
  for (var i = 0; i < 2; i++) {
    expect(iterator.moveNext(), isFalse);
  }
}

void main() {
  group('events', () {
    test('empty', () {
      final iterator = parseEvents('').iterator;
      assertComplete(iterator);
    });
    test('cdata', () {
      final iterator = parseEvents('<![CDATA[<nasty>]]>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlCDATAEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.CDATA);
      expect(event.text, '<nasty>');
      final other = XmlCDATAEvent(event.text);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('comment', () {
      final iterator = parseEvents('<!--for amusement only-->').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlCommentEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.COMMENT);
      expect(event.text, 'for amusement only');
      final other = XmlCommentEvent(event.text);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('declaration', () {
      final iterator = parseEvents('<?xml?>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlDeclarationEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.DECLARATION);
      expect(event.attributes, isEmpty);
      final other = XmlDeclarationEvent(event.attributes);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('declaration (attributes)', () {
      final iterator =
          parseEvents('<?xml version="1.0" author=\'lfr\'?>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlDeclarationEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.DECLARATION);
      expect(event.attributes, hasLength(2));
      expect(event.attributes[0].name, 'version');
      expect(event.attributes[0].value, '1.0');
      expect(event.attributes[0].attributeType, XmlAttributeType.DOUBLE_QUOTE);
      expect(event.attributes[1].name, 'author');
      expect(event.attributes[1].value, 'lfr');
      expect(event.attributes[1].attributeType, XmlAttributeType.SINGLE_QUOTE);
      final other = XmlDeclarationEvent(event.attributes);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('doctype', () {
      final iterator = parseEvents('<!DOCTYPE note\n'
              'PUBLIC "public.dtd" "system.dtd"\n'
              '[<!ENTITY copy "(c)">]\n'
              '>')
          .iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlDoctypeEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.DOCUMENT_TYPE);
      expect(event.name, 'note');
      expect(event.externalId, isNotNull);
      expect(event.externalId!.publicId, 'public.dtd');
      expect(event.externalId!.systemId, 'system.dtd');
      expect(event.internalSubset, '<!ENTITY copy "(c)">');
      final other =
          XmlDoctypeEvent(event.name, event.externalId, event.internalSubset);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('end element', () {
      final iterator = parseEvents('</bar>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlEndElementEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.ELEMENT);
      expect(event.name, 'bar');
      final other = XmlEndElementEvent(event.name);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('processing', () {
      final iterator = parseEvents('<?pi test?>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlProcessingEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.PROCESSING);
      expect(event.target, 'pi');
      expect(event.text, 'test');
      final other = XmlProcessingEvent(event.target, event.text);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('start element', () {
      final iterator = parseEvents('<foo>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlStartElementEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.ELEMENT);
      expect(event.name, 'foo');
      expect(event.attributes, isEmpty);
      expect(event.isSelfClosing, isFalse);
      final other = XmlStartElementEvent(
          event.name, event.attributes, event.isSelfClosing);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('start element (attributes, self-closing)', () {
      final iterator = parseEvents('<foo a="1" b=\'2\'/>').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlStartElementEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.ELEMENT);
      expect(event.name, 'foo');
      expect(event.attributes, hasLength(2));
      expect(event.attributes[0].name, 'a');
      expect(event.attributes[0].value, '1');
      expect(event.attributes[0].attributeType, XmlAttributeType.DOUBLE_QUOTE);
      expect(event.attributes[1].name, 'b');
      expect(event.attributes[1].value, '2');
      expect(event.attributes[1].attributeType, XmlAttributeType.SINGLE_QUOTE);
      expect(event.isSelfClosing, isTrue);
      final other = XmlStartElementEvent(
          event.name,
          event.attributes
              .map((attr) =>
                  XmlEventAttribute(attr.name, attr.value, attr.attributeType))
              .toList(),
          event.isSelfClosing);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
    test('text', () {
      final iterator = parseEvents('Hello World!').iterator;
      expect(iterator.moveNext(), isTrue);
      final event = iterator.current as XmlTextEvent;
      assertComplete(iterator);
      expect(event.nodeType, XmlNodeType.TEXT);
      expect(event.text, 'Hello World!');
      final other = XmlTextEvent(event.text);
      expect(event, other);
      expect(event.hashCode, other.hashCode);
    });
  });
  group('errors', () {
    group('parser error', () {
      test('missing tag closing', () {
        final iterator = parseEvents('<hello').iterator;
        expect(
            iterator.moveNext,
            throwsA(isXmlParserException(
              message: '">" expected',
              buffer: '<hello',
              position: 6,
            )));
        expect(iterator.moveNext(), isTrue);
        final event = iterator.current as XmlTextEvent;
        expect(event.text, 'hello');
        assertComplete(iterator);
      });
      test('missing attribute closing', () {
        final iterator = parseEvents('<foo bar="abc').iterator;
        expect(
            iterator.moveNext,
            throwsA(isXmlParserException(
              message: '">" expected',
              buffer: '<foo bar="abc',
              position: 5,
            )));
        expect(iterator.moveNext(), isTrue);
        final event = iterator.current as XmlTextEvent;
        expect(event.text, 'foo bar="abc');
        assertComplete(iterator);
      });
      test('missing comment closing', () {
        final iterator = parseEvents('<!-- comment').iterator;
        expect(
            iterator.moveNext,
            throwsA(isXmlParserException(
              message: '"-->" expected',
              buffer: '<!-- comment',
              position: 4,
            )));
        expect(iterator.moveNext(), isTrue);
        final event = iterator.current as XmlTextEvent;
        expect(event.text, '!-- comment');
        assertComplete(iterator);
      });
    });
    group('not validated', () {
      test('unexpected end tag', () {
        final events = parseEvents('</foo>');
        expect(events, [XmlEndElementEvent('foo')]);
      });
      test('missing end tag', () {
        final events = parseEvents('<foo>');
        expect(events, [XmlStartElementEvent('foo', [], false)]);
      });
      test('not matching end tag', () {
        final events = parseEvents('<foo></bar></foo>');
        expect(events, [
          XmlStartElementEvent('foo', [], false),
          XmlEndElementEvent('bar'),
          XmlEndElementEvent('foo')
        ]);
      });
    });
    group('validated', () {
      test('unexpected end tag', () {
        final iterator = parseEvents('</foo>', validateNesting: true).iterator;
        expect(() => iterator.moveNext(),
            throwsA(isXmlTagException(actualName: 'foo', position: 0)));
        expect(iterator.current, XmlEndElementEvent('foo'));
        assertComplete(iterator);
      });
      test('missing end tag', () {
        final iterator = parseEvents('<foo>', validateNesting: true).iterator;
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, XmlStartElementEvent('foo', [], false));
        expect(() => iterator.moveNext(),
            throwsA(isXmlTagException(expectedName: 'foo', position: 5)));
        assertComplete(iterator);
      });
      test('not matching end tag', () {
        final iterator =
            parseEvents('<foo></bar></foo>', validateNesting: true).iterator;
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, XmlStartElementEvent('foo', [], false));
        expect(
            () => iterator.moveNext(),
            throwsA(isXmlTagException(
                expectedName: 'foo', actualName: 'bar', position: 5)));
        expect(iterator.current, XmlEndElementEvent('bar'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, XmlEndElementEvent('foo'));
        assertComplete(iterator);
      });
    });
  });
  group('annotations', () {
    test('default', () {
      for (var event in parseEvents(shiporderXsd)) {
        expect(event.buffer, isNull);
        expect(event.start, isNull);
        expect(event.stop, isNull);
        expect(event.parent, isNull);
        expect(event.parentEvent, isNull);
      }
    });
    test('buffer', () {
      for (var event in parseEvents(shiporderXsd, withBuffer: true)) {
        expect(event.buffer, shiporderXsd);
      }
    });
    test('location', () {
      for (var event in parseEvents(shiporderXsd, withLocation: true)) {
        expect(event.start, isNotNull);
        expect(event.stop, isNotNull);
        expect(event.start! <= event.stop!, isTrue);
        final outtake = shiporderXsd.substring(event.start!, event.stop!);
        expect(parseEvents(outtake), [event]);
      }
    });
    test('parent', () {
      final stack = <XmlStartElementEvent>[];
      for (var event in parseEvents(shiporderXsd, withParent: true)) {
        expect(event.parent, stack.isNotEmpty ? stack.last : isNull);
        expect(event.parentEvent, stack.isNotEmpty ? stack.last : isNull);
        if (event is XmlStartElementEvent && !event.isSelfClosing) {
          stack.add(event);
        } else if (event is XmlEndElementEvent) {
          stack.removeLast();
        }
      }
      expect(stack, isEmpty);
    });
  });
  group('examples', () {
    test('extract non-empty text', () {
      final texts = parseEvents(bookstoreXml)
          .whereType<XmlTextEvent>()
          .map((event) => event.text.trim())
          .where((text) => text.isNotEmpty);
      expect(texts, ['Harry Potter', '29.99', 'Learning XML', '39.95']);
    });
    test('extract specific attribute', () {
      final maxExclusive = parseEvents(shiporderXsd)
          .whereType<XmlStartElementEvent>()
          .singleWhere((event) => event.name == 'xsd:maxExclusive')
          .attributes
          .singleWhere((attribute) => attribute.name == 'value')
          .value;
      expect(maxExclusive, '100');
    });
    test('extract all genres', () {
// Some libraries provide a sliding window iterator
// https://github.com/renggli/dart-more/blob/main/lib/src/iterable/window.dart
// which would make this code trivial to write and read:
      final genres = <String>{};
      parseEvents(booksXml).reduce((previous, current) {
        if (previous is XmlStartElementEvent &&
            previous.name == 'genre' &&
            current is XmlTextEvent) {
          genres.add(current.text);
        }
        return current;
      });
      expect(
          genres,
          containsAll([
            'Computer',
            'Fantasy',
            'Romance',
            'Horror',
            'Science Fiction',
          ]));
    });
  });
}
