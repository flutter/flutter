import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'utils/matchers.dart';

void main() {
  group('XmlParentException', () {
    test('checkNoParent', () {
      final document = XmlDocument([XmlComment('Comment')]);
      XmlParentException.checkNoParent(document);
      expect(
          () => XmlParentException.checkNoParent(document.firstChild!),
          throwsA(isXmlParentException(
            message: 'Node already has a parent, copy or remove it first',
            node: document.firstChild,
            parent: document,
          )));
    });
    test('checkMatchingParent', () {
      final document = XmlDocument([XmlComment('Comment')]);
      XmlParentException.checkMatchingParent(document.firstChild!, document);
      expect(
          () => XmlParentException.checkMatchingParent(
              document, document.firstChild!),
          throwsA(isXmlParentException(
            message: 'Node already has a non-matching parent',
            node: document,
            parent: document.firstChild,
          )));
    });
  });
  group('XmlParserException', () {
    test('with properties', () {
      final exception = XmlParserException('Expected foo',
          buffer: 'hello\nworld', position: 6);
      expect(
          exception,
          isXmlParserException(
            message: 'Expected foo',
            buffer: 'hello\nworld',
            position: 6,
            line: 2,
            column: 1,
          ));
    });
    test('without anything', () {
      final exception = XmlParserException('Expected foo');
      expect(
          exception,
          isXmlParserException(
            message: 'Expected foo',
            buffer: isNull,
            position: isNull,
            line: 0,
            column: 0,
          ));
    });
  });
  group('XmlNodeTypeException', () {
    test('checkValidType', () {
      final commentNode = XmlComment('Comment');
      final commentNodeTypes = [XmlNodeType.COMMENT];
      final otherNodeTypes = [XmlNodeType.ELEMENT, XmlNodeType.TEXT];
      XmlNodeTypeException.checkValidType(commentNode, commentNodeTypes);
      expect(
          () =>
              XmlNodeTypeException.checkValidType(commentNode, otherNodeTypes),
          throwsA(isXmlNodeTypeException(
            message: 'Got XmlNodeType.COMMENT, but expected one of '
                'XmlNodeType.ELEMENT, XmlNodeType.TEXT',
            node: commentNode,
            types: otherNodeTypes,
          )));
    });
  });
  group('XmlTagException', () {
    test('mismatchClosingTag', () {
      final exception = XmlTagException.mismatchClosingTag('foo', 'bar',
          buffer: '<foo>\n</bar>', position: 6);
      expect(
          exception,
          isXmlTagException(
            message: 'Expected </foo>, but found </bar>',
            expectedName: 'foo',
            actualName: 'bar',
            buffer: '<foo>\n</bar>',
            position: 6,
            line: 2,
            column: 1,
          ));
    });
    test('unexpectedClosingTag', () {
      final exception = XmlTagException.unexpectedClosingTag('bar',
          buffer: '</bar>', position: 0);
      expect(
          exception,
          isXmlTagException(
            message: 'Unexpected </bar>',
            expectedName: isNull,
            actualName: 'bar',
            buffer: '</bar>',
            position: 0,
            line: 1,
            column: 1,
          ));
    });
    test('missingClosingTag', () {
      final exception = XmlTagException.missingClosingTag('foo',
          buffer: '<foo>', position: 5);
      expect(
          exception,
          isXmlTagException(
            message: 'Missing </foo>',
            expectedName: 'foo',
            actualName: isNull,
            buffer: '<foo>',
            position: 5,
            line: 1,
            column: 6,
          ));
    });
    test('checkClosingTag', () {
      XmlTagException.checkClosingTag('foo', 'foo');
      expect(
          () => XmlTagException.checkClosingTag('foo', 'bar',
              buffer: '<foo>\n</bar>', position: 6),
          throwsA(isXmlTagException(
            message: 'Expected </foo>, but found </bar>',
            expectedName: 'foo',
            actualName: 'bar',
            buffer: '<foo>\n</bar>',
            position: 6,
            line: 2,
            column: 1,
          )));
    });
  });
}
