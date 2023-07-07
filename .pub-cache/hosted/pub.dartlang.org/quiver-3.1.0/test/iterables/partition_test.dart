// Copyright 2014 Google Inc. All Rights Reserved.
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

library quiver.iterables.partition_test;

import 'package:quiver/src/iterables/partition.dart';
import 'package:test/test.dart';

void main() {
  group('partition', () {
    test('should throw when size is <= 0', () {
      expect(() => partition([1, 2, 3], 0), throwsArgumentError);
      expect(() => partition([1, 2, 3], -1), throwsArgumentError);
    });

    test('should return an empty list for empty input iterable', () {
      expect(partition([], 5), equals([]));
    });

    test('should return one partition if partition size < input size', () {
      var it = partition([1, 2, 3], 5).iterator;
      expect(it.moveNext(), isTrue);
      expect(it.current, equals([1, 2, 3]));
      expect(it.moveNext(), isFalse);
      expect(() => it.current, throwsError);
    });

    test('should return one partition if partition size == input size', () {
      var it = partition([1, 2, 3, 4, 5], 5).iterator;
      expect(it.moveNext(), isTrue);
      expect(it.current, equals([1, 2, 3, 4, 5]));
      expect(it.moveNext(), isFalse);
      expect(() => it.current, throwsError);
    });

    test(
        'should return partitions of correct size if '
        'partition size > input size', () {
      var it = partition([1, 2, 3, 4, 5], 3).iterator;
      expect(it.moveNext(), isTrue);
      expect(it.current, equals([1, 2, 3]));
      expect(it.moveNext(), isTrue);
      expect(it.current, equals([4, 5]));
      expect(it.moveNext(), isFalse);
      expect(() => it.current, throwsError);
    });
  });
}

final throwsError = throwsA(const TypeMatcher<Error>());
