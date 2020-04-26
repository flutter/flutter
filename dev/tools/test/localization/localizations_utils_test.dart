// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../localization/localizations_utils.dart';

import '../common.dart';

void main() {
  group('generateString', () {
    test('handles simple string', () {
      expect(generateString('abc'), "'abc'");
    });

    test('handles string with quote', () {
      expect(generateString("ab'c"), "'ab\\\'c'");
    });

    test('handles string with double quote', () {
      expect(generateString('ab"c'), "'ab\\\"c'");
    });

    test('handles string with both single and double quote', () {
      expect(generateString('''a'b"c'''), '\'a\\\'b\\"c\'');
    });

    test('handles string with a triple single quote and a double quote', () {
      expect(generateString("""a"b'''c"""), '\'a\\"b\\\'\\\'\\\'c\'');
    });

    test('handles string with a triple double quote and a single quote', () {
      expect(generateString('''a'b"""c'''), '\'a\\\'b\\"\\"\\"c\'');
    });

    test('handles string with both triple single and triple double quote', () {
      expect(generateString('''a\'''b"""c'''), '\'a\\\'\\\'\\\'b\\"\\"\\"c\'');
    });

    test('escapes dollar when escapeDollar is true', () {
      expect(generateString(r'ab$c'), "'ab\\\$c'");
    });

    test('handles backslash', () {
      expect(generateString(r'ab\c'), r"'ab\\c'");
    });

    test('handles backslash followed by "n" character', () {
      expect(generateString(r'ab\nc'), r"'ab\\nc'");
    });

    test('supports newline escaping', () {
      expect(generateString('ab\nc'), "'ab\\nc'");
    });

    test('supports form feed escaping', () {
      expect(generateString('ab\fc'), "'ab\\fc'");
    });

    test('supports tab escaping', () {
      expect(generateString('ab\tc'), "'ab\\tc'");
    });

    test('supports carriage return escaping', () {
      expect(generateString('ab\rc'), "'ab\\rc'");
    });

    test('supports backspace escaping', () {
      expect(generateString('ab\bc'), "'ab\\bc'");
    });
  });
}
