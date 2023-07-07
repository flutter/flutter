// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:math';

import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart' hide anyOf;

import 'utils/matchers.dart';

typedef Evaluator = num Function(num value);

Parser element() => char('(').seq(ref0(content)).seq(char(')'));

Parser content() => (ref0(element) | any()).star();
final nestedParser = resolve(ref0(content)).flatten().end();

class ParensGrammar extends GrammarDefinition {
  @override
  Parser start() => char('(') & ref0(start) & char(')') | epsilon();
}

class NestedGrammar1 {
  Parser start() => ref0(term).end();
  Parser term() => ref0(nestedTerm) | ref0(singleCharacter);
  Parser nestedTerm() =>
      (char('(')).map((value) => "'$value' (nestedTerm)") &
      ref0(term) &
      char(')').map((value) => "'$value' (nestedTerm)");
  Parser singleCharacter() =>
      char('(').map((value) => "'$value' (singleCharacter)") |
      char(')').map((value) => "'$value' (singleCharacter)") |
      char('0').map((value) => "'$value' (singleCharacter)");
}

class NestedGrammar2 {
  Parser start() => ref0(term).end();
  Parser term() => (ref0(nestedTerm) | ref0(singleCharacter)).plus();
  Parser nestedTerm() =>
      (char('(')).map((value) => "'$value' (nestedTerm)") &
      ref0(term) &
      char(')').map((value) => "'$value' (nestedTerm)");
  Parser singleCharacter() =>
      char('(').map((value) => "'$value' (singleCharacter)") |
      char(')').map((value) => "'$value' (singleCharacter)") |
      char('0').map((value) => "'$value' (singleCharacter)");
}

class NestedGrammar3 {
  Parser start() => ref0(term).end();
  Parser term() => (ref0(nestedTerm) | ref0(singleCharacter)).plus();
  Parser nestedTerm() =>
      (char('(')).map((value) => "'$value' (nestedTerm)") &
      ref0(term) &
      char(')').map((value) => "'$value' (nestedTerm)");
  Parser singleCharacter() =>
      char('(').map((value) => "'$value' (singleCharacter)") |
      char('0').map((value) => "'$value' (singleCharacter)");
}

void main() {
  test('flatten().trim()', () {
    final parser = word().plus().flatten().trim();
    expect(parser, isParseSuccess('ab1', 'ab1'));
    expect(parser, isParseSuccess(' ab1 ', 'ab1'));
    expect(parser, isParseSuccess('  ab1  ', 'ab1'));
  });
  test('trim().flatten()', () {
    final parser = word().plus().trim().flatten();
    expect(parser, isParseSuccess('ab1', 'ab1'));
    expect(parser, isParseSuccess(' ab1 ', ' ab1 '));
    expect(parser, isParseSuccess('  ab1  ', '  ab1  '));
  });
  group('separatedBy()', () {
    void testWith(String name, Parser<List<T>> Function<T>(Parser<T>) builder) {
      test(name, () {
        final string = letter();
        final stringList = builder(string);
        expect(stringList, const TypeMatcher<Parser<List<String>>>());
        expect(stringList, isParseSuccess('a,b,c', ['a', 'b', 'c']));

        final integer = digit().map(int.parse);
        final integerList = builder(integer);
        expect(integerList, const TypeMatcher<Parser<List<int>>>());
        expect(integerList, isParseSuccess('1,2,3', [1, 2, 3]));

        final mixed = string | integer;
        final mixedList = builder(mixed);
        expect(mixedList, const TypeMatcher<Parser<List>>());
        expect(mixedList, isParseSuccess('1,a,2', [1, 'a', 2]));
      });
    }

    Parser<List<T>> typeParam<T>(Parser<T> parser) =>
        parser.separatedBy<T>(char(','), includeSeparators: false);
    Parser<List<T>> castList<T>(Parser<T> parser) =>
        parser.separatedBy(char(','), includeSeparators: false).castList<T>();
    Parser<List<T>> smartCompiler<T>(Parser<T> parser) =>
        parser.separatedBy(char(','), includeSeparators: false);

    testWith('with list created using desired type', typeParam);
    testWith('with generic list cast to desired type', castList);
    testWith('with compiler inferring desired type', smartCompiler);
  });
  test('parse padded and limited number', () {
    final parser = digit().repeat(2).flatten().callCC((continuation, context) {
      final result = continuation(context);
      if (result.isSuccess && int.parse(result.value) > 31) {
        return context.failure('00-31 expected');
      } else {
        return result;
      }
    });
    expect(parser, isParseSuccess('00', '00'));
    expect(parser, isParseSuccess('24', '24'));
    expect(parser, isParseSuccess('31', '31'));
    expect(parser, isParseFailure('32', message: '00-31 expected'));
    expect(parser, isParseFailure('3', position: 1, message: 'digit expected'));
  });
  group('date format parser', () {
    final day = 'dd'.toParser().map((token) => digit()
        .repeat(2)
        .flatten()
        .map((value) => MapEntry(#day, int.parse(value))));
    final month = 'mm'.toParser().map((token) => digit()
        .repeat(2)
        .flatten()
        .map((value) => MapEntry(#month, int.parse(value))));
    final year = 'yyyy'.toParser().map((token) => digit()
        .repeat(4)
        .flatten()
        .map((value) => MapEntry(#year, int.parse(value))));

    final spacing = whitespace().map((token) =>
        whitespace().star().map((value) => const MapEntry(#unused, 0)));
    final verbatim = any().map(
        (token) => token.toParser().map((value) => const MapEntry(#unused, 0)));

    final entries = [day, month, year, spacing, verbatim].toChoiceParser();
    final format = entries
        .star()
        .end()
        .map((parsers) => parsers.toSequenceParser().map((entries) {
              final arguments = Map.fromEntries(entries);
              return DateTime(
                arguments[#year] ?? DateTime.now().year,
                arguments[#month] ?? DateTime.january,
                arguments[#day] ?? 1,
              );
            }));

    test('iso', () {
      final date = format.parse('yyyy-mm-dd').value;
      expect(date, isParseSuccess('1980-06-11', DateTime(1980, 6, 11)));
      expect(date, isParseSuccess('1982-08-24', DateTime(1982, 8, 24)));
      expect(date,
          isParseFailure('1984.10.31', position: 4, message: '"-" expected'));
    });
    test('europe', () {
      final date = format.parse('dd.mm.yyyy').value;
      expect(date, isParseSuccess('11.06.1980', DateTime(1980, 6, 11)));
      expect(date, isParseSuccess('24.08.1982', DateTime(1982, 8, 24)));
      expect(
          date, isParseFailure('1984', position: 2, message: '"." expected'));
    });
    test('us', () {
      final date = format.parse('mm/dd/yyyy').value;
      expect(date, isParseSuccess('06/11/1980', DateTime(1980, 6, 11)));
      expect(date, isParseSuccess('08/24/1982', DateTime(1982, 8, 24)));
      expect(date, isParseFailure('Hello', message: 'digit expected'));
    });
  });
  test('stackoverflow.com/questions/64670722', () {
    final delimited = any().callCC((continuation, context) {
      final delimiter = continuation(context).value.toParser();
      final parser = [
        delimiter,
        delimiter.neg().star().flatten(),
        delimiter,
      ].toSequenceParser().pick(1);
      return parser.parseOn(context);
    });
    expect(delimited, isParseSuccess('"hello"', 'hello'));
    expect(delimited, isParseSuccess('/hello/', 'hello'));
    expect(delimited, isParseSuccess(',hello,', 'hello'));
    expect(delimited, isParseSuccess('xhellox', 'hello'));
    expect(
        delimited, isParseFailure('abc', position: 3, message: '"a" expected'));
  });
  test('function evaluator', () {
    final builder = ExpressionBuilder<Evaluator>();
    builder.group()
      ..primitive(digit()
          .plus()
          .seq(char('.').seq(digit().plus()).optional())
          .flatten()
          .trim()
          .map((a) {
        final number = num.parse(a);
        return (num value) => number;
      }))
      ..primitive(char('x').trim().map((_) => (value) => value))
      ..wrapper(char('(').trim(), char(')').trim(), (_, a, __) => a);
    // negation is a prefix operator
    builder
        .group()
        .prefix(char('-').trim(), (_, a) => (num value) => -a(value));
    // power is right-associative
    builder.group().right(
        char('^').trim(), (a, _, b) => (num value) => pow(a(value), b(value)));
    // multiplication and addition are left-associative
    builder.group()
      ..left(char('*').trim(), (a, _, b) => (num value) => a(value) * b(value))
      ..left(char('/').trim(), (a, _, b) => (num value) => a(value) / b(value));
    builder.group()
      ..left(char('+').trim(), (a, _, b) => (num value) => a(value) + b(value))
      ..left(char('-').trim(), (a, _, b) => (num value) => a(value) - b(value));
    final parser = builder.build().end();

    final expression = parser.parse('5 * x ^ 3 - 2').value;
    expect(expression(-2), -42);
    expect(expression(-1), -7);
    expect(expression(0), -2);
    expect(expression(1), 3);
    expect(expression(2), 38);
  });
  test('stackoverflow.com/q/67617000/82303', () {
    expect(nestedParser, isParseSuccess('()', '()'));
    expect(nestedParser, isParseSuccess('(a)', '(a)'));
    expect(nestedParser, isParseSuccess('(a()b)', '(a()b)'));
    expect(nestedParser, isParseSuccess('(a(b)c)', '(a(b)c)'));
    expect(nestedParser, isParseSuccess('(a()b(cd))', '(a()b(cd))'));
  });
  group('github.com/petitparser/dart-petitparser/issues/109', () {
    // The digit defines how many characters are read by the data parser.
    Parser buildMetadataParser() => digit().flatten().map(int.parse);
    Parser buildDataParser(int count) => any().repeat(count).flatten();

    const input = '4database';
    test('split', () {
      final metadataParser = buildMetadataParser();
      final metadataResult = metadataParser.parse(input);
      final dataParser = buildDataParser(metadataResult.value);
      final dataResult = dataParser.parseOn(metadataResult);
      expect(dataResult.value, 'data');
    });
    test('continuation', () {
      final parser = buildMetadataParser().callCC((continuation, context) {
        final metadataResult = continuation(context);
        final dataParser = buildDataParser(metadataResult.value);
        return dataParser.parseOn(metadataResult);
      });
      expect(parser.parse(input).value, 'data');
    });
  });
  group('stackoverflow.com/questions/68105573', () {
    const firstInput = '(use = "official").empty()';
    const secondInput = '((5 + 5) * 5) + 5';

    test('greedy', () {
      final parser =
          char('(') & any().starGreedy(char(')')).flatten() & char(')');
      expect(parser.parse(firstInput).value,
          ['(', 'use = "official").empty(', ')']);
      expect(parser.parse(secondInput).value, ['(', '(5 + 5) * 5', ')']);
    });
    test('lazy', () {
      final parser =
          char('(') & any().starLazy(char(')')).flatten() & char(')');
      expect(parser.parse(firstInput).value, ['(', 'use = "official"', ')']);
      expect(parser.parse(secondInput).value, ['(', '(5 + 5', ')']);
    });
    test('recursive', () {
      final inner = undefined();
      final parser =
          char('(') & inner.starLazy(char(')')).flatten() & char(')');
      inner.set(parser | any());
      expect(parser.parse(firstInput).value, ['(', 'use = "official"', ')']);
      expect(parser.parse(secondInput).value, ['(', '(5 + 5) * 5', ')']);
    });
    test('recursive (better)', () {
      final inner = undefined();
      final parser = char('(') & inner.star().flatten() & char(')');
      inner.set(parser | pattern('^)'));
      expect(parser.parse(firstInput).value, ['(', 'use = "official"', ')']);
      expect(parser.parse(secondInput).value, ['(', '(5 + 5) * 5', ')']);
    });
  });
  group('github.com/petitparser/dart-petitparser/issues/112', () {
    final inner = digit() & digit();
    test('original', () {
      final parser = inner.callCC((continuation, context) {
        final result = continuation(context);
        if (result.isSuccess && result.value[0] != result.value[1]) {
          return context.failure('values do not match');
        } else {
          return result;
        }
      });
      expect(parser, isParseSuccess('11', ['1', '1']));
      expect(parser, isParseSuccess('22', ['2', '2']));
      expect(parser, isParseSuccess('33', ['3', '3']));
      expect(
          parser, isParseFailure('1', position: 1, message: 'digit expected'));
      expect(parser, isParseFailure('12', message: 'values do not match'));
      expect(parser, isParseFailure('21', message: 'values do not match'));
    });
    test('where', () {
      final parser = inner.where((value) => value[0] == value[1],
          failureMessage: (value) => 'values do not match');
      expect(parser, isParseSuccess('11', ['1', '1']));
      expect(parser, isParseSuccess('22', ['2', '2']));
      expect(parser, isParseSuccess('33', ['3', '3']));
      expect(
          parser, isParseFailure('1', position: 1, message: 'digit expected'));
      expect(parser, isParseFailure('12', message: 'values do not match'));
      expect(parser, isParseFailure('21', message: 'values do not match'));
    });
  });
  test('https://github.com/petitparser/dart-petitparser/issues/121', () {
    final parser = (((letter() | char('_')) &
            (letter() | digit() | anyOf('_- ()')).star() &
            char('.').not('end of id expected')))
        .flatten();
    expect(parser, isParseSuccess('foo', 'foo'));
    expect(parser,
        isParseFailure('foo.1', message: 'end of id expected', position: 3));
  });
  test('https://github.com/petitparser/dart-petitparser/issues/126', () {
    final parser = ParensGrammar().build();
    expect(parser, isParseSuccess('', null));
    expect(parser, isParseSuccess('()', ['(', null, ')']));
    expect(
        parser,
        isParseSuccess('(())', [
          '(',
          ['(', null, ')'],
          ')'
        ]));
    expect(
        parser,
        isParseSuccess('((()))', [
          '(',
          [
            '(',
            ['(', null, ')'],
            ')'
          ],
          ')'
        ]));
  });
  group('https://stackoverflow.com/questions/73260748', () {
    test('Case 1', () {
      final parser = resolve(NestedGrammar1().start());
      expect(
          parser,
          isParseSuccess('(0)', [
            "'(' (nestedTerm)",
            "'0' (singleCharacter)",
            "')' (nestedTerm)",
          ]));
    });
    test('Case 2', () {
      final parser = resolve(NestedGrammar2().start());
      expect(
          parser,
          isParseSuccess('(0)', [
            "'(' (singleCharacter)",
            "'0' (singleCharacter)",
            "')' (singleCharacter)",
          ]));
    });
    test('Case 3', () {
      final parser = resolve(NestedGrammar3().start());
      expect(
          parser,
          isParseSuccess('(0)', [
            [
              "'(' (nestedTerm)",
              ["'0' (singleCharacter)"],
              "')' (nestedTerm)",
            ]
          ]));
    });
  });
}
