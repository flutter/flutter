import 'dart:math' as math;

import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

Parser buildParser() {
  final builder = ExpressionBuilder();
  builder.group()
    ..primitive(digit()
        .plus()
        .seq(char('.').seq(digit().plus()).optional())
        .flatten()
        .trim())
    ..wrapper(char('(').trim(), char(')').trim(),
        (left, value, right) => [left, value, right])
    ..wrapper(string('sqrt(').trim(), char(')').trim(),
        (left, value, right) => [left, value, right]);
  builder.group().prefix(char('-').trim(), (op, a) => [op, a]);
  builder.group()
    ..postfix(string('++').trim(), (a, op) => [a, op])
    ..postfix(string('--').trim(), (a, op) => [a, op]);
  builder.group().right(char('^').trim(), (a, op, b) => [a, op, b]);
  builder.group()
    ..left(char('*').trim(), (a, op, b) => [a, op, b])
    ..left(char('/').trim(), (a, op, b) => [a, op, b]);
  builder.group()
    ..left(char('+').trim(), (a, op, b) => [a, op, b])
    ..left(char('-').trim(), (a, op, b) => [a, op, b]);
  return builder.build().end();
}

Parser<num> buildEvaluator() {
  final builder = ExpressionBuilder<num>();
  builder.group()
    ..primitive(digit()
        .plus()
        .seq(char('.').seq(digit().plus()).optional())
        .flatten()
        .trim()
        .map(num.parse))
    ..wrapper(char('(').trim(), char(')').trim(), (left, value, right) => value)
    ..wrapper(string('sqrt(').trim(), char(')').trim(),
        (left, value, right) => math.sqrt(value));
  builder.group().prefix(char('-').trim(), (op, a) => -a);
  builder.group()
    ..postfix(string('++').trim(), (a, op) => ++a)
    ..postfix(string('--').trim(), (a, op) => --a);
  builder.group().right(char('^').trim(), (a, op, b) => math.pow(a, b));
  builder.group()
    ..left(char('*').trim(), (a, op, b) => a * b)
    ..left(char('/').trim(), (a, op, b) => a / b);
  builder.group()
    ..left(char('+').trim(), (a, op, b) => a + b)
    ..left(char('-').trim(), (a, op, b) => a - b);
  return builder.build().end();
}

void main() {
  const epsilon = 1e-5;
  final parser = buildParser();
  final evaluator = buildEvaluator();
  test('number', () {
    expect(evaluator.parse('0').value, closeTo(0, epsilon));
    expect(evaluator.parse('0.0').value, closeTo(0, epsilon));
    expect(evaluator.parse('1').value, closeTo(1, epsilon));
    expect(evaluator.parse('1.2').value, closeTo(1.2, epsilon));
    expect(evaluator.parse('34').value, closeTo(34, epsilon));
    expect(evaluator.parse('34.7').value, closeTo(34.7, epsilon));
    expect(evaluator.parse('56.78').value, closeTo(56.78, epsilon));
  });
  test('number negative', () {
    expect(evaluator.parse('-1').value, closeTo(-1, epsilon));
    expect(evaluator.parse('-1.2').value, closeTo(-1.2, epsilon));
  });
  test('number parse', () {
    expect(parser.parse('0').value, '0');
    expect(parser.parse('-1').value, ['-', '1']);
  });
  test('add', () {
    expect(evaluator.parse('1 + 2').value, closeTo(3, epsilon));
    expect(evaluator.parse('2 + 1').value, closeTo(3, epsilon));
    expect(evaluator.parse('1 + 2.3').value, closeTo(3.3, epsilon));
    expect(evaluator.parse('2.3 + 1').value, closeTo(3.3, epsilon));
    expect(evaluator.parse('1 + -2').value, closeTo(-1, epsilon));
    expect(evaluator.parse('-2 + 1').value, closeTo(-1, epsilon));
  });
  test('add many', () {
    expect(evaluator.parse('1').value, closeTo(1, epsilon));
    expect(evaluator.parse('1 + 2').value, closeTo(3, epsilon));
    expect(evaluator.parse('1 + 2 + 3').value, closeTo(6, epsilon));
    expect(evaluator.parse('1 + 2 + 3 + 4').value, closeTo(10, epsilon));
    expect(evaluator.parse('1 + 2 + 3 + 4 + 5').value, closeTo(15, epsilon));
  });
  test('add parse', () {
    expect(parser.parse('1 + 2 + 3').value, [
      ['1', '+', '2'],
      '+',
      '3'
    ]);
  });
  test('sub', () {
    expect(evaluator.parse('1 - 2').value, closeTo(-1, epsilon));
    expect(evaluator.parse('1.2 - 1.2').value, closeTo(0, epsilon));
    expect(evaluator.parse('1 - -2').value, closeTo(3, epsilon));
    expect(evaluator.parse('-1 - -2').value, closeTo(1, epsilon));
  });
  test('sub many', () {
    expect(evaluator.parse('1').value, closeTo(1, epsilon));
    expect(evaluator.parse('1 - 2').value, closeTo(-1, epsilon));
    expect(evaluator.parse('1 - 2 - 3').value, closeTo(-4, epsilon));
    expect(evaluator.parse('1 - 2 - 3 - 4').value, closeTo(-8, epsilon));
    expect(evaluator.parse('1 - 2 - 3 - 4 - 5').value, closeTo(-13, epsilon));
  });
  test('sub parse', () {
    expect(parser.parse('1 - 2 - 3').value, [
      ['1', '-', '2'],
      '-',
      '3'
    ]);
  });
  test('mul', () {
    expect(evaluator.parse('2 * 3').value, closeTo(6, epsilon));
    expect(evaluator.parse('2 * -4').value, closeTo(-8, epsilon));
  });
  test('mul many', () {
    expect(evaluator.parse('1 * 2').value, closeTo(2, epsilon));
    expect(evaluator.parse('1 * 2 * 3').value, closeTo(6, epsilon));
    expect(evaluator.parse('1 * 2 * 3 * 4').value, closeTo(24, epsilon));
    expect(evaluator.parse('1 * 2 * 3 * 4 * 5').value, closeTo(120, epsilon));
  });
  test('mul parse', () {
    expect(parser.parse('1 * 2 * 3').value, [
      ['1', '*', '2'],
      '*',
      '3'
    ]);
  });
  test('div', () {
    expect(evaluator.parse('12 / 3').value, closeTo(4, epsilon));
    expect(evaluator.parse('-16 / -4').value, closeTo(4, epsilon));
  });
  test('div many', () {
    expect(evaluator.parse('100 / 2').value, closeTo(50, epsilon));
    expect(evaluator.parse('100 / 2 / 2').value, closeTo(25, epsilon));
    expect(evaluator.parse('100 / 2 / 2 / 5').value, closeTo(5, epsilon));
    expect(evaluator.parse('100 / 2 / 2 / 5 / 5').value, closeTo(1, epsilon));
  });
  test('mul parse', () {
    expect(parser.parse('1 / 2 / 3').value, [
      ['1', '/', '2'],
      '/',
      '3'
    ]);
  });
  test('pow', () {
    expect(evaluator.parse('2 ^ 3').value, closeTo(8, epsilon));
    expect(evaluator.parse('-2 ^ 3').value, closeTo(-8, epsilon));
    expect(evaluator.parse('-2 ^ -3').value, closeTo(-0.125, epsilon));
  });
  test('pow many', () {
    expect(evaluator.parse('4 ^ 3').value, closeTo(64, epsilon));
    expect(evaluator.parse('4 ^ 3 ^ 2').value, closeTo(262144, epsilon));
    expect(evaluator.parse('4 ^ 3 ^ 2 ^ 1').value, closeTo(262144, epsilon));
    expect(
        evaluator.parse('4 ^ 3 ^ 2 ^ 1 ^ 0').value, closeTo(262144, epsilon));
  });
  test('pow parse', () {
    expect(parser.parse('1 ^ 2 ^ 3').value, [
      '1',
      '^',
      ['2', '^', '3']
    ]);
  });
  test('parens', () {
    expect(evaluator.parse('(1)').value, closeTo(1, epsilon));
    expect(evaluator.parse('(1 + 2)').value, closeTo(3, epsilon));
    expect(evaluator.parse('((1))').value, closeTo(1, epsilon));
    expect(evaluator.parse('((1 + 2))').value, closeTo(3, epsilon));
    expect(evaluator.parse('2 * (3 + 4)').value, closeTo(14, epsilon));
    expect(evaluator.parse('(2 + 3) * 4').value, closeTo(20, epsilon));
    expect(evaluator.parse('6 / (2 + 4)').value, closeTo(1, epsilon));
    expect(evaluator.parse('(2 + 6) / 2').value, closeTo(4, epsilon));
  });
  test('parens', () {
    expect(parser.parse('(1)').value, ['(', '1', ')']);
    expect(parser.parse('(1 + 2)').value, [
      '(',
      ['1', '+', '2'],
      ')'
    ]);
    expect(parser.parse('((1))').value, [
      '(',
      ['(', '1', ')'],
      ')'
    ]);
    expect(parser.parse('((1 + 2))').value, [
      '(',
      [
        '(',
        ['1', '+', '2'],
        ')'
      ],
      ')'
    ]);
    expect(parser.parse('2 * (3 + 4)').value, [
      '2',
      '*',
      [
        '(',
        ['3', '+', '4'],
        ')'
      ]
    ]);
    expect(parser.parse('(2 + 3) * 4').value, [
      [
        '(',
        ['2', '+', '3'],
        ')'
      ],
      '*',
      '4'
    ]);
    expect(parser.parse('6 / (2 + 4)').value, [
      '6',
      '/',
      [
        '(',
        ['2', '+', '4'],
        ')'
      ]
    ]);
    expect(parser.parse('(2 + 6) / 2').value, [
      [
        '(',
        ['2', '+', '6'],
        ')'
      ],
      '/',
      '2'
    ]);
  });
  test('sqrt', () {
    expect(evaluator.parse('sqrt(4)').value, closeTo(2, epsilon));
    expect(evaluator.parse('sqrt(1 + 3)').value, closeTo(2, epsilon));
    expect(evaluator.parse('1 + sqrt(16)').value, closeTo(5, epsilon));
    expect(evaluator.parse('sqrt(sqrt(16))').value, closeTo(2, epsilon));
  });
  test('sqrt parse', () {
    expect(parser.parse('sqrt(4)').value, ['sqrt(', '4', ')']);
    expect(parser.parse('sqrt(1 + 3)').value, [
      'sqrt(',
      ['1', '+', '3'],
      ')'
    ]);
    expect(parser.parse('1 + sqrt(16)').value, [
      '1',
      '+',
      ['sqrt(', '16', ')']
    ]);
    expect(parser.parse('sqrt(sqrt(16))').value, [
      'sqrt(',
      ['sqrt(', '16', ')'],
      ')'
    ]);
  });
  test('priority', () {
    expect(evaluator.parse('2 * 3 + 4').value, closeTo(10, epsilon));
    expect(evaluator.parse('2 + 3 * 4').value, closeTo(14, epsilon));
    expect(evaluator.parse('6 / 3 + 4').value, closeTo(6, epsilon));
    expect(evaluator.parse('2 + 6 / 2').value, closeTo(5, epsilon));
  });
  test('priority parse', () {
    expect(parser.parse('2 * 3 + 4').value, [
      ['2', '*', '3'],
      '+',
      '4'
    ]);
    expect(parser.parse('2 + 3 * 4').value, [
      '2',
      '+',
      ['3', '*', '4']
    ]);
  });
  test('postfix add', () {
    expect(evaluator.parse('0++').value, closeTo(1, epsilon));
    expect(evaluator.parse('0++++').value, closeTo(2, epsilon));
    expect(evaluator.parse('0++++++').value, closeTo(3, epsilon));
    expect(evaluator.parse('0+++1').value, closeTo(2, epsilon));
    expect(evaluator.parse('0+++++1').value, closeTo(3, epsilon));
    expect(evaluator.parse('0+++++++1').value, closeTo(4, epsilon));
  });
  test('postfix add parse', () {
    expect(parser.parse('0++').value, ['0', '++']);
    expect(parser.parse('0++++').value, [
      ['0', '++'],
      '++'
    ]);
    expect(parser.parse('0++++++').value, [
      [
        ['0', '++'],
        '++'
      ],
      '++'
    ]);
    expect(parser.parse('0+++1').value, [
      ['0', '++'],
      '+',
      '1'
    ]);
    expect(parser.parse('0+++++1').value, [
      [
        ['0', '++'],
        '++'
      ],
      '+',
      '1'
    ]);
    expect(parser.parse('0+++++++1').value, [
      [
        [
          ['0', '++'],
          '++'
        ],
        '++'
      ],
      '+',
      '1'
    ]);
  });
  test('postfix sub', () {
    expect(evaluator.parse('1--').value, closeTo(0, epsilon));
    expect(evaluator.parse('2----').value, closeTo(0, epsilon));
    expect(evaluator.parse('3------').value, closeTo(0, epsilon));
    expect(evaluator.parse('2---1').value, closeTo(0, epsilon));
    expect(evaluator.parse('3-----1').value, closeTo(0, epsilon));
    expect(evaluator.parse('4-------1').value, closeTo(0, epsilon));
  });
  test('postfix sub parse', () {
    expect(parser.parse('0--').value, ['0', '--']);
    expect(parser.parse('0----').value, [
      ['0', '--'],
      '--'
    ]);
    expect(parser.parse('0------').value, [
      [
        ['0', '--'],
        '--'
      ],
      '--'
    ]);
    expect(parser.parse('0---1').value, [
      ['0', '--'],
      '-',
      '1'
    ]);
    expect(parser.parse('0-----1').value, [
      [
        ['0', '--'],
        '--'
      ],
      '-',
      '1'
    ]);
    expect(parser.parse('0-------1').value, [
      [
        [
          ['0', '--'],
          '--'
        ],
        '--'
      ],
      '-',
      '1'
    ]);
  });
  test('negate', () {
    expect(evaluator.parse('1').value, closeTo(1, epsilon));
    expect(evaluator.parse('-1').value, closeTo(-1, epsilon));
    expect(evaluator.parse('--1').value, closeTo(1, epsilon));
    expect(evaluator.parse('---1').value, closeTo(-1, epsilon));
  });
  test('negate parse', () {
    expect(parser.parse('1').value, '1');
    expect(parser.parse('-1').value, ['-', '1']);
    expect(parser.parse('--1').value, [
      '-',
      ['-', '1']
    ]);
    expect(parser.parse('---1').value, [
      '-',
      [
        '-',
        ['-', '1']
      ]
    ]);
  });
  test('linter', () {
    expect(linter(parser), isEmpty);
    expect(linter(evaluator), isEmpty);
  });
}
