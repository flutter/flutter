import 'package:petitparser/core.dart';
import 'package:petitparser/definition.dart';
import 'package:petitparser/indent.dart';
import 'package:petitparser/parser.dart';
import 'package:test/test.dart';

import 'utils/matchers.dart';

class IndentList extends GrammarDefinition {
  final indent = Indent();

  @override
  Parser start() => <Parser>[
        ref0(newlines).optional(),
        ref0(things),
        ref0(newlines).optional(),
        endOfInput(),
      ].toSequenceParser().pick(1);

  Parser things() => <Parser>[
        indent.same,
        ref0(object) | ref0(line),
      ].toSequenceParser().pick(1).star();

  Parser object() => <Parser>[
        ref0(key),
        ref0(block) | ref0(inline),
      ].toSequenceParser().map((values) => {values[0]: values[1]});

  Parser key() => <Parser>[
        pattern('^ \t\r\n:').plus().flatten(),
        indent.parser.star(),
        char(':'),
        indent.parser.star(),
      ].toSequenceParser().pick(0);

  Parser block() => <Parser>[
        ref0(newlines),
        indent.increase,
        ref0(things),
        indent.decrease,
      ].toSequenceParser().pick(2);

  Parser inline() => ref0(line).map((value) => [value]);

  Parser line() => <Parser>[
        ref0(newline).neg().plus().flatten(),
        ref0(newlines).optional(),
      ].toSequenceParser().pick(0);

  Parser newline() => Token.newlineParser();

  Parser newlines() => [
        indent.parser.star(),
        ref0(newline),
      ].toSequenceParser().plus();
}

void main() {
  group('definition', () {
    final definition = IndentList();
    final parser = definition.build();

    tearDown(() {
      expect(definition.indent.stack, isEmpty);
      expect(definition.indent.current, '');
    });
    test('empty', () {
      expect(parser, isParseSuccess('', []));

      expect(parser, isParseSuccess('\n', []));
      expect(parser, isParseSuccess('\n\r', []));
      expect(parser, isParseSuccess('\r', []));

      expect(parser, isParseSuccess('\n\n', []));
      expect(parser, isParseSuccess('\n\r\n\r', []));
      expect(parser, isParseSuccess('\r\r', []));
    });
    test('newline before', () {
      expect(parser, isParseSuccess('\na', ['a']));
      expect(parser, isParseSuccess('\n\ra', ['a']));
      expect(parser, isParseSuccess('\ra', ['a']));

      expect(parser, isParseSuccess('\n\na', ['a']));
      expect(parser, isParseSuccess('\n\r\n\ra', ['a']));
      expect(parser, isParseSuccess('\r\ra', ['a']));
    });
    test('newline after', () {
      expect(parser, isParseSuccess('a\n', ['a']));
      expect(parser, isParseSuccess('a\n\r', ['a']));
      expect(parser, isParseSuccess('a\r', ['a']));

      expect(parser, isParseSuccess('a\n\n', ['a']));
      expect(parser, isParseSuccess('a\n\r\n\r', ['a']));
      expect(parser, isParseSuccess('a\r\r', ['a']));
    });
    test('single indent', () {
      expect(
          parser,
          isParseSuccess('a:\n b', [
            {
              'a': ['b']
            }
          ]));
      expect(
          parser,
          isParseSuccess('a:\n\tb', [
            {
              'a': ['b']
            }
          ]));
      expect(
          parser,
          isParseSuccess('a:\n \tb', [
            {
              'a': ['b']
            }
          ]));
      expect(
          parser,
          isParseSuccess('a:\n\t b', [
            {
              'a': ['b']
            }
          ]));
    });
    test('same indent', () {
      expect(
          parser,
          isParseSuccess('a:\n b\n c', [
            {
              'a': ['b', 'c']
            }
          ]));
      expect(
          parser,
          isParseSuccess('a:\n\tb\n\tc', [
            {
              'a': ['b', 'c']
            }
          ]));
      expect(
          parser,
          isParseSuccess('a:\n \tb\n \tc', [
            {
              'a': ['b', 'c']
            }
          ]));
      expect(
          parser,
          isParseSuccess('a:\n\t b\n\t c', [
            {
              'a': ['b', 'c']
            }
          ]));
    });
    test('different indent', () {
      expect(parser, isParseFailure('a:\n b\n\tc', position: 6));
      expect(parser, isParseFailure('a:\n\tb\n c', position: 6));
    });
    test('missing indent', () {
      expect(parser, isParseSuccess('a:\nb', ['a:', 'b']));
    });
    test('unexpected indent', () {
      expect(parser, isParseFailure('a\n b', position: 2));
    });
    test('same level', () {
      expect(parser, isParseSuccess('a\nb\nc', ['a', 'b', 'c']));
    });
    test('inlined values', () {
      expect(
          parser,
          isParseSuccess('a:1\nb: 2\nc :3', [
            {
              'a': ['1']
            },
            {
              'b': ['2']
            },
            {
              'c': ['3']
            }
          ]));
    });
    test('increasing', () {
      expect(
          parser,
          isParseSuccess('a:\n  b:\n    c', [
            {
              'a': [
                {
                  'b': ['c']
                }
              ]
            }
          ]));
    });
    test('decreasing', () {
      expect(
          parser,
          isParseSuccess('a:\n\tb\nc', [
            {
              'a': ['b']
            },
            'c'
          ]));
    });
  });
}
