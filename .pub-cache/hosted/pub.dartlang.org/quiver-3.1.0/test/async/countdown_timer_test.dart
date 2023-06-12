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

library quiver.async.countdown_timer_test;

import 'package:quiver/src/async/countdown_timer.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/testing/time.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart';

void main() {
  group('CountdownTimer', () {
    test('should countdown', () {
      FakeAsync().run((FakeAsync async) async {
        var clock = async.getClock(DateTime.fromMillisecondsSinceEpoch(0));
        var stopwatch = FakeStopwatch(
            () => 1000 * clock.now().millisecondsSinceEpoch, 1000000);

        var timings = CountdownTimer(const Duration(milliseconds: 500),
                const Duration(milliseconds: 100),
                stopwatch: stopwatch)
            .map((c) => c.remaining.inMilliseconds);

        List<int> result = await timings.toList();
        async.elapse(aMillisecond * 500);
        expect(result, [400, 300, 200, 100, 0]);
      });
    });

    test('should set increment to the initialized value', () {
      var timer = CountdownTimer(
          const Duration(milliseconds: 321), const Duration(milliseconds: 123));
      expect(timer.increment, const Duration(milliseconds: 123));
    });
  });
}
