import 'package:flutter_tools/src/localizations/message_parser.dart';
import '../src/common.dart';

void expectTokensEqual(List<TokenNode> actual, List<TokenNode> expected) {
  final errorMessage = '''
Expected
$expected
but got
$actual
''';
  expect(actual.length, equals(expected.length), reason: errorMessage);
  for (int i = 0; i < actual.length; i++) {
    expect(actual[i].value, equals(expected[i].value), reason: errorMessage);
    expect(actual[i].type, equals(expected[i].type), reason: errorMessage);
  }
}

void main() {

  testWithoutContext('lexer basic', () {
    final List<TokenNode> tokens1 = lex('Hello {name}');
    expectTokensEqual(tokens1, <TokenNode>[
      TokenNode.string('Hello '),
      TokenNode.openBrace(),
      TokenNode.identifier('name'),
      TokenNode.closeBrace(),
    ]);

    final List<TokenNode> tokens2 = lex('There are {count} {count, plural, =1{cat} other{cats}}');
    expectTokensEqual(tokens2, <TokenNode>[
      TokenNode.string('There are '),
      TokenNode.openBrace(),
      TokenNode.identifier('count'),
      TokenNode.closeBrace(),
      TokenNode.string(' '),
      TokenNode.openBrace(),
      TokenNode.identifier('count'),
      TokenNode.comma(),
      TokenNode.plural(),
      TokenNode.comma(),
      TokenNode.equalSign(),
      TokenNode.number('1'),
      TokenNode.openBrace(),
      TokenNode.string('cat'),
      TokenNode.closeBrace(),
      TokenNode.other(),
      TokenNode.openBrace(),
      TokenNode.string('cats'),
      TokenNode.closeBrace(),
      TokenNode.closeBrace(),
    ]);

    final List<TokenNode> tokens3 = lex('{gender, select, male{he} female{she} other{they}}');
    expectTokensEqual(tokens3, <TokenNode>[
      TokenNode.openBrace(),
      TokenNode.identifier('gender'),
      TokenNode.comma(),
      TokenNode.select(),
      TokenNode.comma(),
      TokenNode.identifier('male'),
      TokenNode.openBrace(),
      TokenNode.string('he'),
      TokenNode.closeBrace(),
      TokenNode.identifier('female'),
      TokenNode.openBrace(),
      TokenNode.string('she'),
      TokenNode.closeBrace(),
      TokenNode.other(),
      TokenNode.openBrace(),
      TokenNode.string('they'),
      TokenNode.closeBrace(),
      TokenNode.closeBrace(),
    ]);

  });

  testWithoutContext('lexer recursive', () {
    final List<TokenNode> tokens1 = lex('{count, plural, =1{{gender, select, male{he} female{she}}} other{they}}');
    print(tokens1);
  });

  testWithoutContext('lexer escaping', () {

  });

  testWithoutContext('lexer: lexically correct but syntactically incorrect', () {
    final List<TokenNode> tokens1 = lex('string { identifier { string { identifier } } }');
  });

  testWithoutContext('parser basic', () {
    final Node messageNode1 = parse(lex('Hello {name}'));

    final Node messageNode2 = parse(lex('There are {count} {count, plural, =1{cat} other{cats}}'));

    final Node messageNode3 = parse(lex('{gender, select, male{he} female{she} other{they}}'));
  });

  testWithoutContext('parser recursive', () {
    final Node messageNode1 = parse(lex('{count, plural, =1{{gender, select, male{he} female{she}}} other{they}}'));
    print(messageNode1);
  });
}
