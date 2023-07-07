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

library quiver.iterables.merge_test;

import 'package:quiver/src/iterables/merge.dart';
import 'package:quiver/src/iterables/min_max.dart';
import 'package:test/test.dart';

void main() {
  group('merge', () {
    test('should merge no iterables into empty iterable', () {
      expect(merge([]), []);
    });

    test('should merge empty iterables into empty iterable', () {
      expect(merge([[]]), []);
      expect(merge([[], []]), []);
      expect(merge([[], [], []]), []);
      for (int i = 4; i <= 10; i++) {
        expect(merge(List.filled(i, const [])), []);
      }
    });

    test('should merge single-element iterables', () {
      expect(
          merge([
            ['a'],
            ['b']
          ]),
          ['a', 'b']);
    });

    test('should output the union of elements in both iterables', () {
      var a = ['a', 'b', 'c'];
      expect(merge([a, a]), ['a', 'a', 'b', 'b', 'c', 'c']);
    });

    test('should honor the comparator', () {
      var a = ['c', 'b', 'a'];
      expect(merge([a, a], (String x, String y) => -x.compareTo(y)),
          ['c', 'c', 'b', 'b', 'a', 'a']);
    });

    test('should merge empty iterables with non-empty ones', () {
      var a = ['a', 'b', 'c'];
      expect(merge([a, <String>[]]), ['a', 'b', 'c']);
      expect(merge([<String>[], a]), ['a', 'b', 'c']);
    });

    test('should handle zig-zag case', () {
      var a = ['a', 'a', 'd', 'f'];
      var b = ['b', 'c', 'g', 'g'];
      expect(merge([a, b]), ['a', 'a', 'b', 'c', 'd', 'f', 'g', 'g']);
    });

    test('should handle max(a) < min(b) case', () {
      var a = <String>['a', 'b'];
      var b = <String>['c', 'd'];
      expect(max(a)!.compareTo(min(b)!) < 0, isTrue); // test the test
      expect(merge([a, b]), ['a', 'b', 'c', 'd']);
    });

    test('should handle three-way zig-zag case', () {
      var a = ['a', 'd', 'g', 'j'];
      var b = ['b', 'e', 'h', 'k'];
      var c = ['c', 'f', 'i', 'l'];
      var expected = [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l'
      ];
      expect(merge([a, b, c]), expected);
      expect(merge([a, c, b]), expected);
      expect(merge([b, a, c]), expected);
      expect(merge([b, c, a]), expected);
      expect(merge([c, a, b]), expected);
      expect(merge([c, b, a]), expected);
    });
  });
}
