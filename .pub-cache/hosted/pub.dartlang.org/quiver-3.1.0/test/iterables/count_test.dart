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

library quiver.iterables.count_test;

import 'package:quiver/src/iterables/count.dart';
import 'package:test/test.dart';

void main() {
  group('count', () {
    test('should create an infinite sequence starting at 0 given no args', () {
      expect(count().first, 0);
      expect(count().take(5), [0, 1, 2, 3, 4]);
    });

    test('should create an infinite sequence starting from start', () {
      expect(count(3).first, 3);
      expect(count(3).take(5), [3, 4, 5, 6, 7]);
    });

    test('should create an infinite sequence stepping by step', () {
      expect(count(3, 2).first, 3);
      expect(count(3, 2).take(5), [3, 5, 7, 9, 11]);
      expect(count(3.5, 2).first, 3.5);
      expect(count(3.5, .5).take(5), [3.5, 4, 4.5, 5, 5.5]);
    });
  });
}
