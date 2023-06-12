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

library quiver.iterables.enumerate_test;

import 'package:quiver/src/iterables/enumerate.dart';
import 'package:test/test.dart';

void main() {
  group('enumerate', () {
    test('should add indices to its argument', () {
      var e = enumerate(['a', 'b', 'c']);
      expect(e.map((v) => v.index), [0, 1, 2]);
      expect(e.map((v) => v.value), ['a', 'b', 'c']);
    });

    test('should return an empty iterable given an empty iterable', () {
      expect(enumerate([]), []);
    });

    test('should add indices to its argument', () {
      var e = enumerate(['a', 'b', 'c']);
      expect(e.map((v) => v.index), [0, 1, 2]);
      expect(e.map((v) => v.index), [0, 1, 2],
          reason: 'should enumerate to the same values a second time');
    });

    test('first', () {
      var e = enumerate(['a', 'b', 'c']);
      expect(e.first.value, 'a');
      expect(e.first.index, 0);
      expect(e.first.value, 'a');
    });

    test('last', () {
      var e = enumerate(['a', 'b', 'c']);
      expect(e.last.value, 'c');
      expect(e.last.index, 2);
      expect(e.last.value, 'c');
    });

    test('single', () {
      var e = enumerate(['a']);
      expect(e.single.value, 'a');
      expect(e.single.index, 0);
      expect(e.single.value, 'a');

      expect(() => enumerate([1, 2]).single, throwsStateError);
    });

    test('length', () {
      expect(enumerate([7, 8, 9]).length, 3);
    });

    test('elementAt', () {
      var list = ['a', 'b', 'c'];
      var e = enumerate(list);
      for (int i = 2; i >= 0; i--) {
        expect(e.elementAt(i).value, list[i]);
        expect(e.elementAt(i).index, i);
      }
    });

    test('equals and hashcode', () {
      var list = ['a', 'b', 'c'];
      var e1 = enumerate(list);
      var e2 = enumerate(list);
      for (int i = 0; i < 2; i++) {
        expect(e1.elementAt(i), e2.elementAt(i));
        expect(e1.elementAt(i).hashCode, e1.elementAt(i).hashCode);
        expect(identical(e1.elementAt(i), e2.elementAt(i)), isFalse);
      }
    });
  });
}
