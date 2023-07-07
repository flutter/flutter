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

library quiver.async.concat_test;

import 'dart:async';

import 'package:quiver/src/async/concat.dart';
import 'package:test/test.dart';

void main() {
  group('concat', () {
    test('should produce no events for no streams',
        () => concat([]).toList().then((events) => expect(events, isEmpty)));

    test('should echo events of a single stream', () {
      var controller = StreamController<String>();
      var concatenated = concat([controller.stream]);
      var expectation = concatenated.toList().then((e) {
        expect(e, ['a', 'b', 'c']);
      });
      ['a', 'b', 'c'].forEach(controller.add);
      return Future.wait([controller.close(), expectation]);
    });

    test('should handle empty streams', () {
      var concatenated = concat([Stream.fromIterable([])]);
      return concatenated.toList().then((e) {
        expect(e, []);
      });
    });

    test('should concatenate stream data events', () {
      var controller1 = StreamController<String>();
      var controller2 = StreamController<String>();
      var concatenated = concat([controller1.stream, controller2.stream]);
      var expectation = concatenated.toList().then((e) {
        expect(e, ['a', 'b', 'c', 'd', 'e', 'f']);
      });
      ['a', 'b', 'c'].forEach(controller1.add);
      ['d', 'e', 'f'].forEach(controller2.add);
      return Future.wait(
          [controller1.close(), controller2.close(), expectation]);
    });

    test('should concatenate stream error events', () {
      var controller1 = StreamController<String>();
      var controller2 = StreamController<String>();
      var concatenated = concat([controller1.stream, controller2.stream]);
      var errors = [];
      concatenated.listen(null, onError: errors.add);
      ['e1', 'e2'].forEach(controller1.addError);
      ['e3', 'e4'].forEach(controller2.addError);
      return Future.wait([controller1.close(), controller2.close()]).then((_) {
        expect(errors, ['e1', 'e2', 'e3', 'e4']);
      });
    });

    test('should forward pause, resume, and cancel to current stream', () {
      var wasPaused = false, wasResumed = false, wasCanceled = false;
      var controller = StreamController<String>(
          onPause: () => wasPaused = true,
          onResume: () => wasResumed = true,
          onCancel: () {
            wasCanceled = true;
          });
      var concatenated = concat([controller.stream]);
      var subscription = concatenated.listen(null);
      controller.add('a');
      return Future.value()
          .then((_) => subscription.pause())
          .then((_) => subscription.resume())

          // Give resume a chance to take effect.
          .then((_) => controller.add('b'))
          .then((_) => Future(subscription.cancel))
          .then((_) {
        expect(wasPaused, isTrue, reason: 'was not paused');
        expect(wasResumed, isTrue, reason: 'was not resumed');
        expect(wasCanceled, isTrue, reason: 'was not canceled');
      }).then((_) => controller.close());
    });

    test('should forward iteration error and stop', () {
      var data = [], errors = [];
      var badIteration =
          ['e', 'this should not get thrown'].map((message) => throw message);
      var concatenated = concat(badIteration);
      var completer = Completer();
      concatenated.listen(data.add,
          onError: errors.add, onDone: completer.complete);
      return completer.future.then((_) {
        expect(data, []);
        expect(errors, ['e']);
      });
    });
  });
}
