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

library quiver.iterables.concat_test;

import 'package:quiver/src/iterables/concat.dart';
import 'package:test/test.dart';

void main() {
  group('concat', () {
    test('should handle empty input iterables', () {
      expect(concat([]), isEmpty);
    });

    test('should handle single input iterables', () {
      expect(
          concat([
            [1, 2, 3]
          ]),
          [1, 2, 3]);
    });

    test('should chain multiple input iterables', () {
      expect(
          concat([
            [1, 2, 3],
            [-1, -2, -3]
          ]),
          [1, 2, 3, -1, -2, -3]);
    });

    test('should reflect changes in the inputs', () {
      var a = [1, 2];
      var b = [4, 5];
      var ab = concat([a, b]);
      expect(ab, [1, 2, 4, 5]);
      a.add(3);
      b.add(6);
      expect(ab, [1, 2, 3, 4, 5, 6]);
    });
  });
}
