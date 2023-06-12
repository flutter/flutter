// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.time.clock_test;

import 'package:quiver/src/async/metronome.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart';

void main() {
  group('Metronome', () {
    test('delivers events as expected', () {
      FakeAsync().run((async) {
        int callbacks = 0;

        // Initialize metronome with start time.
        DateTime lastTime = DateTime.parse('2014-05-05 20:00:30');
        var sub = Metronome.epoch(aMinute, clock: async.getClock(lastTime))
            .listen((d) {
          callbacks++;
          lastTime = d;
        });
        expect(callbacks, 0, reason: 'Should be no callbacks at start');
        async.elapse(aSecond * 15);
        expect(callbacks, 0, reason: 'Should be no callbacks before trigger');
        async.elapse(aSecond * 15);
        expect(callbacks, 1, reason: 'Calledback on rollover');
        expect(lastTime, DateTime.parse('2014-05-05 20:01:00'),
            reason: 'And that time was correct');
        async.elapse(aMinute * 1);
        expect(callbacks, 2, reason: 'Callback is repeated');
        expect(lastTime, DateTime.parse('2014-05-05 20:02:00'),
            reason: 'And that time was correct');
        sub.cancel();
        async.elapse(aMinute * 2);
        expect(callbacks, 2, reason: 'No callbacks after subscription cancel');
      });
    });

    test('can be re-listened to', () {
      FakeAsync().run((async) {
        int callbacks = 0;
        var clock = Metronome.epoch(aMinute,
            clock: async.getClock(DateTime.parse('2014-05-05 20:00:30')));
        var sub = clock.listen((d) {
          callbacks++;
        });
        async.elapse(aMinute);
        expect(callbacks, 1);
        sub.cancel();
        async.elapse(aMinute);
        expect(callbacks, 1);
        sub = clock.listen((d) {
          callbacks++;
        });
        async.elapse(aMinute);
        expect(callbacks, 2);
      });
    });

    test('supports multiple listeners joining and leaving', () {
      FakeAsync().run((async) {
        List<int> callbacks = [0, 0];
        var clock = Metronome.epoch(aMinute,
            clock: async.getClock(DateTime.parse('2014-05-05 20:00:30')));
        List subs = [
          clock.listen((d) {
            callbacks[0]++;
          }),
          clock.listen((d) {
            callbacks[1]++;
          })
        ];

        async.elapse(aMinute);
        expect(callbacks, [1, 1]);
        subs[0].cancel();
        async.elapse(aMinute);
        expect(callbacks, [1, 2]);
      });
    });

    test('can be anchored at any time', () {
      FakeAsync().run((async) {
        List<DateTime> times = [];
        DateTime start = DateTime.parse('2014-05-05 20:06:00');
        Clock clock = async.getClock(start);
        Metronome.periodic(aMinute * 10,
                clock: clock, anchor: clock.minutesAgo(59))
            .listen((d) {
          times.add(d);
        });
        async.elapse(anHour);
        expect(times, [
          DateTime.parse('2014-05-05 20:07:00'),
          DateTime.parse('2014-05-05 20:17:00'),
          DateTime.parse('2014-05-05 20:27:00'),
          DateTime.parse('2014-05-05 20:37:00'),
          DateTime.parse('2014-05-05 20:47:00'),
          DateTime.parse('2014-05-05 20:57:00'),
        ]);
      });
    });

    test('can be anchored in the future', () {
      FakeAsync().run((async) {
        List<DateTime> times = [];
        DateTime start = DateTime.parse('2014-05-05 20:06:00');
        Clock clock = async.getClock(start);
        Metronome.periodic(aMinute * 10,
                clock: clock, anchor: clock.minutesFromNow(61))
            .listen((d) {
          times.add(d);
        });
        async.elapse(anHour);
        expect(times, [
          DateTime.parse('2014-05-05 20:07:00'),
          DateTime.parse('2014-05-05 20:17:00'),
          DateTime.parse('2014-05-05 20:27:00'),
          DateTime.parse('2014-05-05 20:37:00'),
          DateTime.parse('2014-05-05 20:47:00'),
          DateTime.parse('2014-05-05 20:57:00'),
        ]);
      });
    });

    test('can be a periodic timer', () {
      FakeAsync().run((async) {
        List<DateTime> times = [];
        DateTime start = DateTime.parse('2014-05-05 20:06:00.004');
        Metronome.periodic(aMillisecond * 100,
                clock: async.getClock(start), anchor: start)
            .listen((d) {
          times.add(d);
        });
        async.elapse(aMillisecond * 304);
        expect(times, [
          DateTime.parse('2014-05-05 20:06:00.104'),
          DateTime.parse('2014-05-05 20:06:00.204'),
          DateTime.parse('2014-05-05 20:06:00.304'),
        ]);
      });
    });

    test('resyncs when workers taking some time', () {
      FakeAsync().run((async) {
        List<DateTime> times = [];
        DateTime start = DateTime.parse('2014-05-05 20:06:00.004');
        Metronome.periodic(aMillisecond * 100,
                clock: async.getClock(start), anchor: start)
            .listen((d) {
          times.add(d);
          async.elapseBlocking(const Duration(milliseconds: 80));
        });
        async.elapse(aMillisecond * 304);
        expect(times, [
          DateTime.parse('2014-05-05 20:06:00.104'),
          DateTime.parse('2014-05-05 20:06:00.204'),
          DateTime.parse('2014-05-05 20:06:00.304'),
        ]);
      });
    });

    test('drops time when workers taking longer than interval', () {
      FakeAsync().run((async) {
        List<DateTime> times = [];
        DateTime start = DateTime.parse('2014-05-05 20:06:00.004');
        Metronome.periodic(aMillisecond * 100,
                clock: async.getClock(start), anchor: start)
            .listen((d) {
          times.add(d);
          async.elapseBlocking(const Duration(milliseconds: 105));
        });
        async.elapse(aMillisecond * 504);
        expect(times, [
          DateTime.parse('2014-05-05 20:06:00.104'),
          DateTime.parse('2014-05-05 20:06:00.304'),
          DateTime.parse('2014-05-05 20:06:00.504'),
        ]);
      });
    });
  });
}
