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

library quiver.async.enumerate_test;

import 'dart:async';

import 'package:quiver/src/async/enumerate.dart';
import 'package:test/test.dart';

void main() {
  group('enumerate', () {
    test('should add indices to its argument', () {
      var controller = StreamController<String>();
      var enumerated = enumerate(controller.stream);
      var expectation = enumerated.toList().then((e) {
        expect(e.map((v) => v.index), [0, 1, 2]);
        expect(e.map((v) => v.value), ['a', 'b', 'c']);
      });
      ['a', 'b', 'c'].forEach(controller.add);
      return Future.wait([controller.close(), expectation]);
    });
  });
}
