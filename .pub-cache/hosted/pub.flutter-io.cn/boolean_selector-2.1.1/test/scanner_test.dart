// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/src/scanner.dart';
import 'package:boolean_selector/src/token.dart';
import 'package:test/test.dart';

/// A matcher that asserts that a value is a [IdentifierToken].
final _isIdentifierToken = TypeMatcher<IdentifierToken>();

void main() {
  group('peek()', () {
    test('returns the next token without consuming it', () {
      var scanner = Scanner('( )');
      expect(scanner.peek().type, equals(TokenType.leftParen));
      expect(scanner.peek().type, equals(TokenType.leftParen));
      expect(scanner.peek().type, equals(TokenType.leftParen));
    });

    test('returns an end-of-file token at the end of a file', () {
      var scanner = Scanner('( )');
      scanner.next();
      scanner.next();

      var token = scanner.peek();
      expect(token.type, equals(TokenType.endOfFile));
      expect(token.span.start.offset, equals(3));
      expect(token.span.end.offset, equals(3));
    });

    test('throws a StateError if called after end-of-file was consumed', () {
      var scanner = Scanner('( )');
      scanner.next();
      scanner.next();
      scanner.next();
      expect(() => scanner.peek(), throwsStateError);
    });
  });

  group('next()', () {
    test('consumes and returns the next token', () {
      var scanner = Scanner('( )');
      expect(scanner.next().type, equals(TokenType.leftParen));
      expect(scanner.peek().type, equals(TokenType.rightParen));
      expect(scanner.next().type, equals(TokenType.rightParen));
    });

    test('returns an end-of-file token at the end of a file', () {
      var scanner = Scanner('( )');
      scanner.next();
      scanner.next();

      var token = scanner.next();
      expect(token.type, equals(TokenType.endOfFile));
      expect(token.span.start.offset, equals(3));
      expect(token.span.end.offset, equals(3));
    });

    test('throws a StateError if called after end-of-file was consumed', () {
      var scanner = Scanner('( )');
      scanner.next();
      scanner.next();
      scanner.next();
      expect(() => scanner.next(), throwsStateError);
    });
  });

  group('scan()', () {
    test('consumes a matching token and returns true', () {
      var scanner = Scanner('( )');
      expect(scanner.scan(TokenType.leftParen), isTrue);
      expect(scanner.peek().type, equals(TokenType.rightParen));
    });

    test("doesn't consume a matching token and returns false", () {
      var scanner = Scanner('( )');
      expect(scanner.scan(TokenType.questionMark), isFalse);
      expect(scanner.peek().type, equals(TokenType.leftParen));
    });

    test('throws a StateError called after end-of-file was consumed', () {
      var scanner = Scanner('( )');
      scanner.next();
      scanner.next();
      scanner.next();
      expect(() => scanner.scan(TokenType.endOfFile), throwsStateError);
    });
  });

  group('scans a simple token:', () {
    test('left paren', () => _expectSimpleScan('(', TokenType.leftParen));
    test('right paren', () => _expectSimpleScan(')', TokenType.rightParen));
    test('or', () => _expectSimpleScan('||', TokenType.or));
    test('and', () => _expectSimpleScan('&&', TokenType.and));
    test('not', () => _expectSimpleScan('!', TokenType.not));
    test('question mark', () => _expectSimpleScan('?', TokenType.questionMark));
    test('colon', () => _expectSimpleScan(':', TokenType.colon));
  });

  group('scans an identifier that', () {
    test('is simple', () {
      var token = _scan('   foo  ');
      expect(token, _isIdentifierToken);
      token as IdentifierToken; // promote token

      expect(token.name, equals('foo'));
      expect(token.span.text, equals('foo'));
      expect(token.span.start.offset, equals(3));
      expect(token.span.end.offset, equals(6));
    });

    test('is a single character', () {
      var token = _scan('f');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('f'));
    });

    test('has a leading underscore', () {
      var token = _scan('_foo');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('_foo'));
    });

    test('has a leading dash', () {
      var token = _scan('-foo');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('-foo'));
    });

    test('contains an underscore', () {
      var token = _scan('foo_bar');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('foo_bar'));
    });

    test('contains a dash', () {
      var token = _scan('foo-bar');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('foo-bar'));
    });

    test('is capitalized', () {
      var token = _scan('FOO');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('FOO'));
    });

    test('contains numbers', () {
      var token = _scan('foo123');
      expect(token, _isIdentifierToken);
      expect((token as IdentifierToken).name, equals('foo123'));
    });
  });

  test('scans an empty selector', () {
    expect(_scan('').type, equals(TokenType.endOfFile));
  });

  test('scans multiple tokens', () {
    var scanner = Scanner('(foo && bar)');

    var token = scanner.next();
    expect(token.type, equals(TokenType.leftParen));
    expect(token.span.start.offset, equals(0));
    expect(token.span.end.offset, equals(1));

    token = scanner.next();
    expect(token.type, equals(TokenType.identifier));
    expect((token as IdentifierToken).name, equals('foo'));
    expect(token.span.start.offset, equals(1));
    expect(token.span.end.offset, equals(4));

    token = scanner.next();
    expect(token.type, equals(TokenType.and));
    expect(token.span.start.offset, equals(5));
    expect(token.span.end.offset, equals(7));

    token = scanner.next();
    expect(token.type, equals(TokenType.identifier));
    expect((token as IdentifierToken).name, equals('bar'));
    expect(token.span.start.offset, equals(8));
    expect(token.span.end.offset, equals(11));

    token = scanner.next();
    expect(token.type, equals(TokenType.rightParen));
    expect(token.span.start.offset, equals(11));
    expect(token.span.end.offset, equals(12));

    token = scanner.next();
    expect(token.type, equals(TokenType.endOfFile));
    expect(token.span.start.offset, equals(12));
    expect(token.span.end.offset, equals(12));
  });

  group('ignores', () {
    test('a single-line comment', () {
      var scanner = Scanner('( // &&\n// ||\n)');
      expect(scanner.next().type, equals(TokenType.leftParen));
      expect(scanner.next().type, equals(TokenType.rightParen));
      expect(scanner.next().type, equals(TokenType.endOfFile));
    });

    test('a single-line comment without a trailing newline', () {
      var scanner = Scanner('( // &&');
      expect(scanner.next().type, equals(TokenType.leftParen));
      expect(scanner.next().type, equals(TokenType.endOfFile));
    });

    test('a multi-line comment', () {
      var scanner = Scanner('( /* && * /\n|| */\n)');
      expect(scanner.next().type, equals(TokenType.leftParen));
      expect(scanner.next().type, equals(TokenType.rightParen));
      expect(scanner.next().type, equals(TokenType.endOfFile));
    });

    test('a multi-line nested comment', () {
      var scanner = Scanner('(/* && /* ? /* || */ : */ ! */)');
      expect(scanner.next().type, equals(TokenType.leftParen));
      expect(scanner.next().type, equals(TokenType.rightParen));
      expect(scanner.next().type, equals(TokenType.endOfFile));
    });

    test("Dart's notion of whitespace", () {
      var scanner = Scanner('( \t \n)');
      expect(scanner.next().type, equals(TokenType.leftParen));
      expect(scanner.next().type, equals(TokenType.rightParen));
      expect(scanner.next().type, equals(TokenType.endOfFile));
    });
  });

  group('disallows', () {
    test('a single |', () {
      expect(() => _scan('|'), throwsFormatException);
    });

    test('"| |"', () {
      expect(() => _scan('| |'), throwsFormatException);
    });

    test('a single &', () {
      expect(() => _scan('&'), throwsFormatException);
    });

    test('"& &"', () {
      expect(() => _scan('& &'), throwsFormatException);
    });

    test('an unknown operator', () {
      expect(() => _scan('=='), throwsFormatException);
    });

    test('unicode', () {
      expect(() => _scan('öh'), throwsFormatException);
    });

    test('an unclosed multi-line comment', () {
      expect(() => _scan('/*'), throwsFormatException);
    });

    test('an unopened multi-line comment', () {
      expect(() => _scan('*/'), throwsFormatException);
    });
  });
}

/// Asserts that the first token scanned from [selector] has type [type],
/// and that that token's span is exactly [selector].
void _expectSimpleScan(String selector, TokenType type) {
  // Complicate the selector to test that the span covers it correctly.
  var token = _scan('   $selector  ');
  expect(token.type, equals(type));
  expect(token.span.text, equals(selector));
  expect(token.span.start.offset, equals(3));
  expect(token.span.end.offset, equals(3 + selector.length));
}

/// Scans a single token from [selector].
Token _scan(String selector) => Scanner(selector).next();
