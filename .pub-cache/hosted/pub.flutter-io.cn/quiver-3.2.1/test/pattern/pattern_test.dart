// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.pattern_test;

import 'package:quiver/pattern.dart';
import 'package:test/test.dart';

const _specialChars = r'\^$.|+[](){}';

void main() {
  group('escapeRegex', () {
    test('should escape special characters', () {
      for (final c in _specialChars.split('')) {
        expect(escapeRegex(c), '\\$c');
      }
    });
  });

  group('matchesAny', () {
    test('should match multiple include patterns', () {
      expectMatch(matchAny(['a', 'b']), 'a', 0, ['a']);
      expectMatch(matchAny(['a', 'b']), 'b', 0, ['b']);
    });

    test('should match multiple include patterns (non-zero start)', () {
      expectMatch(matchAny(['a', 'b']), 'ba', 1, ['a']);
      expectMatch(matchAny(['a', 'b']), 'aab', 2, ['b']);
    });

    test('should return multiple matches', () {
      expectMatch(matchAny(['a', 'b']), 'ab', 0, ['a', 'b']);
    });

    test('should return multiple matches (non-zero start)', () {
      expectMatch(matchAny(['a', 'b', 'c']), 'cab', 1, ['a', 'b']);
    });

    test('should exclude', () {
      expectMatch(
          matchAny(['foo', 'bar'], exclude: ['foobar']), 'foobar', 0, []);
    });

    test('should exclude (non-zero start)', () {
      expectMatch(
          matchAny(['foo', 'bar'], exclude: ['foobar']), 'xyfoobar', 2, []);
    });
  });

  group('matchesFull', () {
    test('should match a string', () {
      expect(matchesFull('abcd', 'abcd'), true);
      expect(matchesFull(RegExp('a.*d'), 'abcd'), true);
    });

    test('should return false for a partial match', () {
      expect(matchesFull('abc', 'abcd'), false);
      expect(matchesFull('bcd', 'abcd'), false);
      expect(matchesFull(RegExp('a.*c'), 'abcd'), false);
      expect(matchesFull(RegExp('b.*d'), 'abcd'), false);
    });
  });
}

void expectMatch(Pattern pattern, String str, int start, List<String> matches) {
  var actual = pattern.allMatches(str, start).map((m) => m.group(0)).toList();
  expect(actual, matches);
}
