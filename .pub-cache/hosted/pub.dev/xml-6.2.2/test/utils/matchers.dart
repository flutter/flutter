import 'package:test/test.dart';
import 'package:xml/xml.dart';

Matcher isXmlParentException({
  dynamic message = isNotEmpty,
  dynamic node = anything,
  dynamic parent = anything,
}) =>
    TypeMatcher<XmlParentException>()
        .having((value) => value.message, 'message', message)
        .having((value) => value.node, 'node', node)
        .having((value) => value.parent, 'parent', parent)
        .having((value) => value.toString(), 'toString', isNotEmpty);

Matcher isXmlParserException({
  dynamic message = isNotEmpty,
  dynamic buffer = anything,
  dynamic position = anything,
  dynamic line = anything,
  dynamic column = anything,
}) =>
    TypeMatcher<XmlParserException>()
        .having((value) => value.message, 'message', message)
        .having((value) => value.buffer, 'buffer', buffer)
        .having((value) => value.source, 'source', buffer)
        .having((value) => value.position, 'position', position)
        .having((value) => value.offset, 'offset', position)
        .having((value) => value.line, 'line', line)
        .having((value) => value.column, 'column', column)
        .having((value) => value.toString(), 'toString', isNotEmpty);

Matcher isXmlNodeTypeException({
  dynamic message = isNotEmpty,
  dynamic node = anything,
  dynamic types = anything,
}) =>
    TypeMatcher<XmlNodeTypeException>()
        .having((value) => value.message, 'message', message)
        .having((value) => value.node, 'node', node)
        .having((value) => value.types, 'types', types)
        .having((value) => value.toString(), 'toString', isNotEmpty);

Matcher isXmlTagException({
  dynamic message = isNotEmpty,
  dynamic expectedName = anything,
  dynamic actualName = anything,
  dynamic buffer = anything,
  dynamic position = anything,
  dynamic line = anything,
  dynamic column = anything,
}) =>
    TypeMatcher<XmlTagException>()
        .having((value) => value.message, 'message', message)
        .having((value) => value.expectedName, 'expectedName', expectedName)
        .having((value) => value.actualName, 'actualName', actualName)
        .having((value) => value.buffer, 'buffer', buffer)
        .having((value) => value.position, 'position', position)
        .having((value) => value.line, 'line', line)
        .having((value) => value.column, 'column', column)
        .having((value) => value.toString(), 'toString', isNotEmpty);
