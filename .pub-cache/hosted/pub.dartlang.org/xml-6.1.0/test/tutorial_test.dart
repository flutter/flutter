import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import 'utils/assertions.dart';

void main() {
  final bookshelfXml = '''<?xml version="1.0"?>
    <bookshelf>
      <book>
        <title lang="en">Growing a Language</title>
        <price>29.99</price>
      </book>
      <book>
        <title lang="en">Learning XML</title>
        <price>39.95</price>
      </book>
      <price>132.00</price>
    </bookshelf>''';
  final document = XmlDocument.parse(bookshelfXml);
  group('reading and writing', () {
    test('parse document', () {
      assertDocumentInvariants(document);
    });
    test('printing document', () {
      expect(document.toString(), bookshelfXml);
      expect(document.toXmlString(pretty: true, indent: '\t'),
          startsWith('<?xml version="1.0"?>'));
    });
  });
  group('traversing and querying', () {
    test('extract text', () {
      final textual = document.descendants
          .where((node) => node is XmlText && node.text.trim().isNotEmpty)
          .join('\n');
      expect(
          textual,
          'Growing a Language\n'
          '29.99\n'
          'Learning XML\n'
          '39.95\n'
          '132.00');
    });
    test('find all elements', () {
      final titles = document.findAllElements('title').map((node) => node.text);
      expect(titles, ['Growing a Language', 'Learning XML']);
    });
    test('nested find elements', () {
      final total = document
          .findAllElements('book')
          .map((node) => double.parse(node.findElements('price').single.text))
          .reduce((a, b) => a + b);
      expect(total, closeTo(69.94, 0.1));
    });
  });
  group('building', () {
    test('a document', () {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element('bookshelf', nest: () {
        builder.element('book', nest: () {
          builder.element('title', nest: () {
            builder.attribute('lang', 'en');
            builder.text('Growing a Language');
          });
          builder.element('price', nest: 29.99);
        });
        builder.element('book', nest: () {
          builder.element('title', nest: () {
            builder.attribute('lang', 'en');
            builder.text('Learning XML');
          });
          builder.element('price', nest: 39.95);
        });
        builder.element('price', nest: '132.00');
      });
      final builtDocument = builder.buildDocument();
      expect(document.toXmlString(pretty: true),
          builtDocument.toXmlString(pretty: true));
    });
    test('a fragment', () {
      void buildBook(
          XmlBuilder builder, String title, String language, num price) {
        builder.element('book', nest: () {
          builder.element('title', nest: () {
            builder.attribute('lang', language);
            builder.text(title);
          });
          builder.element('price', nest: price);
        });
      }

      final builder = XmlBuilder();
      buildBook(builder, 'The War of the Worlds', 'en', 12.50);
      buildBook(builder, 'Voyages extraordinaries', 'fr', 18.20);
      final builtDocument = document.copy();
      builtDocument.rootElement.children.add(builder.buildFragment());
      final titles =
          builtDocument.findAllElements('title').map((node) => node.text);
      expect(titles, [
        'Growing a Language',
        'Learning XML',
        'The War of the Worlds',
        'Voyages extraordinaries'
      ]);
    });
  });
  group('event-driven', () {
    test('iterable', () {
      final result = parseEvents(bookshelfXml)
          .whereType<XmlTextEvent>()
          .map((event) => event.text.trim())
          .where((text) => text.isNotEmpty)
          .join('\n');
      expect(
          result,
          'Growing a Language\n'
          '29.99\n'
          'Learning XML\n'
          '39.95\n'
          '132.00');
    });
    test('stream', () async {
      final stream = Stream.fromIterable([bookshelfXml]);
      final result = await stream
          .toXmlEvents()
          .normalizeEvents()
          .expand((events) => events
              .whereType<XmlTextEvent>()
              .map((event) => event.text.trim())
              .where((text) => text.isNotEmpty))
          .join('\n');
      expect(
          result,
          'Growing a Language\n'
          '29.99\n'
          'Learning XML\n'
          '39.95\n'
          '132.00');
    });
    test('stream select subtree', () async {
      final stream = Stream.fromIterable([bookshelfXml]);
      final result = await stream
          .toXmlEvents()
          .normalizeEvents()
          .selectSubtreeEvents((event) => event.name == 'title')
          .toXmlNodes()
          .expand((nodes) => nodes)
          .map((node) => node.innerText)
          .join('\n');
      expect(
          result,
          'Growing a Language\n'
          'Learning XML');
    });
  });
}
