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

library quiver.async.collect_test;

import 'dart:async';
import 'dart:math';

import 'package:quiver/src/async/collect.dart';
import 'package:test/test.dart';

void main() {
  group('collect', () {
    test('should produce no events for no futures',
        () => collect([]).toList().then((events) => expect(events, isEmpty)));

    test('should produce events for future completions in input order', () {
      var futures = Iterable<Future>.generate(
          5, (int i) => i.isEven ? Future.value(i) : Future.error(i));
      var events = [];
      var done = Completer<List<dynamic>>();

      collect(futures).listen(events.add,
          onError: (i) {
            events.add('e$i');
          },
          onDone: () => done.complete([]));
      return Future.wait(futures).catchError((_) => done.future).then((_) {
        expect(events, [0, 'e1', 2, 'e3', 4]);
      });
    });

    test(
        'should only advance iterator once '
        'event for previous future is sent', () {
      var eventCount = 0;
      var maxParallel = 0;
      var currentParallel = 0;
      var done = Completer();
      var futures = Iterable.generate(3, (_) {
        maxParallel = max(++currentParallel, maxParallel);
        return Future.value();
      });

      var collected = collect(futures);

      void decrementParallel(_) {
        eventCount++;
        currentParallel--;
      }

      collected.listen(decrementParallel,
          onError: decrementParallel, onDone: done.complete);
      return done.future.then((_) {
        expect(maxParallel, 1);
        expect(eventCount, 3);
      });
    });
  });
}
