// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

void main() {
  group('$WordBreaker', () {
    test('Does not go beyond the ends of a string', () {
      expect(WordBreaker.prevBreakIndex('foo', 0), 0);
      expect(WordBreaker.nextBreakIndex('foo', 'foo'.length), 'foo'.length);
    });

    test('Words and spaces', () {
      expectWords('foo bar', ['foo', ' ', 'bar']);
      expectWords('foo bar', ['foo', ' ', 'bar']);
    });

    test('Single-letter words', () {
      expectWords('foo a bar', ['foo', ' ', 'a', ' ', 'bar']);
      expectWords('a b c', ['a', ' ', 'b', ' ', 'c']);
      expectWords(' a b ', [' ', 'a', ' ', 'b', ' ']);
    });

    test('Multiple consecutive spaces', () {
      // Different types of whitespace:
      final String oghamSpace = String.fromCharCode(0x1680);
      final String punctuationSpace = String.fromCharCode(0x2008);
      final String mathSpace = String.fromCharCode(0x205F);
      final String ideographicSpace = String.fromCharCode(0x3000);
      expectWords(
        'foo${oghamSpace} ${punctuationSpace}bar',
        ['foo', '${oghamSpace} ${punctuationSpace}', 'bar'],
      );
      expectWords(
        '${mathSpace}${ideographicSpace}${oghamSpace}foo',
        ['${mathSpace}${ideographicSpace}${oghamSpace}', 'foo'],
      );
      expectWords(
        'foo${punctuationSpace}${mathSpace} ',
        ['foo', '${punctuationSpace}${mathSpace} '],
      );
      expectWords(
        '${oghamSpace} ${punctuationSpace}${mathSpace}${ideographicSpace}',
        ['${oghamSpace} ${punctuationSpace}${mathSpace}${ideographicSpace}'],
      );
    });

    test('Punctuation', () {
      expectWords('foo,bar.baz', ['foo', ',', 'bar.baz']);
      expectWords('foo_bar', ['foo_bar']);
      expectWords('foo-bar', ['foo', '-', 'bar']);
    });

    test('Numeric', () {
      expectWords('12ab ab12', ['12ab', ' ', 'ab12']);
      expectWords('ab12,34cd', ['ab12,34cd']);
      expectWords('123,456_789.0', ['123,456_789.0']);
    });

    test('Quotes', () {
      expectWords("Mike's bike", ["Mike's", ' ', 'bike']);
      expectWords("Students' grades", ['Students', "'", ' ', 'grades']);
      expectWords(
        'Joe said: "I\'m here"',
        ['Joe', ' ', 'said', ':', ' ', '"', "I\'m", ' ', 'here', '"'],
      );
    });

    // Hebrew letters have the same rules as other letters, except
    // when they are around quotes. So we need to test those rules separately.
    test('Hebrew with quotes', () {
      // A few hebrew letters:
      final String h1 = 'א';
      final String h2 = 'ל';
      final String h3 = 'ט';

      // Test the single quote behavior that should be the same as other letters.
      expectWords("$h1$h2'$h3", ["$h1$h2'$h3"]);

      // Single quote following a hebrew shouldn't break.
      expectWords("$h1$h2'", ["$h1$h2'"]);
      expectWords("$h1$h2' $h3", ["$h1$h2'", ' ', h3]);

      // Double quotes around hebrew words should break.
      expectWords('"$h1$h3"', ['"', '$h1$h3', '"']);

      // Double quotes within hebrew words shouldn't break.
      expectWords('$h3"$h2', ['$h3"$h2']);
    });

    test('Newline, CR and LF', () {
      final String newline = String.fromCharCode(0x000B);
      // The only sequence of new lines that isn't a word boundary is CR×LF.
      expectWords('foo\r\nbar', ['foo', '\r\n', 'bar']);

      // All other sequences are considered word boundaries.

      expectWords('foo\n\nbar', ['foo', '\n', '\n', 'bar']);
      expectWords('foo\r\rbar', ['foo', '\r', '\r', 'bar']);
      expectWords(
          'foo${newline}${newline}bar', ['foo', newline, newline, 'bar']);

      expectWords('foo\n\rbar', ['foo', '\n', '\r', 'bar']);
      expectWords('foo${newline}\rbar', ['foo', newline, '\r', 'bar']);
      expectWords('foo\r${newline}bar', ['foo', '\r', newline, 'bar']);
      expectWords('foo${newline}\nbar', ['foo', newline, '\n', 'bar']);
      expectWords('foo\n${newline}bar', ['foo', '\n', newline, 'bar']);
    });

    test('katakana', () {
      // Katakana letters should stick together but not with other letters.
      expectWords('ナヌ', ['ナヌ']);
      expectWords('ナabcヌ', ['ナ', 'abc', 'ヌ']);

      // Katakana sometimes behaves the same as other letters.
      expectWords('ナ,ヌ_イ', ['ナ', ',', 'ヌ_イ']);

      // Katakana sometimes behaves differently from other letters.
      expectWords('ナ.ヌ', ['ナ', '.', 'ヌ']);
      expectWords("ナ'ヌ", ['ナ', "'", 'ヌ']);
      expectWords('ナ12ヌ', ['ナ', '12', 'ヌ']);
    });
  });
}

void expectWords(String text, List<String> expectedWords) {
  int strIndex = 0;

  // Forward word break lookup.
  for (String word in expectedWords) {
    int nextBreak = WordBreaker.nextBreakIndex(text, strIndex);
    expect(nextBreak, strIndex + word.length);
    strIndex += word.length;
  }

  // Backward word break lookup.
  strIndex = text.length;
  for (String word in expectedWords.reversed) {
    int prevBreak = WordBreaker.prevBreakIndex(text, strIndex);
    expect(prevBreak, strIndex - word.length);
    strIndex -= word.length;
  }
}
