import 'package:test/test.dart';
import 'package:xml/xml.dart';

void verifyIterator(Iterable iterable) {
  final iterator = iterable.iterator;
  while (iterator.moveNext()) {
    expect(iterator.current, isNotNull);
  }
  expect(iterator.moveNext(), isFalse);
}

void main() {
  const bookXml = '<book>'
      '<title lang="en" price="12.00">XML</title>'
      '<description/>'
      '</book>';
  final book = XmlDocument.parse(bookXml);
  test('ancestors', () {
    expect(book.ancestors, []);
    expect(book.children[0].ancestors, [book]);
    expect(book.children[0].children[0].ancestors, [book.children[0], book]);
    expect(book.children[0].children[0].attributes[0].ancestors,
        [book.children[0].children[0], book.children[0], book]);
    expect(book.children[0].children[0].attributes[1].ancestors,
        [book.children[0].children[0], book.children[0], book]);
    expect(book.children[0].children[0].children[0].ancestors,
        [book.children[0].children[0], book.children[0], book]);
    expect(book.children[0].children[1].ancestors, [book.children[0], book]);
    verifyIterator(book.children[0].children[1].ancestors);
  });
  test('ancestorElements', () {
    expect(book.ancestorElements, []);
    expect(book.children[0].ancestorElements, []);
    expect(book.children[0].children[0].ancestorElements, [book.children[0]]);
    expect(book.children[0].children[0].attributes[0].ancestorElements,
        [book.children[0].children[0], book.children[0]]);
    expect(book.children[0].children[0].attributes[1].ancestorElements,
        [book.children[0].children[0], book.children[0]]);
    expect(book.children[0].children[0].children[0].ancestorElements,
        [book.children[0].children[0], book.children[0]]);
    expect(book.children[0].children[1].ancestorElements, [book.children[0]]);
    verifyIterator(book.children[0].children[1].ancestorElements);
  });
  test('preceding', () {
    expect(book.preceding, []);
    expect(book.children[0].preceding, [book]);
    expect(book.children[0].children[0].preceding, [book, book.children[0]]);
    expect(book.children[0].children[0].attributes[0].preceding,
        [book, book.children[0], book.children[0].children[0]]);
    expect(book.children[0].children[0].attributes[1].preceding, [
      book,
      book.children[0],
      book.children[0].children[0],
      book.children[0].children[0].attributes[0]
    ]);
    expect(book.children[0].children[0].children[0].preceding, [
      book,
      book.children[0],
      book.children[0].children[0],
      book.children[0].children[0].attributes[0],
      book.children[0].children[0].attributes[1]
    ]);
    expect(book.children[0].children[1].preceding, [
      book,
      book.children[0],
      book.children[0].children[0],
      book.children[0].children[0].attributes[0],
      book.children[0].children[0].attributes[1],
      book.children[0].children[0].children[0]
    ]);
    verifyIterator(book.children[0].children[1].preceding);
  });
  test('precedingElements', () {
    expect(book.precedingElements, []);
    expect(book.children[0].precedingElements, []);
    expect(book.children[0].children[0].precedingElements, [book.children[0]]);
    expect(book.children[0].children[0].attributes[0].precedingElements,
        [book.children[0], book.children[0].children[0]]);
    expect(book.children[0].children[0].attributes[1].precedingElements,
        [book.children[0], book.children[0].children[0]]);
    expect(book.children[0].children[0].children[0].precedingElements,
        [book.children[0], book.children[0].children[0]]);
    expect(book.children[0].children[1].precedingElements,
        [book.children[0], book.children[0].children[0]]);
    verifyIterator(book.children[0].children[1].precedingElements);
  });
  test('descendants', () {
    expect(book.descendants, [
      book.children[0],
      book.children[0].children[0],
      book.children[0].children[0].attributes[0],
      book.children[0].children[0].attributes[1],
      book.children[0].children[0].children[0],
      book.children[0].children[1]
    ]);
    expect(book.children[0].descendants, [
      book.children[0].children[0],
      book.children[0].children[0].attributes[0],
      book.children[0].children[0].attributes[1],
      book.children[0].children[0].children[0],
      book.children[0].children[1]
    ]);
    expect(book.children[0].children[0].descendants, [
      book.children[0].children[0].attributes[0],
      book.children[0].children[0].attributes[1],
      book.children[0].children[0].children[0]
    ]);
    expect(book.children[0].children[0].attributes[0].descendants, []);
    expect(book.children[0].children[0].attributes[1].descendants, []);
    expect(book.children[0].children[0].children[0].descendants, []);
    expect(book.children[0].children[1].descendants, []);
    verifyIterator(book.descendants);
  });
  test('descendantElements', () {
    expect(book.descendantElements, [
      book.children[0],
      book.children[0].children[0],
      book.children[0].children[1]
    ]);
    expect(book.children[0].descendantElements,
        [book.children[0].children[0], book.children[0].children[1]]);
    expect(book.children[0].children[0].descendantElements, []);
    expect(book.children[0].children[0].attributes[0].descendantElements, []);
    expect(book.children[0].children[0].attributes[1].descendantElements, []);
    expect(book.children[0].children[0].children[0].descendantElements, []);
    expect(book.children[0].children[1].descendantElements, []);
    verifyIterator(book.descendantElements);
  });
  test('following', () {
    expect(book.following, []);
    expect(book.children[0].following, []);
    expect(
        book.children[0].children[0].following, [book.children[0].children[1]]);
    expect(book.children[0].children[0].attributes[0].following, [
      book.children[0].children[0].attributes[1],
      book.children[0].children[0].children[0],
      book.children[0].children[1]
    ]);
    expect(book.children[0].children[0].attributes[1].following, [
      book.children[0].children[0].children[0],
      book.children[0].children[1]
    ]);
    expect(book.children[0].children[0].children[0].following,
        [book.children[0].children[1]]);
    expect(book.children[0].children[1].following, []);
    verifyIterator(book.following);
  });
  test('followingElements', () {
    expect(book.followingElements, []);
    expect(book.children[0].followingElements, []);
    expect(book.children[0].children[0].followingElements,
        [book.children[0].children[1]]);
    expect(book.children[0].children[0].attributes[0].followingElements,
        [book.children[0].children[1]]);
    expect(book.children[0].children[0].attributes[1].followingElements,
        [book.children[0].children[1]]);
    expect(book.children[0].children[0].children[0].followingElements,
        [book.children[0].children[1]]);
    expect(book.children[0].children[1].followingElements, []);
    verifyIterator(book.followingElements);
  });
  test('nodes', () {
    expect(book.nodes, [book.children[0]]);
    expect(book.children[0].nodes,
        [book.children[0].children[0], book.children[0].children[1]]);
    expect(book.children[0].children[0].nodes, [
      book.children[0].children[0].attributes[0],
      book.children[0].children[0].attributes[1],
      book.children[0].children[0].children[0]
    ]);
    expect(book.children[0].children[0].attributes[0].nodes, []);
    expect(book.children[0].children[0].attributes[1].nodes, []);
    expect(book.children[0].children[0].children[0].nodes, []);
    expect(book.children[0].children[1].nodes, []);
    verifyIterator(book.nodes);
  });
}
