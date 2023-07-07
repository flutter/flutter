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

library quiver.iterables.zip_test;

import 'package:quiver/src/iterables/range.dart';
import 'package:quiver/src/iterables/zip.dart';
import 'package:test/test.dart';

void main() {
  group('zip', () {
    test('should create an empty iterable if given no iterables', () {
      expect(zip([]), []);
    });

    test('should zip equal length lists', () {
      expect(
          zip([
            [1, 2, 3],
            ['a', 'b', 'c']
          ]),
          [
            [1, 'a'],
            [2, 'b'],
            [3, 'c']
          ]);
      expect(
          zip([
            [1, 2],
            ['a', 'b'],
            [2, 4]
          ]),
          [
            [1, 'a', 2],
            [2, 'b', 4]
          ]);
    });

    test('should stop at the end of the shortest iterable', () {
      expect(
          zip([
            [1, 2],
            ['a', 'b'],
            []
          ]),
          []);
      expect(zip([range(2), range(4)]), [
        [0, 0],
        [1, 1]
      ]);
    });
  });
}
