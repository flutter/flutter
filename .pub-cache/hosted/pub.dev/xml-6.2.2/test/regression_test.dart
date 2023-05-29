import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'utils/assertions.dart';

class TrimTextVisitor with XmlVisitor {
  @override
  void visitDocument(XmlDocument node) => node.children.forEach(visit);

  @override
  void visitElement(XmlElement node) => node.children.forEach(visit);

  @override
  void visitText(XmlText node) => node.text = node.text.trim();
}

void main() {
  test('https://github.com/renggli/dart-xml/issues/38', () {
    const input = '<?xml?><InstantaneousDemand><DeviceMacId>'
        '0xd8d5b9000000b3e8</DeviceMacId><MeterMacId>0x00135003007c27b4'
        '</MeterMacId><TimeStamp>0x2244aeb3</TimeStamp><Demand>0x0006c1'
        '</Demand><Multiplier>0x00000001</Multiplier><Divisor>0x000003e8'
        '</Divisor><DigitsRight>0x03</DigitsRight><DigitsLeft>0x0f'
        '</DigitsLeft><SuppressLeadingZero>Y</SuppressLeadingZero>'
        '</InstantaneousDemand>';
    assertDocumentParseInvariants(input);
  });
  test('https://github.com/renggli/dart-xml/issues/95', () {
    const input = '''
        <link type="text/html" title="View on Feedbooks" rel="alternate" href="https://www.feedbooks.com/book/2936"/>
        <link type="application/epub+zip" rel="http://opds-spec.org/acquisition" href="https://www.feedbooks.com/book/2936.epub"/>
        <link type="image/jpeg" rel="http://opds-spec.org/image" href="https://covers.feedbooks.net/book/2936.jpg?size=large&amp;t=1549045871"/>
        <link type="image/jpeg" rel="http://opds-spec.org/image/thumbnail" href="https://covers.feedbooks.net/book/2936.jpg?size=large&amp;t=1549045871"/>
    ''';
    assertFragmentParseInvariants(input);
    final fragment = XmlDocumentFragment.parse(input);
    final href = fragment
        .findElements('link')
        .where((element) =>
            element.getAttribute('rel') ==
            'http://opds-spec.org/image/thumbnail')
        .map((element) => element.getAttribute('href'))
        .single;
    expect(href,
        'https://covers.feedbooks.net/book/2936.jpg?size=large&t=1549045871');
  });
  group('https://github.com/renggli/dart-xml/issues/99', () {
    const input = '''
        <root>
          <left> left</left>
          <both> both </both>
          <right>right </right>
        </root>''';
    test('transformation class', () {
      final document = XmlDocument.parse(input);
      TrimTextVisitor().visit(document);
      expect(document.rootElement.children[1].text, 'left');
      expect(document.rootElement.children[3].text, 'both');
      expect(document.rootElement.children[5].text, 'right');
    });
    test('transformation function', () {
      final document = XmlDocument.parse(input);
      for (final node in document.descendants.whereType<XmlText>()) {
        node.replace(XmlText(node.text.trim()));
      }
      expect(document.rootElement.children[1].text, 'left');
      expect(document.rootElement.children[3].text, 'both');
      expect(document.rootElement.children[5].text, 'right');
    });
  });
  test('https://github.com/renggli/dart-xml/issues/100', () {
    final document = XmlDocument.parse('''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns:os="http://a9.com/-/spec/opensearch/1.1/" xmlns="http://www.w3.org/2005/Atom">
          <os:totalResults>0</os:totalResults>
          <os:itemsPerPage>50</os:itemsPerPage>
          <os:startIndex>1</os:startIndex>
        </feed>''');
    expect(document.rootElement.getElement('os:totalResults')?.text, '0');
    expect(document.rootElement.getElement('os:itemsPerPage')?.text, '50');
    expect(document.rootElement.getElement('os:startIndex')?.text, '1');
  });
  test('https://github.com/renggli/dart-xml/issues/104', () {
    final document = XmlDocument.parse('''
        <?xml version="1.0"?>
        <!DOCTYPE TEI.2 PUBLIC "-//TEI P4//DTD Main DTD Driver File//EN" "http://www.tei-c.org/Guidelines/DTD/tei2.dtd"[
        <!ENTITY % TEI.XML "INCLUDE">
        <!ENTITY % PersProse PUBLIC "-//Perseus P4//DTD Perseus Prose//EN" "http://www.perseus.tufts.edu/DTD/1.0/PersProse.dtd">
        %PersProse;
        ]>
        <TEI.2></TEI.2>
    ''');
    expect(document.doctypeElement, isNotNull);
    expect(document.doctypeElement!.name, 'TEI.2');
    expect(document.doctypeElement!.externalId!.publicId,
        '-//TEI P4//DTD Main DTD Driver File//EN');
    expect(document.doctypeElement!.externalId!.systemId,
        'http://www.tei-c.org/Guidelines/DTD/tei2.dtd');
  });
  test('https://stackoverflow.com/questions/68100391', () {
    const number = 20;
    final document = XmlDocument.parse('''
        <Alarm>
          <Settings>
              <AlarmVolume type="int" min="0" max="100" unit="%">80</AlarmVolume>
          </Settings>
        </Alarm>
    ''');
    document.findAllElements('AlarmVolume').first.innerText = number.toString();
    expect(document.toXmlString(), '''
        <Alarm>
          <Settings>
              <AlarmVolume type="int" min="0" max="100" unit="%">20</AlarmVolume>
          </Settings>
        </Alarm>
    ''');
  });
  test('https://github.com/renggli/dart-xml/issues/144', () {
    assertDocumentParseInvariants('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE kanjidic2 [
	<!-- Version 1.6 - April 2008
	This is the DTD of the XML-format kanji file combining information from
	the KANJIDIC and KANJD212 files. It is intended to be largely self-
	documenting, with each field being accompanied by an explanatory
	comment.

	The file covers the following kanji:
	(a) the 6,355 kanji from JIS X 0208;
	(b) the 5,801 kanji from JIS X 0212;
	(c) the 3,693 kanji from JIS X 0213 as follows:
		(i) the 2,741 kanji which are also in JIS X 0212 have
		JIS X 0213 code-points (kuten) added to the existing entry;
		(ii) the 952 "new" kanji have new entries.

	At the end of the explanation for a number of fields there is a tag
	with the format [N]. This indicates the leading letter(s) of the
	equivalent field in the KANJIDIC and KANJD212 files.

	The KANJIDIC documentation should also be read for additional 
	information about the information in the file.
	-->
<!ELEMENT kanjidic2 (header,character*)>
<!ELEMENT header (file_version,database_version,date_of_creation)>
]><root/>''');
  });
  test('https://github.com/renggli/dart-xml/discussions/142', () {
    final entityMapping = XmlDefaultEntityMapping({
      ...XmlDefaultEntityMapping.html5().entities,
      'O': '\u201C',
      'C': '\u201D',
    });
    final document = XmlDocument.parse('''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html [
  <!ENTITY O "&#x201C;">
  <!ENTITY C "&#x201D;">
]>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Alice's Adventures in Wonderland by Lewis Carroll</title></head>
  <body>&O;Who are <i>you</i>?&C; said the Caterpillar.</body>
</html>''', entityMapping: entityMapping);
    expect(document.findAllElements('body').first.innerText,
        '“Who are you?” said the Caterpillar.');
  });
  group('https://github.com/renggli/dart-xml/discussions/154', () {
    final document = XmlDocument.parse('<a>'
        '<x>1</x>' // first match
        '<b><x>2</x></b>' // second match
        '<x>3<x></x></x>' // third match (does not descend into inner)
        '</a>');
    bool predicate(XmlNode node) => node is XmlElement && node.localName == 'x';

    test('descendants & ancestors', () {
      final nodes = document.descendants
          // Find all the nodes that satisfy the condition.
          .where((node) => predicate(node))
          // Exclude the nodes that have parents satisfying the condition.
          .where((node) => !node.ancestors.any(predicate));
      expect(nodes.map((node) => node.innerText), ['1', '2', '3']);
    });
    test('recursive', () {
      List<XmlNode> find(XmlNode node, bool Function(XmlNode) predicate) {
        if (predicate(node)) {
          // Return a matching node, ...
          return [node];
        } else {
          // ... otherwise recurse into the children.
          return [
            ...node.attributes.expand((child) => find(child, predicate)),
            ...node.children.expand((child) => find(child, predicate)),
          ];
        }
      }

      final nodes = find(document, predicate);
      expect(nodes.map((node) => node.innerText), ['1', '2', '3']);
    });
    test('iterative', () {
      List<XmlNode> find(XmlNode node, bool Function(XmlNode) predicate) {
        final todo = [node];
        final solutions = <XmlNode>[];
        while (todo.isNotEmpty) {
          final current = todo.removeAt(0);
          if (predicate(current)) {
            solutions.add(current);
          } else {
            todo.insertAll(0, current.nodes);
          }
        }
        return solutions;
      }

      final nodes = find(document, predicate);
      expect(nodes.map((node) => node.innerText), ['1', '2', '3']);
    });
  });
  test('https://github.com/renggli/dart-xml/issues/156', () {
    final bookshelfXml = '''<?xml version="1.0"?>
      <car color:name="blue">
      </car>''';
    final document = XmlDocument.parse(bookshelfXml);
    final carElement = document.rootElement;
    expect(carElement.getAttribute('color:name'), equals('blue'));
    // In 6.2.1, this creates another color:name
    // attribute instead of overwriting the existing one.
    carElement.setAttribute('color:name', 'red');
    expect(carElement.getAttribute('color:name'), equals('red'));
  });
}
