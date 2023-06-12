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

library quiver.iterables.cycle_test;

import 'package:quiver/src/iterables/cycle.dart';
import 'package:test/test.dart';

void main() {
  group('cycle', () {
    test('should create an empty iterable given an empty iterable', () {
      expect(cycle([]), []);
      expect(cycle([]).isEmpty, true);
      expect(cycle([]).isNotEmpty, false);
    });

    test('should cycle its argument', () {
      expect(cycle([1, 2, 3]).take(7), [1, 2, 3, 1, 2, 3, 1]);
      expect(cycle([1, 2, 3]).isEmpty, false);
      expect(cycle([1, 2, 3]).isNotEmpty, true);
    });
  });
}
