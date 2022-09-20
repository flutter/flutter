import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';
import 'package:flutter_tools/src/localizations/message_parser.dart';
import '../src/common.dart';

void expectTokensEqual(List<Node> actual, List<Node> expected) {
  final String errorMessage = '''
Expected
$expected
but got
$actual
''';
  expect(actual.length, equals(expected.length), reason: errorMessage);
  for (int i = 0; i < actual.length; i++) {
    expect(actual[i].value, equals(expected[i].value), reason: errorMessage);
    expect(actual[i].type, equals(expected[i].type), reason: errorMessage);
    expect(actual[i].positionInMessage, equals(expected[i].positionInMessage), reason: errorMessage);
  }
}

void main() {

  testWithoutContext('lexer basic', () {
    final List<Node> tokens1 = lex('Hello {name}');
    expectTokensEqual(tokens1, <Node>[
      Node.string(0, 'Hello '),
      Node.openBrace(6),
      Node.identifier(7, 'name'),
      Node.closeBrace(11),
    ]);

    // final List<Node> tokens2 = lex('There are {count} {count, plural, =1{cat} other{cats}}');
    // expectTokensEqual(tokens2, <Node>[
    //   Node.string('There are '),
    //   Node.openBrace(),
    //   Node.identifier('count'),
    //   Node.closeBrace(),
    //   Node.string(' '),
    //   Node.openBrace(),
    //   Node.identifier('count'),
    //   Node.comma(),
    //   Node.plural(),
    //   Node.comma(),
    //   Node.equalSign(),
    //   Node.number('1'),
    //   Node.openBrace(),
    //   Node.string('cat'),
    //   Node.closeBrace(),
    //   Node.other(),
    //   Node.openBrace(),
    //   Node.string('cats'),
    //   Node.closeBrace(),
    //   Node.closeBrace(),
    // ]);

    // final List<Node> tokens3 = lex('{gender, select, male{he} female{she} other{they}}');
    // expectTokensEqual(tokens3, <Node>[
    //   Node.openBrace(),
    //   Node.identifier('gender'),
    //   Node.comma(),
    //   Node.select(),
    //   Node.comma(),
    //   Node.identifier('male'),
    //   Node.openBrace(),
    //   Node.string('he'),
    //   Node.closeBrace(),
    //   Node.identifier('female'),
    //   Node.openBrace(),
    //   Node.string('she'),
    //   Node.closeBrace(),
    //   Node.other(),
    //   Node.openBrace(),
    //   Node.string('they'),
    //   Node.closeBrace(),
    //   Node.closeBrace(),
    // ]);

  });

  testWithoutContext('lexer recursive', () {
    final List<Node> tokens1 = lex('{count, plural, =1{{gender, select, male{he} female{she}}} other{they}}');
    print(tokens1);
  });

  testWithoutContext('lexer escaping', () {

  });

  testWithoutContext('lexer: lexically correct but syntactically incorrect', () {
    final List<Node> tokens1 = lex('string { identifier { string { identifier } } }');
  });

  testWithoutContext('parser basic', () {
    final Node messageNode1 = parse('Hello {name}');

    final Node messageNode2 = parse('There are {count} {count, plural, =1{cat} other{cats}}');

    final Node messageNode3 = parse('{gender, select, male{he} female{she} other{they}}');
  });

  testWithoutContext('parser recursive', () {
    final Node messageNode1 = parse('{count, plural, =1{{gender, select, male{he} female{she}}} other{they}}');
    print(messageNode1);
  });
  
  testWithoutContext('parser unexpected token', () {
    // unexpected token
    expect(
      () => parse('{ placeholder = '),
      throwsA(isA<L10nException>().having(
        (L10nException e) => e.message,
        'message',
        contains('ICU Syntax Error: Expected "{" but found "="'),
    )));
    expect(
      () => parse('{ count, plural, = }'),
      throwsA(isA<L10nException>().having(
        (L10nException e) => e.message,
        'message',
        contains('ICU Syntax Error: Expected number but found "}"'),
    )));
    expect(
      () => parse('{ , plural , = }'),
      throwsA(isA<L10nException>().having(
        (L10nException e) => e.message,
        'message',
        contains('ICU Syntax Error: Expected identifier but found ","'),
    )));

  });
}
