// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library dart_style.test.string_compare_test;

import 'package:dart_style/src/string_compare.dart';
import 'package:test/test.dart';

void main() {
  test('whitespace at end of string', () {
    expect(equalIgnoringWhitespace('foo bar\n', 'foo bar'), isTrue);
    expect(equalIgnoringWhitespace('foo bar', 'foo bar\n'), isTrue);
    expect(equalIgnoringWhitespace('foo bar \n', 'foo bar'), isTrue);
    expect(equalIgnoringWhitespace('foo bar', 'foo bar \n'), isTrue);
  });

  test('whitespace at start of string', () {
    expect(equalIgnoringWhitespace('\nfoo bar', 'foo bar'), isTrue);
    expect(equalIgnoringWhitespace('\n foo bar', 'foo bar'), isTrue);
    expect(equalIgnoringWhitespace('foo bar', '\nfoo bar'), isTrue);
    expect(equalIgnoringWhitespace('foo bar', '\n foo bar'), isTrue);
  });

  test('whitespace in the middle of string', () {
    expect(equalIgnoringWhitespace('foobar', 'foo bar'), isTrue);
    expect(equalIgnoringWhitespace('foo bar', 'foobar'), isTrue);
    expect(equalIgnoringWhitespace('foo\tbar', 'foobar'), isTrue);
    expect(equalIgnoringWhitespace('foobar', 'foo\tbar'), isTrue);
    expect(equalIgnoringWhitespace('foo\nbar', 'foobar'), isTrue);
    expect(equalIgnoringWhitespace('foobar', 'foo\nbar'), isTrue);
  });

  test('wdentical strings', () {
    expect(equalIgnoringWhitespace('foo bar', 'foo bar'), isTrue);
    expect(equalIgnoringWhitespace('', ''), isTrue);
  });

  test('test unicode whitespace characters', () {
    // The formatter strips all Unicode whitespace characters from the end of
    // comment lines, so treat those as whitespace too.
    var whitespaceRunes = [
      0x0020,
      0x0085,
      0x00a0,
      0x2000,
      0x200a,
      0x2028,
      0x2029,
      0x202f,
      0x205f,
      0x3000,
      0xfeff
    ];
    for (var rune in whitespaceRunes) {
      expect(
          equalIgnoringWhitespace(
              'foo${String.fromCharCode(rune)}bar', 'foo    bar'),
          isTrue);
    }
  });

  test('different strings', () {
    expect(equalIgnoringWhitespace('foo bar', 'Foo bar'), isFalse);
    expect(equalIgnoringWhitespace('foo bar', 'foo bars'), isFalse);
    expect(equalIgnoringWhitespace('foo bars', 'foo bar'), isFalse);
    expect(equalIgnoringWhitespace('oo bar', 'foo bar'), isFalse);
    expect(equalIgnoringWhitespace('', 'foo bar'), isFalse);
    expect(equalIgnoringWhitespace('foo bar', ''), isFalse);
  });
}
