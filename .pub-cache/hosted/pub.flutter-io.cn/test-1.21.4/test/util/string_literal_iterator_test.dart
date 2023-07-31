// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_core/src/util/string_literal_iterator.dart';

final _offset = 'final str = '.length;

void main() {
  group('returns simple characters in', () {
    test('a single simple string', () {
      var iter = _parse('"abc"');

      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('a'));
      expect(iter.offset, equals(_offset + 1));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('b'));
      expect(iter.offset, equals(_offset + 2));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('c'));
      expect(iter.offset, equals(_offset + 3));

      expect(iter.moveNext(), isFalse);
      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 4));
    });

    test('a raw string', () {
      var iter = _parse('r"abc"');

      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 1));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('a'));
      expect(iter.offset, equals(_offset + 2));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('b'));
      expect(iter.offset, equals(_offset + 3));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('c'));
      expect(iter.offset, equals(_offset + 4));

      expect(iter.moveNext(), isFalse);
      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 5));
    });

    test('a multiline string', () {
      var iter = _parse('"""ab\ncd"""');

      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 2));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('a'));
      expect(iter.offset, equals(_offset + 3));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('b'));
      expect(iter.offset, equals(_offset + 4));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('\n'));
      expect(iter.offset, equals(_offset + 5));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('c'));
      expect(iter.offset, equals(_offset + 6));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('d'));
      expect(iter.offset, equals(_offset + 7));

      expect(iter.moveNext(), isFalse);
      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 8));
    });

    test('a raw multiline string', () {
      var iter = _parse('r"""ab\ncd"""');

      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 3));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('a'));
      expect(iter.offset, equals(_offset + 4));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('b'));
      expect(iter.offset, equals(_offset + 5));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('\n'));
      expect(iter.offset, equals(_offset + 6));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('c'));
      expect(iter.offset, equals(_offset + 7));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('d'));
      expect(iter.offset, equals(_offset + 8));

      expect(iter.moveNext(), isFalse);
      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 9));
    });

    test('adjacent strings', () {
      var iter = _parse('"ab" r"cd" """ef\ngh"""');

      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('a'));
      expect(iter.offset, equals(_offset + 1));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('b'));
      expect(iter.offset, equals(_offset + 2));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('c'));
      expect(iter.offset, equals(_offset + 7));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('d'));
      expect(iter.offset, equals(_offset + 8));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('e'));
      expect(iter.offset, equals(_offset + 14));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('f'));
      expect(iter.offset, equals(_offset + 15));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('\n'));
      expect(iter.offset, equals(_offset + 16));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('g'));
      expect(iter.offset, equals(_offset + 17));

      expect(iter.moveNext(), isTrue);
      expect(iter.current, _isRune('h'));
      expect(iter.offset, equals(_offset + 18));

      expect(iter.moveNext(), isFalse);
      expect(() => iter.current, throwsA(isA<TypeError>()));
      expect(iter.offset, equals(_offset + 19));
    });
  });

  group('parses an escape sequence for', () {
    test('a newline', () => _expectEscape(r'\n', '\n'));
    test('a carriage return', () => _expectEscape(r'\r', '\r'));
    test('a form feed', () => _expectEscape(r'\f', '\f'));
    test('a backspace', () => _expectEscape(r'\b', '\b'));
    test('a tab', () => _expectEscape(r'\t', '\t'));
    test('a vertical tab', () => _expectEscape(r'\v', '\v'));
    test('a quote', () => _expectEscape(r'\"', '"'));
    test('a backslash', () => _expectEscape(r'\\', '\\'));

    test('a hex character', () {
      _expectEscape(r'\x62', 'b');
      _expectEscape(r'\x7A', 'z');
      _expectEscape(r'\x7a', 'z');
    });

    test('a fixed-length unicode character',
        () => _expectEscape(r'\u0062', 'b'));

    test('a short variable-length unicode character',
        () => _expectEscape(r'\u{62}', 'b'));

    test('a long variable-length unicode character',
        () => _expectEscape(r'\u{000062}', 'b'));
  });

  group('throws an ArgumentError for', () {
    test('interpolation', () {
      expect(() => _parse(r'"$foo"'), throwsArgumentError);
    });

    test('interpolation in an adjacent string', () {
      expect(() => _parse(r'"foo" "$bar" "baz"'), throwsArgumentError);
    });
  });
}

/// Asserts that [escape] is parsed as [value].
void _expectEscape(String escape, String value) {
  var iter = _parse('"a${escape}b"');

  expect(() => iter.current, throwsA(isA<TypeError>()));
  expect(iter.offset, equals(_offset));

  expect(iter.moveNext(), isTrue);
  expect(iter.current, _isRune('a'));
  expect(iter.offset, equals(_offset + 1));

  expect(iter.moveNext(), isTrue);
  expect(iter.current, _isRune(value));
  expect(iter.offset, equals(_offset + 2));

  expect(iter.moveNext(), isTrue);
  expect(iter.current, _isRune('b'));
  expect(iter.offset, equals(_offset + escape.length + 2));

  expect(iter.moveNext(), isFalse);
  expect(() => iter.current, throwsA(isA<TypeError>()));
  expect(iter.offset, equals(_offset + escape.length + 3));
}

/// Returns a matcher that asserts that the given rune is the rune for [char].
Matcher _isRune(String char) {
  return predicate((rune) {
    return rune is int && String.fromCharCode(rune) == char;
  }, 'is the rune "$char"');
}

/// Parses [dart], which should be a string literal, into a
/// [StringLiteralIterator].
StringLiteralIterator _parse(String dart) {
  var declaration = parseString(content: 'final str = $dart;')
      .unit
      .declarations
      .single as TopLevelVariableDeclaration;
  var literal = declaration.variables.variables.single.initializer;
  return StringLiteralIterator(literal as StringLiteral);
}
