import 'dart:math' as math;

import 'package:petitparser/debug.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

class ExpressionDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(term).end();
  Parser term() => ref0(add) | ref0(prod);
  Parser add() => ref0(prod) & char('+').trim() & ref0(term);
  Parser prod() => ref0(mul) | ref0(prim);
  Parser mul() => ref0(prim) & char('*').trim() & ref0(prod);
  Parser prim() => ref0(parens) | ref0(number);
  Parser parens() => char('(').trim() & ref0(term) & char(')').trim();
  Parser number() => digit().plus().flatten().trim();
}

class EvaluatorDefinition extends ExpressionDefinition {
  @override
  Parser add() =>
      super.add().castList<num>().map((values) => values[0] + values[2]);
  @override
  Parser mul() =>
      super.mul().castList<num>().map((values) => values[0] * values[2]);
  @override
  Parser parens() => super.parens().castList<num>().pick(1);
  @override
  Parser number() => super.number().map((value) => int.parse(value));
}

void main() {
  test('simple grammar (operators)', () {
    final id = letter() & (letter() | digit()).star();
    final id1 = id.parse('yeah');
    final id2 = id.parse('f12');
    expect(id1.value, [
      'y',
      ['e', 'a', 'h']
    ]);
    expect(id2.value, [
      'f',
      ['1', '2']
    ]);
    final id3 = id.parse('123');
    expect(id3.message, 'letter expected');
    expect(id3.position, 0);
    expect(id.accept('foo'), isTrue);
    expect(id.accept('123'), isFalse);
  });
  test('simple grammar (chained calls)', () {
    final id = letter().seq(letter().or(digit()).star());
    final id1 = id.parse('yeah');
    final id2 = id.parse('f12');
    expect(id1.value, [
      'y',
      ['e', 'a', 'h']
    ]);
    expect(id2.value, [
      'f',
      ['1', '2']
    ]);
    final id3 = id.parse('123');
    expect(id3.message, 'letter expected');
    expect(id3.position, 0);
    expect(id.accept('foo'), isTrue);
    expect(id.accept('123'), isFalse);
  });
  test('simple grammar (lists)', () {
    final id = [
      letter(),
      [letter(), digit()].toChoiceParser().star()
    ].toSequenceParser();
    final id1 = id.parse('yeah');
    final id2 = id.parse('f12');
    expect(id1.value, [
      'y',
      ['e', 'a', 'h']
    ]);
    expect(id2.value, [
      'f',
      ['1', '2']
    ]);
    final id3 = id.parse('123');
    expect(id3.message, 'letter expected');
    expect(id3.position, 0);
    expect(id.accept('foo'), isTrue);
    expect(id.accept('123'), isFalse);
  });
  test('simple grammar (typed functions)', () {
    final id = seq2(letter(), [letter(), digit()].toChoiceParser().star());
    final id1 = id.parse('yeah');
    final id2 = id.parse('f12');
    expect(
        id1.value,
        isA<Sequence2>()
            .having((sequence) => sequence.first, 'first', 'y')
            .having((sequence) => sequence.second, 'second', ['e', 'a', 'h']));
    expect(
        id2.value,
        isA<Sequence2>()
            .having((sequence) => sequence.first, 'first', 'f')
            .having((sequence) => sequence.second, 'second', ['1', '2']));
    final id3 = id.parse('123');
    expect(id3.message, 'letter expected');
    expect(id3.position, 0);
    expect(id.accept('foo'), isTrue);
    expect(id.accept('123'), isFalse);
  });
  test('different parsers (word)', () {
    final id1 = letter() & word().star();
    final matches = id1.flatten().allMatches('foo 123 bar4');
    expect(matches, ['foo', 'bar4']);
  });
  test('different parsers (pattern)', () {
    final id2 = letter() & pattern('a-zA-Z0-9').star();
    final matches = id2.flatten().allMatches('foo 123 bar4');
    expect(matches, ['foo', 'bar4']);
  });
  test('complicated grammar', () {
    final term = undefined();
    final prod = undefined();
    final prim = undefined();
    final add = (prod & char('+').trim() & term)
        .castList<num>()
        .map((values) => values[0] + values[2]);
    term.set(add | prod);
    final mul = (prim & char('*').trim() & prod)
        .castList<num>()
        .map((values) => values[0] * values[2]);
    prod.set(mul | prim);
    final parens =
        (char('(').trim() & term & char(')').trim()).map((values) => values[1]);
    final number = digit().plus().flatten().trim().map(int.parse);
    prim.set(parens | number);
    final parser = term.end();
    expect(parser.parse('1 + 2 + 3').value, 6);
    expect(parser.parse('1 + 2 * 3').value, 7);
    expect(parser.parse('(1 + 2) * 3').value, 9);
  });
  test('expression definition', () {
    final parser = ExpressionDefinition().build();
    expect(parser.parse('1 + 2 + 3').value, [
      '1',
      '+',
      ['2', '+', '3']
    ]);
    expect(parser.parse('1 + 2 * 3').value, [
      '1',
      '+',
      ['2', '*', '3']
    ]);
    expect(parser.parse('(1 + 2) * 3').value, [
      [
        '(',
        ['1', '+', '2'],
        ')'
      ],
      '*',
      '3'
    ]);
  });
  test('evaluator definition', () {
    final definition = ExpressionDefinition();
    final parser = definition.build();
    expect(parser.parse('1 + 2 + 3').value, [
      '1',
      '+',
      ['2', '+', '3']
    ]);
    expect(parser.parse('1 + 2 * 3').value, [
      '1',
      '+',
      ['2', '*', '3']
    ]);
    expect(parser.parse('(1 + 2) * 3').value, [
      [
        '(',
        ['1', '+', '2'],
        ')'
      ],
      '*',
      '3'
    ]);
  });
  test('number definition', () {
    final definition = EvaluatorDefinition();
    final parser = definition.build();
    expect(parser.parse('1 + 2 + 3').value, 6);
    expect(parser.parse('1 + 2 * 3').value, 7);
    expect(parser.parse('(1 + 2) * 3').value, 9);
  });
  test('number definition', () {
    final definition = EvaluatorDefinition();
    final parser = definition.build(start: definition.number);
    expect(parser.parse('42').value, 42);
  });
  test('expression builder', () {
    final builder = ExpressionBuilder<num>();
    builder.group()
      ..primitive(digit()
          .plus()
          .seq(char('.').seq(digit().plus()).optional())
          .flatten()
          .trim()
          .map(num.parse))
      ..wrapper(char('(').trim(), char(')').trim(), (l, a, r) => a);
    // Negation is a prefix operator
    builder.group().prefix(char('-').trim(), (op, a) => -a);
    // Power is right-associative
    builder.group().right(char('^').trim(), (a, op, b) => math.pow(a, b));
    // Multiplication and addition are left-associative
    builder.group()
      ..left(char('*').trim(), (a, op, b) => a * b)
      ..left(char('/').trim(), (a, op, b) => a / b);
    builder.group()
      ..left(char('+').trim(), (a, op, b) => a + b)
      ..left(char('-').trim(), (a, op, b) => a - b);
    final parser = builder.build().end();
    expect(parser.parse('-8').value, -8);
    expect(parser.parse('1+2*3').value, 7);
    expect(parser.parse('1*2+3').value, 5);
    expect(parser.parse('8/4/2').value, 1);
    expect(parser.parse('2^2^3').value, 256);
  });
  test('number parsing', () {
    final definition = EvaluatorDefinition();
    final parser = definition.build(start: definition.number);
    expect(parser.parse('42').value, 42);
  });
  test('detect common problems', () {
    final definition = EvaluatorDefinition();
    final parser = definition.build();
    expect(linter(parser), isEmpty);
  });
  test('debugging parser', () {
    final output = <TraceEvent>[];
    final parser = letter() & word().star();
    trace(parser, output: output.add).parse('f1');
    expect(output.map((each) => each.toString()), [
      "Instance of 'SequenceParser<dynamic>'",
      "  Instance of 'CharacterParser'[letter expected]",
      "  Success[1:2]: f",
      "  Instance of 'PossessiveRepeatingParser<String>'[0..*]",
      "    Instance of 'CharacterParser'[letter or digit expected]",
      "    Success[1:3]: 1",
      "    Instance of 'CharacterParser'[letter or digit expected]",
      "    Failure[1:3]: letter or digit expected",
      "  Success[1:3]: [1]",
      "Success[1:3]: [f, [1]]",
    ]);
  });
}
