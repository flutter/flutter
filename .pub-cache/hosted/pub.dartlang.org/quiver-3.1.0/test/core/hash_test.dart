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

library quiver.core.hash_test;

import 'package:quiver/src/core/hash.dart';
import 'package:test/test.dart';

void main() {
  test('hashObjects should return an int', () {
    int h = hashObjects(['123', 456]);
    expect(h, isA<int>());
  });

  test('hashObjects should handle null', () {
    int h = hashObjects(['123', null]);
    expect(h, isA<int>());
  });

  test('hashObjects should handle all objects being null', () {
    int h = hashObjects([null, null]);
    expect(h, isA<int>());
  });

  test('hash2 should return an int', () {
    int h = hash2('123', 456);
    expect(h, isA<int>());
  });

  test('hash3 should return an int', () {
    int h = hash3('123', 456, true);
    expect(h, isA<int>());
  });

  test('hash4 should return an int', () {
    int h = hash4('123', 456, true, []);
    expect(h, isA<int>());
  });
}
