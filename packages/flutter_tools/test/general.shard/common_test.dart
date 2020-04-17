// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../src/common.dart';

void main() {
  final Map<dynamic, dynamic> stubMatchState = <dynamic, dynamic>{};
  group('containsIgnoreWhitespace Matcher', () {
    group('on item to be contained', () {
      test('matches simple case.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any text!');
        final bool result =
            testMatcher.matches('Give me any text!', stubMatchState);
        expect(result, true);
      });

      test("shouldn't match when it's only because of removing whitespaces", () {
        final Matcher testMatcher = containsIgnoringWhitespace('any text!');
        final bool result =
            testMatcher.matches('Give me anytext!', stubMatchState);
        expect(result, false);
      });

      test('ignores trailing spaces.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any text!    ');
        final bool result =
            testMatcher.matches('Give me any text!', stubMatchState);
        expect(result, true);
      });

      test('ignores leading spaces.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('   any text!');
        final bool result =
            testMatcher.matches('Give me any text!', stubMatchState);
        expect(result, true);
      });

      test('ignores linebreaks.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any\n text!');
        final bool result =
            testMatcher.matches('Give me any text!', stubMatchState);
        expect(result, true);
      });

      test('ignores tabs.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any\t text!');
        final bool result =
            testMatcher.matches('Give me any text!', stubMatchState);
        expect(result, true);
      });

      test('is case sensitive.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any text!');
        final bool result =
            testMatcher.matches('Give me Any text!', stubMatchState);
        expect(result, false);
      });
    });

    group('on value to match against', () {

      test('ignores trailing spaces.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any value to include!');
        final bool result =
            testMatcher.matches('Give  me  any value to include!   ', stubMatchState);
        expect(result, true);
      });

      test('ignores leading spaces.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any value to include!');
        final bool result =
            testMatcher.matches('     Give me    any value to include!', stubMatchState);
        expect(result, true);
      });

      test('ignores linebreaks.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any value to include!');
        final bool result =
            testMatcher.matches('Give me \n any \n value \n to \n include!', stubMatchState);
        expect(result, true);
      });

      test('ignores tabs.', () {
        final Matcher testMatcher = containsIgnoringWhitespace('any value to include!');
        final bool result =
            testMatcher.matches('\tGive\t me any\t value \t to \t include!', stubMatchState);
        expect(result, true);
      });
    });
  });
}
