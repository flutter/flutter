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

library quiver.iterables.min_max_test;

import 'package:quiver/src/iterables/min_max.dart';
import 'package:test/test.dart';

void main() {
  group('max', () {
    test('should return the maximum element', () {
      expect(max([2, 5, 1, 4]), 5);
    });

    test('should return null if the iterable is empty', () {
      expect(max([]), null);
    });
  });

  group('min', () {
    test('should return the minimum element', () {
      expect(min([2, 5, 1, 4]), 1);
    });

    test('should return null if the iterable is empty', () {
      expect(min([]), null);
    });
  });

  group('extent', () {
    test('should return the max and min elements', () {
      var ext = extent([2, 5, 1, 4]);
      expect(ext.min, 1);
      expect(ext.max, 5);
    });

    test('should return the single element', () {
      var ext = extent([2]);
      expect(ext.min, 2);
      expect(ext.max, 2);
    });

    test('should return null if the iterable is empty', () {
      var ext = extent([]);
      expect(ext.min, null);
      expect(ext.max, null);
    });
  });
}
