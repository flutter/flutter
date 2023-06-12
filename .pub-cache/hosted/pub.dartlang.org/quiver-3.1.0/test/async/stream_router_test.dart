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

library quiver.async.stream_router_test;

import 'dart:async';

import 'package:quiver/src/async/stream_router.dart';
import 'package:test/test.dart';

void main() {
  group('StreamRouter', () {
    test('should route an event to the correct stream', () {
      var controller = StreamController<String>();
      StreamRouter<String>(controller.stream)
        ..route((e) => e == 'foo').listen((e) {
          expect(e, 'foo');
        })
        ..route((e) => e == 'bar').listen((e) {
          fail('wrong stream');
        })
        ..route((e) => e == 'foo').listen((e) {
          fail('wrong stream');
        })
        ..defaultStream.listen((e) {
          fail('wrong stream');
        });
      controller.add('foo');
      return controller.close();
    });

    test('should send events that match no predicate to defaultStream', () {
      var controller = StreamController<String>();
      StreamRouter<String>(controller.stream)
        ..route((e) => e == 'foo').listen((e) {
          fail('wrong stream');
        })
        ..route((e) => e == 'bar').listen((e) {
          fail('wrong stream');
        })
        ..defaultStream.listen((e) {
          expect(e, 'baz');
        });
      controller.add('baz');
      return controller.close();
    });

    test('should close child streams', () {
      var controller = StreamController<int>(sync: true);
      var router = StreamRouter<int>(controller.stream);
      // toList() will only complete when the child streams are closed
      var future = Future.wait([
        router.route((e) => e % 2 == 0).toList(),
        router.route((e) => e % 2 == 1).toList(),
      ]).then((l) {
        expect(l, [
          [4],
          [5]
        ]);
      });
      controller
        ..add(4)
        ..add(5);
      router.close();
      return future;
    });
  });
}
