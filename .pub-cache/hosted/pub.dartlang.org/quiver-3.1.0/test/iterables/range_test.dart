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

library quiver.iterables.range_test;

import 'package:quiver/src/iterables/range.dart';
import 'package:test/test.dart';

void main() {
  group('range', () {
    test('should create an empty iterator if stop is 0', () {
      expect(range(0), []);
    });

    test('should create a sequence from 0 to stop - 1', () {
      expect(range(10), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('should start sequences at start_or_stop', () {
      expect(range(1, 11), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('should create an empty iterator if start and stop are equal', () {
      expect(range(1, 1), []);
    });

    test('should step by step', () {
      expect(range(0, 10, 2), [0, 2, 4, 6, 8]);
      expect(range(0, 10, 3), [0, 3, 6, 9]);
    });

    test('should step by a negative step', () {
      expect(range(10, 0, -1), [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
      expect(range(0, -8, -1), [0, -1, -2, -3, -4, -5, -6, -7]);
      expect(range(0, -10, -3), [0, -3, -6, -9]);
    });

    test('should throw with a bad range', () {
      expect(() => range(10, 0), throwsArgumentError);
    });

    test('should throw with a bad step', () {
      expect(() => range(0, 10, -1), throwsArgumentError);
    });
  });
}
