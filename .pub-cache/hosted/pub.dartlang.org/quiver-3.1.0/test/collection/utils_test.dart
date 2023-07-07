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

library quiver.collection.utils_test;

import 'package:quiver/src/collection/utils.dart';
import 'package:test/test.dart';

void main() {
  group('listsEqual', () {
    test('return true for equal lists', () {
      expect(listsEqual(null, null), isTrue);
      expect(listsEqual([], []), isTrue);
      expect(listsEqual([1], [1]), isTrue);
      expect(listsEqual(['a', 'b'], ['a', 'b']), isTrue);
    });

    test('return false for unequal lists', () {
      expect(listsEqual(null, []), isFalse);
      expect(listsEqual([], null), isFalse);
      expect(listsEqual([1], [2]), isFalse);
      expect(listsEqual([1], []), isFalse);
      expect(listsEqual([], [1]), isFalse);
    });
  });

  group('listMap', () {
    test('return true for equal maps', () {
      expect(mapsEqual({}, {}), isTrue);
      expect(mapsEqual({'a': 1}, {'a': 1}), isTrue);
    });

    test('return false for unequal maps', () {
      expect(mapsEqual({'a': 1}, {'a': 2}), isFalse);
      expect(mapsEqual({'a': 1}, {'b': 1}), isFalse);
      expect(mapsEqual({'a': 1}, {'a': 1, 'b': 2}), isFalse);
      expect(mapsEqual({'a': 1, 'b': 2}, {'a': 1}), isFalse);
    });
  });

  group('setsEqual', () {
    test('return true for equal sets', () {
      expect(setsEqual(Set(), Set()), isTrue);
      expect(setsEqual(Set.from([1]), Set.from([1])), isTrue);
      expect(setsEqual(Set.from(['a', 'b']), Set.from(['a', 'b'])), isTrue);
    });

    test('return false for unequal sets', () {
      expect(setsEqual(Set.from([1]), Set.from([2])), isFalse);
      expect(setsEqual(Set.from([1]), Set()), isFalse);
      expect(setsEqual(Set(), Set.from([1])), isFalse);
    });
  });

  group('indexOf', () {
    test('returns the first matching index', () {
      expect(indexOf<int>([1, 12, 19, 20, 24], (n) => n % 2 == 0), 1);
      expect(indexOf<String>(['a', 'b', 'a'], (s) => s == 'a'), 0);
    });

    test('returns -1 when there is no match', () {
      expect(indexOf<int>([1, 3, 7], (n) => n % 2 == 0), -1);
      expect(indexOf<String>(['a', 'b'], (s) => s == 'e'), -1);
      expect(indexOf<bool>([], (_) => true), -1);
    });
  });
}
