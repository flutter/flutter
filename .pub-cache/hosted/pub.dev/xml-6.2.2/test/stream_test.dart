// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:math' show min, Random;

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import 'utils/assertions.dart';
import 'utils/examples.dart';
import 'utils/matchers.dart';

@isTestGroup
void chunkedTests<T>(
  String title,
  T Function() factory,
  Stream<T> Function(T input, int Function() splitter) chunker,
  FutureOr<void> Function(Stream<T> stream) callback,
) =>
    group(title, () {
      for (var i = 1; i <= 512; i *= 2) {
        test(
          'chunks equally sized $i',
          () => callback(chunker(factory(), () => i)),
        );
      }
      final random = Random(title.hashCode);
      for (var i = 1; i <= 512; i *= 2) {
        test(
          'chunks randomly sized $i',
          () => callback(chunker(factory(), () => random.nextInt(1 + i))),
        );
      }
    });

Stream<String> stringChunker(String input, int Function() splitter) async* {
  while (input.isNotEmpty) {
    final size = min(splitter(), input.length);
    yield input.substring(0, size);
    input = input.substring(size);
  }
}

Stream<List<T>> listChunker<T>(List<T> input, int Function() splitter) async* {
  while (input.isNotEmpty) {
    final size = min(splitter(), input.length);
    yield input.sublist(0, size);
    input = input.sublist(size);
  }
}

void main() {
  group('events', () {
    for (final entry in allXml.entries) {
      group(entry.key, () {
        late XmlDocument document;
        late String source;
        late List<XmlEvent> events;
        setUp(() {
          document = XmlDocument.parse(entry.value);
          source = document.toXmlString();
          events = parseEvents(source).toList(growable: false);
        });
        chunkedTests<String>(
          'string -> events',
          () => source,
          stringChunker,
          (stream) {
            final actual = stream.toXmlEvents().normalizeEvents().flatten();
            expect(actual, emitsInOrder([...events, emitsDone]));
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> nodes',
          () => events,
          listChunker,
          (stream) {
            final actual = stream.toXmlNodes().flatten();
            final expected =
                document.children.map((node) => predicate<XmlNode>((actual) {
                      compareNode(actual, node);
                      return true;
                    }, 'matches $node'));
            expect(actual, emitsInOrder([...expected, emitsDone]));
          },
        );
        chunkedTests<List<XmlNode>>(
          'nodes -> events',
          () => document.children,
          listChunker,
          (stream) {
            final actual = stream.toXmlEvents().flatten();
            expect(actual, emitsInOrder([...events, emitsDone]));
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> string',
          () => events,
          listChunker,
          (stream) {
            final actual = stream.toXmlString().join();
            expect(actual, completion(source));
          },
        );
        chunkedTests<String>(
          'string -> events -> string',
          () => source,
          stringChunker,
          (stream) {
            final actual =
                stream.toXmlEvents().normalizeEvents().toXmlString().join();
            expect(actual, completion(source));
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> string -> events',
          () => events,
          listChunker,
          (stream) {
            final actual = stream
                .toXmlString()
                .toXmlEvents()
                .normalizeEvents()
                .flatten()
                .toList();
            expect(actual, completion(events));
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> nodes -> events',
          () => events,
          listChunker,
          (stream) {
            final actual = stream.toXmlNodes().toXmlEvents().flatten().toList();
            expect(actual, completion(events));
          },
        );
        chunkedTests<List<XmlNode>>(
          'nodes -> events -> nodes',
          () => document.children,
          listChunker,
          (stream) async {
            final actual =
                await stream.toXmlEvents().toXmlNodes().flatten().toList();
            expect(
                actual,
                pairwiseCompare<XmlNode, XmlNode>(document.children,
                    (actual, expected) {
                  compareNode(actual, expected);
                  return true;
                }, 'not matching'));
          },
        );
        if (entry.value == shiporderXsd) {
          chunkedTests<List<XmlEvent>>(
            'events -> subtree -> nodes',
            () => events,
            listChunker,
            (stream) async {
              final actual = await stream
                  .selectSubtreeEvents((event) => event.name == 'xsd:element')
                  .toXmlNodes()
                  .flatten()
                  .toList();
              final expected = document
                  .findAllElements('element', namespace: '*')
                  .where((element) => !element.ancestors
                      .whereType<XmlElement>()
                      .any((parent) => parent.name.local == 'element'))
                  .toList();
              expect(
                  actual,
                  pairwiseCompare<XmlNode, XmlNode>(expected,
                      (actual, expected) {
                    compareNode(actual, expected);
                    return true;
                  }, 'not matching'));
              actual
                  .expand((node) => [node, ...node.descendants])
                  .whereType<XmlHasName>()
                  .forEach((node) => expect(node.name.namespaceUri, isNull));
            },
          );
          chunkedTests<List<XmlEvent>>(
            'events -> parents -> subtree -> nodes',
            () => events,
            listChunker,
            (stream) async {
              final actual = await stream
                  .withParentEvents()
                  .selectSubtreeEvents((event) => event.name == 'xsd:element')
                  .toXmlNodes()
                  .flatten()
                  .toList();
              final expected = document
                  .findAllElements('element', namespace: '*')
                  .where((element) => !element.ancestors
                      .whereType<XmlElement>()
                      .any((parent) => parent.name.local == 'element'))
                  .toList();
              expect(
                  actual,
                  pairwiseCompare<XmlNode, XmlNode>(expected,
                      (actual, expected) {
                    compareNode(actual, expected);
                    return true;
                  }, 'not matching'));
              actual
                  .expand((node) => [node, ...node.descendants])
                  .whereType<XmlHasName>()
                  .where((node) => node.name.prefix == 'xsd')
                  .forEach((node) => expect(node.name.namespaceUri,
                      'http://www.w3.org/2001/XMLSchema'));
            },
          );
        }
        chunkedTests<List<XmlEvent>>(
          'event -> forEachEvent',
          () => events,
          listChunker,
          (stream) async {
            final cdata = <XmlCDATAEvent>[];
            final comment = <XmlCommentEvent>[];
            final declaration = <XmlDeclarationEvent>[];
            final doctype = <XmlDoctypeEvent>[];
            final endElement = <XmlEndElementEvent>[];
            final processing = <XmlProcessingEvent>[];
            final startElement = <XmlStartElementEvent>[];
            final text = <XmlTextEvent>[];
            await stream.flatten().forEachEvent(
                  onCDATA: cdata.add,
                  onComment: comment.add,
                  onDeclaration: declaration.add,
                  onDoctype: doctype.add,
                  onEndElement: endElement.add,
                  onProcessing: processing.add,
                  onStartElement: startElement.add,
                  onText: text.add,
                );
            expect(cdata, events.whereType<XmlCDATAEvent>());
            expect(comment, events.whereType<XmlCommentEvent>());
            expect(declaration, events.whereType<XmlDeclarationEvent>());
            expect(doctype, events.whereType<XmlDoctypeEvent>());
            expect(endElement, events.whereType<XmlEndElementEvent>());
            expect(processing, events.whereType<XmlProcessingEvent>());
            expect(startElement, events.whereType<XmlStartElementEvent>());
            expect(text, events.whereType<XmlTextEvent>());
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> tapEachEvent',
          () => events,
          listChunker,
          (stream) async {
            final cdata = <XmlCDATAEvent>[];
            final comment = <XmlCommentEvent>[];
            final declaration = <XmlDeclarationEvent>[];
            final doctype = <XmlDoctypeEvent>[];
            final endElement = <XmlEndElementEvent>[];
            final processing = <XmlProcessingEvent>[];
            final startElement = <XmlStartElementEvent>[];
            final text = <XmlTextEvent>[];
            await stream
                .flatten()
                .tapEachEvent(
                  onCDATA: cdata.add,
                  onComment: comment.add,
                  onDeclaration: declaration.add,
                  onDoctype: doctype.add,
                  onEndElement: endElement.add,
                  onProcessing: processing.add,
                  onStartElement: startElement.add,
                  onText: text.add,
                )
                .drain();
            expect(cdata, events.whereType<XmlCDATAEvent>());
            expect(comment, events.whereType<XmlCommentEvent>());
            expect(declaration, events.whereType<XmlDeclarationEvent>());
            expect(doctype, events.whereType<XmlDoctypeEvent>());
            expect(endElement, events.whereType<XmlEndElementEvent>());
            expect(processing, events.whereType<XmlProcessingEvent>());
            expect(startElement, events.whereType<XmlStartElementEvent>());
            expect(text, events.whereType<XmlTextEvent>());
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> forEachEvent',
          () => events,
          listChunker,
          (stream) async {
            final cdata = <XmlCDATAEvent>[];
            final comment = <XmlCommentEvent>[];
            final declaration = <XmlDeclarationEvent>[];
            final doctype = <XmlDoctypeEvent>[];
            final endElement = <XmlEndElementEvent>[];
            final processing = <XmlProcessingEvent>[];
            final startElement = <XmlStartElementEvent>[];
            final text = <XmlTextEvent>[];
            await stream.forEachEvent(
              onCDATA: cdata.add,
              onComment: comment.add,
              onDeclaration: declaration.add,
              onDoctype: doctype.add,
              onEndElement: endElement.add,
              onProcessing: processing.add,
              onStartElement: startElement.add,
              onText: text.add,
            );
            expect(cdata, events.whereType<XmlCDATAEvent>());
            expect(comment, events.whereType<XmlCommentEvent>());
            expect(declaration, events.whereType<XmlDeclarationEvent>());
            expect(doctype, events.whereType<XmlDoctypeEvent>());
            expect(endElement, events.whereType<XmlEndElementEvent>());
            expect(processing, events.whereType<XmlProcessingEvent>());
            expect(startElement, events.whereType<XmlStartElementEvent>());
            expect(text, events.whereType<XmlTextEvent>());
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> tapEachEvent',
          () => events,
          listChunker,
          (stream) async {
            final cdata = <XmlCDATAEvent>[];
            final comment = <XmlCommentEvent>[];
            final declaration = <XmlDeclarationEvent>[];
            final doctype = <XmlDoctypeEvent>[];
            final endElement = <XmlEndElementEvent>[];
            final processing = <XmlProcessingEvent>[];
            final startElement = <XmlStartElementEvent>[];
            final text = <XmlTextEvent>[];
            await stream
                .tapEachEvent(
                  onCDATA: cdata.add,
                  onComment: comment.add,
                  onDeclaration: declaration.add,
                  onDoctype: doctype.add,
                  onEndElement: endElement.add,
                  onProcessing: processing.add,
                  onStartElement: startElement.add,
                  onText: text.add,
                )
                .drain();
            expect(cdata, events.whereType<XmlCDATAEvent>());
            expect(comment, events.whereType<XmlCommentEvent>());
            expect(declaration, events.whereType<XmlDeclarationEvent>());
            expect(doctype, events.whereType<XmlDoctypeEvent>());
            expect(endElement, events.whereType<XmlEndElementEvent>());
            expect(processing, events.whereType<XmlProcessingEvent>());
            expect(startElement, events.whereType<XmlStartElementEvent>());
            expect(text, events.whereType<XmlTextEvent>());
          },
        );
        chunkedTests<List<XmlEvent>>(
          'events -> withParent -> map',
          () => events,
          listChunker,
          (stream) async {
            final stacks = await stream
                .withParentEvents()
                .normalizeEvents()
                .flatten()
                .map((event) {
              final stack = <XmlEvent>[];
              for (XmlEvent? current = event;
                  current != null;
                  current = current.parent) {
                stack.insert(0, current);
              }
              return stack;
            }).toList();
            expect(stacks.map((events) => events.last), events);
          },
        );
      });
    }
  });
  group('errors', () {
    chunkedTests<String>(
      'missing tag closing',
      () => '<hello',
      stringChunker,
      (stream) {
        expect(
            stream.toXmlEvents(withLocation: true),
            emitsThrough(emitsError(isXmlParserException(
              message: '">" expected',
              position: 6,
            ))));
      },
    );
    chunkedTests<String>(
      'missing attribute closing',
      () => '<foo bar="abc',
      stringChunker,
      (stream) {
        expect(
            stream.toXmlEvents(withLocation: true),
            emitsThrough(emitsError(isXmlParserException(
              message: '">" expected',
              position: 5,
            ))));
      },
    );
    chunkedTests<String>(
      'missing comment closing',
      () => '<!-- comment',
      stringChunker,
      (stream) {
        expect(
            stream.toXmlEvents(withLocation: true),
            emitsThrough(emitsError(isXmlParserException(
              message: '"-->" expected',
              position: 4,
            ))));
      },
    );
    group('tags not validated', () {
      chunkedTests<String>(
        'unexpected end tag',
        () => '</foo>',
        stringChunker,
        (stream) {
          expect(
              stream.toXmlEvents(withLocation: true).flatten(),
              emitsInOrder([
                XmlEndElementEvent('foo'),
                emitsDone,
              ]));
        },
      );
      chunkedTests<String>(
        'missing end tag',
        () => '<foo>',
        stringChunker,
        (stream) {
          expect(
              stream.toXmlEvents(withLocation: true).flatten(),
              emitsInOrder([
                XmlStartElementEvent('foo', [], false),
                emitsDone,
              ]));
        },
      );
      chunkedTests<String>(
        'not matching end tag',
        () => '<foo></bar></foo>',
        stringChunker,
        (stream) {
          expect(
              stream.toXmlEvents(withLocation: true).flatten(),
              emitsInOrder([
                XmlStartElementEvent('foo', [], false),
                XmlEndElementEvent('bar'),
                XmlEndElementEvent('foo'),
                emitsDone,
              ]));
        },
      );
    });
    group('tags validated', () {
      chunkedTests<String>(
        'unexpected end tag',
        () => '</foo>',
        stringChunker,
        (stream) {
          expect(
              stream
                  .toXmlEvents(validateNesting: true, withLocation: true)
                  .flatten(),
              emitsThrough(emitsError(
                  isXmlTagException(actualName: 'foo', position: 0))));
        },
      );
      chunkedTests<String>(
        'missing end tag',
        () => '<foo>',
        stringChunker,
        (stream) {
          expect(
              stream
                  .toXmlEvents(validateNesting: true, withLocation: true)
                  .flatten(),
              emitsThrough(emitsError(
                  isXmlTagException(expectedName: 'foo', position: 5))));
        },
      );
      chunkedTests<String>(
        'not matching end tag',
        () => '<foo></bar></foo>',
        stringChunker,
        (stream) {
          expect(
              stream
                  .toXmlEvents(validateNesting: true, withLocation: true)
                  .flatten(),
              emitsThrough(emitsError(isXmlTagException(
                  expectedName: 'foo', actualName: 'bar', position: 5))));
        },
      );
    });
  });
  group('normalizeEvents', () {
    test('empty', () async {
      final input = <XmlEvent>[XmlTextEvent('')];
      final output = await Stream.fromIterable([input])
          .normalizeEvents()
          .flatten()
          .toList();
      const expected = <XmlEvent>[];
      expect(output, expected);
    });
    test('whitespace', () async {
      final input = <XmlEvent>[XmlTextEvent(' \n\t')];
      final actual = await Stream.fromIterable([input])
          .normalizeEvents()
          .flatten()
          .toList();
      final expected = <XmlEvent>[XmlTextEvent(' \n\t')];
      expect(actual, expected);
    });
    test('combine two', () async {
      final input = <XmlEvent>[XmlTextEvent('a'), XmlTextEvent('b')];
      final actual = await Stream.fromIterable([input])
          .normalizeEvents()
          .flatten()
          .toList();
      final expected = <XmlEvent>[XmlTextEvent('ab')];
      expect(actual, expected);
    });
    test('combine many', () async {
      final input = <XmlEvent>[
        XmlTextEvent('a'),
        XmlTextEvent('b'),
        XmlTextEvent('c'),
        XmlTextEvent('d'),
        XmlTextEvent('e'),
      ];
      final actual = await Stream.fromIterable([input])
          .normalizeEvents()
          .flatten()
          .toList();
      final expected = <XmlEvent>[XmlTextEvent('abcde')];
      expect(actual, expected);
    });
    test('chunked up', () async {
      final input = <XmlEvent>[
        XmlTextEvent('a'),
        XmlTextEvent('b'),
        XmlTextEvent('c'),
        XmlStartElementEvent('br', [], true),
        XmlTextEvent('d'),
        XmlTextEvent('e'),
      ];
      final actual = await Stream.fromIterable([input])
          .normalizeEvents()
          .flatten()
          .toList();
      final expected = <XmlEvent>[
        XmlTextEvent('abc'),
        XmlStartElementEvent('br', [], true),
        XmlTextEvent('de'),
      ];
      expect(actual, expected);
    });
  });
  group('withParentEvents', () {
    test('not parented', () async {
      final input = <XmlEvent>[
        XmlCDATAEvent('cdata'),
        XmlCommentEvent('comment'),
        XmlDeclarationEvent([]),
        XmlDoctypeEvent('doctype'),
        XmlProcessingEvent('target', 'text'),
        XmlStartElementEvent('element', [], true),
        XmlTextEvent('text'),
      ];
      final output = await Stream.fromIterable([input])
          .withParentEvents()
          .flatten()
          .toList();
      expect(output, input, reason: 'equality is unaffected');
      for (var i = 0; i < input.length; i++) {
        expect(input[i], same(output[i]), reason: 'root element is identical');
      }
    });
    test('basic parented', () async {
      final input = <XmlEvent>[
        XmlStartElementEvent('element', [], false),
        XmlCDATAEvent('cdata'),
        XmlCommentEvent('comment'),
        XmlDeclarationEvent([]),
        XmlDoctypeEvent('doctype'),
        XmlProcessingEvent('target', 'text'),
        XmlStartElementEvent('element', [], true),
        XmlTextEvent('text'),
        XmlEndElementEvent('element'),
      ];
      final output = await Stream.fromIterable([input])
          .withParentEvents()
          .flatten()
          .toList();
      expect(output, input, reason: 'equality is unaffected');
      for (var i = 1; i < input.length; i++) {
        expect(output[i].parent, same(output[0]));
        expect(output[i].parent, same(input[0]));
      }
    });
    test('deeply parented', () async {
      final input = <XmlEvent>[
        XmlStartElementEvent('first', [], false),
        XmlStartElementEvent('second', [], false),
        XmlStartElementEvent('third', [], false),
        XmlEndElementEvent('third'),
        XmlEndElementEvent('second'),
        XmlEndElementEvent('first'),
      ];
      final output = await Stream.fromIterable([input])
          .withParentEvents()
          .flatten()
          .toList();
      expect(output, input, reason: 'equality is unaffected');
      expect(output[0], same(input[0]), reason: 'root element is identical');
      expect(output[0].parent, isNull);
      expect(output[1].parent, same(output[0]));
      expect(output[2].parent, same(output[1]));
      expect(output[3].parent, same(output[2]));
      expect(output[4].parent, same(output[1]));
      expect(output[5].parent, same(output[0]));
    });
    test('closing tag mismatch', () {
      final input = <List<XmlEvent>>[
        [XmlStartElementEvent('open', [], false)],
        [XmlEndElementEvent('close')],
        [XmlTextEvent('after')],
      ];
      final stream = Stream.fromIterable(input).withParentEvents().flatten();
      expect(
          stream,
          emitsInOrder([
            input[0][0],
            emitsError(isXmlTagException(
                message: 'Expected </open>, but found </close>')),
          ]));
    });
    test('closing tag missing', () {
      final input = <List<XmlEvent>>[
        [XmlStartElementEvent('open', [], false)],
      ];
      final stream = Stream.fromIterable(input).withParentEvents().flatten();
      expect(
          stream,
          emitsInOrder([
            input[0][0],
            emitsError(isXmlTagException(message: 'Missing </open>')),
          ]));
    });
    test('closing tag unexpected', () {
      final input = <List<XmlEvent>>[
        [XmlEndElementEvent('close')],
        [XmlTextEvent('after')],
      ];
      final stream = Stream.fromIterable(input).withParentEvents().flatten();
      expect(
        stream,
        emitsError(isXmlTagException(message: 'Unexpected </close>')),
      );
    });
    test('after normalization', () {
      final input = [
        XmlStartElementEvent('outer', [], false),
        XmlTextEvent('first'),
        XmlTextEvent(' '),
        XmlTextEvent('second'),
        XmlEndElementEvent('outer'),
      ];
      final actual = const XmlWithParentEvents()
          .convert(const XmlNormalizeEvents().convert(input));
      expect(actual, hasLength(3));
      expect(actual[1].parent, same(actual[0]));
      expect(actual[2].parent, same(actual[0]));
    });
    test('before normalization', () {
      final input = [
        XmlStartElementEvent('outer', [], false),
        XmlTextEvent('first'),
        XmlTextEvent(' '),
        XmlTextEvent('second'),
        XmlEndElementEvent('outer'),
      ];
      final actual = const XmlNormalizeEvents()
          .convert(const XmlWithParentEvents().convert(input));
      expect(actual, hasLength(3));
      expect(actual[1].parent, same(actual[0]));
      expect(actual[2].parent, same(actual[0]));
    });
    test('default namespace', () async {
      const url = 'http://www.w3.org/1999/xhtml';
      const input = '<html xmlns="$url"><body lang="en"/></html>';
      final events = await Stream.fromIterable([input])
          .toXmlEvents()
          .withParentEvents()
          .flatten()
          .toList();
      for (final event in events) {
        if (event is XmlStartElementEvent) {
          expect(event.namespaceUri, url);
          event.attributes
              .where((attribute) => attribute.localName != 'xmlns')
              .forEach((attribute) => expect(attribute.namespaceUri, url));
        } else if (event is XmlEndElementEvent) {
          expect(event.namespaceUri, url);
        }
      }
    });
    test('prefix namespace', () async {
      const url = 'http://www.w3.org/1999/xhtml';
      const input = '<xhtml:html xmlns:xhtml="$url">'
          '<xhtml:body xhtml:lang="en"/>'
          '</xhtml:html>';
      final events = await Stream.fromIterable([input])
          .toXmlEvents()
          .withParentEvents()
          .flatten()
          .toList();
      for (final event in events) {
        if (event is XmlStartElementEvent) {
          expect(event.namespaceUri, url);
          event.attributes
              .where((attribute) => attribute.namespacePrefix != 'xmlns')
              .forEach((attribute) => expect(attribute.namespaceUri, url));
        } else if (event is XmlEndElementEvent) {
          expect(event.namespaceUri, url);
        }
      }
    });
  });
}
