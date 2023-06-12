// AUTO-GENERATED CODE: DO NOT EDIT

import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import '../utils/assertions.dart';
import '../utils/matchers.dart';

void main() {
  group('seq2', () {
    final parser = seq2(char('a'), char('b'));
    final sequence = Sequence2('a', 'b');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('ab', sequence));
      expect(parser, isParseSuccess('ab*', sequence, position: 2));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
  });
  group('map2', () {
    final parser = seq2(char('a'), char('b')).map2((a, b) => '$a$b');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('ab', 'ab'));
      expect(parser, isParseSuccess('ab*', 'ab', position: 2));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
  });
  group('Sequence2', () {
    final sequence = Sequence2('a', 'b');
    final other = Sequence2('b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.last, 'b');
    });
    test('map', () {
      expect(sequence.map((a, b) {
        expect(a, 'a');
        expect(b, 'b');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b)'));
      expect(other.toString(), endsWith('(b, a)'));
    });
  });
  group('seq3', () {
    final parser = seq3(char('a'), char('b'), char('c'));
    final sequence = Sequence3('a', 'b', 'c');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abc', sequence));
      expect(parser, isParseSuccess('abc*', sequence, position: 3));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
  });
  group('map3', () {
    final parser =
        seq3(char('a'), char('b'), char('c')).map3((a, b, c) => '$a$b$c');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abc', 'abc'));
      expect(parser, isParseSuccess('abc*', 'abc', position: 3));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
  });
  group('Sequence3', () {
    final sequence = Sequence3('a', 'b', 'c');
    final other = Sequence3('c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.last, 'c');
    });
    test('map', () {
      expect(sequence.map((a, b, c) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c)'));
      expect(other.toString(), endsWith('(c, b, a)'));
    });
  });
  group('seq4', () {
    final parser = seq4(char('a'), char('b'), char('c'), char('d'));
    final sequence = Sequence4('a', 'b', 'c', 'd');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcd', sequence));
      expect(parser, isParseSuccess('abcd*', sequence, position: 4));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
  });
  group('map4', () {
    final parser = seq4(char('a'), char('b'), char('c'), char('d'))
        .map4((a, b, c, d) => '$a$b$c$d');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcd', 'abcd'));
      expect(parser, isParseSuccess('abcd*', 'abcd', position: 4));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
  });
  group('Sequence4', () {
    final sequence = Sequence4('a', 'b', 'c', 'd');
    final other = Sequence4('d', 'c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.fourth, 'd');
      expect(sequence.last, 'd');
    });
    test('map', () {
      expect(sequence.map((a, b, c, d) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        expect(d, 'd');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c, d)'));
      expect(other.toString(), endsWith('(d, c, b, a)'));
    });
  });
  group('seq5', () {
    final parser = seq5(char('a'), char('b'), char('c'), char('d'), char('e'));
    final sequence = Sequence5('a', 'b', 'c', 'd', 'e');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcde', sequence));
      expect(parser, isParseSuccess('abcde*', sequence, position: 5));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
  });
  group('map5', () {
    final parser = seq5(char('a'), char('b'), char('c'), char('d'), char('e'))
        .map5((a, b, c, d, e) => '$a$b$c$d$e');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcde', 'abcde'));
      expect(parser, isParseSuccess('abcde*', 'abcde', position: 5));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
  });
  group('Sequence5', () {
    final sequence = Sequence5('a', 'b', 'c', 'd', 'e');
    final other = Sequence5('e', 'd', 'c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.fourth, 'd');
      expect(sequence.fifth, 'e');
      expect(sequence.last, 'e');
    });
    test('map', () {
      expect(sequence.map((a, b, c, d, e) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        expect(d, 'd');
        expect(e, 'e');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c, d, e)'));
      expect(other.toString(), endsWith('(e, d, c, b, a)'));
    });
  });
  group('seq6', () {
    final parser =
        seq6(char('a'), char('b'), char('c'), char('d'), char('e'), char('f'));
    final sequence = Sequence6('a', 'b', 'c', 'd', 'e', 'f');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdef', sequence));
      expect(parser, isParseSuccess('abcdef*', sequence, position: 6));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
  });
  group('map6', () {
    final parser =
        seq6(char('a'), char('b'), char('c'), char('d'), char('e'), char('f'))
            .map6((a, b, c, d, e, f) => '$a$b$c$d$e$f');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdef', 'abcdef'));
      expect(parser, isParseSuccess('abcdef*', 'abcdef', position: 6));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
  });
  group('Sequence6', () {
    final sequence = Sequence6('a', 'b', 'c', 'd', 'e', 'f');
    final other = Sequence6('f', 'e', 'd', 'c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.fourth, 'd');
      expect(sequence.fifth, 'e');
      expect(sequence.sixth, 'f');
      expect(sequence.last, 'f');
    });
    test('map', () {
      expect(sequence.map((a, b, c, d, e, f) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        expect(d, 'd');
        expect(e, 'e');
        expect(f, 'f');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c, d, e, f)'));
      expect(other.toString(), endsWith('(f, e, d, c, b, a)'));
    });
  });
  group('seq7', () {
    final parser = seq7(char('a'), char('b'), char('c'), char('d'), char('e'),
        char('f'), char('g'));
    final sequence = Sequence7('a', 'b', 'c', 'd', 'e', 'f', 'g');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdefg', sequence));
      expect(parser, isParseSuccess('abcdefg*', sequence, position: 7));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
    test('failure at 6', () {
      expect(parser,
          isParseFailure('abcdef', message: '"g" expected', position: 6));
      expect(parser,
          isParseFailure('abcdef*', message: '"g" expected', position: 6));
    });
  });
  group('map7', () {
    final parser = seq7(char('a'), char('b'), char('c'), char('d'), char('e'),
            char('f'), char('g'))
        .map7((a, b, c, d, e, f, g) => '$a$b$c$d$e$f$g');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdefg', 'abcdefg'));
      expect(parser, isParseSuccess('abcdefg*', 'abcdefg', position: 7));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
    test('failure at 6', () {
      expect(parser,
          isParseFailure('abcdef', message: '"g" expected', position: 6));
      expect(parser,
          isParseFailure('abcdef*', message: '"g" expected', position: 6));
    });
  });
  group('Sequence7', () {
    final sequence = Sequence7('a', 'b', 'c', 'd', 'e', 'f', 'g');
    final other = Sequence7('g', 'f', 'e', 'd', 'c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.fourth, 'd');
      expect(sequence.fifth, 'e');
      expect(sequence.sixth, 'f');
      expect(sequence.seventh, 'g');
      expect(sequence.last, 'g');
    });
    test('map', () {
      expect(sequence.map((a, b, c, d, e, f, g) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        expect(d, 'd');
        expect(e, 'e');
        expect(f, 'f');
        expect(g, 'g');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c, d, e, f, g)'));
      expect(other.toString(), endsWith('(g, f, e, d, c, b, a)'));
    });
  });
  group('seq8', () {
    final parser = seq8(char('a'), char('b'), char('c'), char('d'), char('e'),
        char('f'), char('g'), char('h'));
    final sequence = Sequence8('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdefgh', sequence));
      expect(parser, isParseSuccess('abcdefgh*', sequence, position: 8));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
    test('failure at 6', () {
      expect(parser,
          isParseFailure('abcdef', message: '"g" expected', position: 6));
      expect(parser,
          isParseFailure('abcdef*', message: '"g" expected', position: 6));
    });
    test('failure at 7', () {
      expect(parser,
          isParseFailure('abcdefg', message: '"h" expected', position: 7));
      expect(parser,
          isParseFailure('abcdefg*', message: '"h" expected', position: 7));
    });
  });
  group('map8', () {
    final parser = seq8(char('a'), char('b'), char('c'), char('d'), char('e'),
            char('f'), char('g'), char('h'))
        .map8((a, b, c, d, e, f, g, h) => '$a$b$c$d$e$f$g$h');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdefgh', 'abcdefgh'));
      expect(parser, isParseSuccess('abcdefgh*', 'abcdefgh', position: 8));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
    test('failure at 6', () {
      expect(parser,
          isParseFailure('abcdef', message: '"g" expected', position: 6));
      expect(parser,
          isParseFailure('abcdef*', message: '"g" expected', position: 6));
    });
    test('failure at 7', () {
      expect(parser,
          isParseFailure('abcdefg', message: '"h" expected', position: 7));
      expect(parser,
          isParseFailure('abcdefg*', message: '"h" expected', position: 7));
    });
  });
  group('Sequence8', () {
    final sequence = Sequence8('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h');
    final other = Sequence8('h', 'g', 'f', 'e', 'd', 'c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.fourth, 'd');
      expect(sequence.fifth, 'e');
      expect(sequence.sixth, 'f');
      expect(sequence.seventh, 'g');
      expect(sequence.eighth, 'h');
      expect(sequence.last, 'h');
    });
    test('map', () {
      expect(sequence.map((a, b, c, d, e, f, g, h) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        expect(d, 'd');
        expect(e, 'e');
        expect(f, 'f');
        expect(g, 'g');
        expect(h, 'h');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c, d, e, f, g, h)'));
      expect(other.toString(), endsWith('(h, g, f, e, d, c, b, a)'));
    });
  });
  group('seq9', () {
    final parser = seq9(char('a'), char('b'), char('c'), char('d'), char('e'),
        char('f'), char('g'), char('h'), char('i'));
    final sequence = Sequence9('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdefghi', sequence));
      expect(parser, isParseSuccess('abcdefghi*', sequence, position: 9));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
    test('failure at 6', () {
      expect(parser,
          isParseFailure('abcdef', message: '"g" expected', position: 6));
      expect(parser,
          isParseFailure('abcdef*', message: '"g" expected', position: 6));
    });
    test('failure at 7', () {
      expect(parser,
          isParseFailure('abcdefg', message: '"h" expected', position: 7));
      expect(parser,
          isParseFailure('abcdefg*', message: '"h" expected', position: 7));
    });
    test('failure at 8', () {
      expect(parser,
          isParseFailure('abcdefgh', message: '"i" expected', position: 8));
      expect(parser,
          isParseFailure('abcdefgh*', message: '"i" expected', position: 8));
    });
  });
  group('map9', () {
    final parser = seq9(char('a'), char('b'), char('c'), char('d'), char('e'),
            char('f'), char('g'), char('h'), char('i'))
        .map9((a, b, c, d, e, f, g, h, i) => '$a$b$c$d$e$f$g$h$i');
    expectParserInvariants(parser);
    test('success', () {
      expect(parser, isParseSuccess('abcdefghi', 'abcdefghi'));
      expect(parser, isParseSuccess('abcdefghi*', 'abcdefghi', position: 9));
    });
    test('failure at 0', () {
      expect(parser, isParseFailure('', message: '"a" expected', position: 0));
      expect(parser, isParseFailure('*', message: '"a" expected', position: 0));
    });
    test('failure at 1', () {
      expect(parser, isParseFailure('a', message: '"b" expected', position: 1));
      expect(
          parser, isParseFailure('a*', message: '"b" expected', position: 1));
    });
    test('failure at 2', () {
      expect(
          parser, isParseFailure('ab', message: '"c" expected', position: 2));
      expect(
          parser, isParseFailure('ab*', message: '"c" expected', position: 2));
    });
    test('failure at 3', () {
      expect(
          parser, isParseFailure('abc', message: '"d" expected', position: 3));
      expect(
          parser, isParseFailure('abc*', message: '"d" expected', position: 3));
    });
    test('failure at 4', () {
      expect(
          parser, isParseFailure('abcd', message: '"e" expected', position: 4));
      expect(parser,
          isParseFailure('abcd*', message: '"e" expected', position: 4));
    });
    test('failure at 5', () {
      expect(parser,
          isParseFailure('abcde', message: '"f" expected', position: 5));
      expect(parser,
          isParseFailure('abcde*', message: '"f" expected', position: 5));
    });
    test('failure at 6', () {
      expect(parser,
          isParseFailure('abcdef', message: '"g" expected', position: 6));
      expect(parser,
          isParseFailure('abcdef*', message: '"g" expected', position: 6));
    });
    test('failure at 7', () {
      expect(parser,
          isParseFailure('abcdefg', message: '"h" expected', position: 7));
      expect(parser,
          isParseFailure('abcdefg*', message: '"h" expected', position: 7));
    });
    test('failure at 8', () {
      expect(parser,
          isParseFailure('abcdefgh', message: '"i" expected', position: 8));
      expect(parser,
          isParseFailure('abcdefgh*', message: '"i" expected', position: 8));
    });
  });
  group('Sequence9', () {
    final sequence = Sequence9('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i');
    final other = Sequence9('i', 'h', 'g', 'f', 'e', 'd', 'c', 'b', 'a');
    test('accessors', () {
      expect(sequence.first, 'a');
      expect(sequence.second, 'b');
      expect(sequence.third, 'c');
      expect(sequence.fourth, 'd');
      expect(sequence.fifth, 'e');
      expect(sequence.sixth, 'f');
      expect(sequence.seventh, 'g');
      expect(sequence.eighth, 'h');
      expect(sequence.ninth, 'i');
      expect(sequence.last, 'i');
    });
    test('map', () {
      expect(sequence.map((a, b, c, d, e, f, g, h, i) {
        expect(a, 'a');
        expect(b, 'b');
        expect(c, 'c');
        expect(d, 'd');
        expect(e, 'e');
        expect(f, 'f');
        expect(g, 'g');
        expect(h, 'h');
        expect(i, 'i');
        return 42;
      }), 42);
    });
    test('equals', () {
      expect(sequence, sequence);
      expect(sequence, isNot(other));
      expect(other, isNot(sequence));
      expect(other, other);
    });
    test('hashCode', () {
      expect(sequence.hashCode, sequence.hashCode);
      expect(sequence.hashCode, isNot(other.hashCode));
      expect(other.hashCode, isNot(sequence.hashCode));
      expect(other.hashCode, other.hashCode);
    });
    test('toString', () {
      expect(sequence.toString(), endsWith('(a, b, c, d, e, f, g, h, i)'));
      expect(other.toString(), endsWith('(i, h, g, f, e, d, c, b, a)'));
    });
  });
}
