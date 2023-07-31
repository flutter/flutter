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

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  var initialTime = DateTime(2000);
  var elapseBy = Duration(days: 1);

  test('should set initial time', () {
    expect(FakeAsync().getClock(initialTime).now(), initialTime);
  });

  group('elapseBlocking', () {
    test('should elapse time without calling timers', () {
      Timer(elapseBy ~/ 2, neverCalled);
      FakeAsync().elapseBlocking(elapseBy);
    });

    test('should elapse time by the specified amount', () {
      var async = FakeAsync()..elapseBlocking(elapseBy);
      expect(async.elapsed, elapseBy);
    });

    test('should throw when called with a negative duration', () {
      expect(() => FakeAsync().elapseBlocking(Duration(days: -1)),
          throwsArgumentError);
    });
  });

  group('elapse', () {
    test('should elapse time by the specified amount', () {
      FakeAsync().run((async) {
        async.elapse(elapseBy);
        expect(async.elapsed, elapseBy);
      });
    });

    test('should throw ArgumentError when called with a negative duration', () {
      expect(() => FakeAsync().elapse(Duration(days: -1)), throwsArgumentError);
    });

    test('should throw when called before previous call is complete', () {
      FakeAsync().run((async) {
        Timer(elapseBy ~/ 2, expectAsync0(() {
          expect(() => async.elapse(elapseBy), throwsStateError);
        }));
        async.elapse(elapseBy);
      });
    });

    group('when creating timers', () {
      test('should call timers expiring before or at end time', () {
        FakeAsync().run((async) {
          Timer(elapseBy ~/ 2, expectAsync0(() {}));
          Timer(elapseBy, expectAsync0(() {}));
          async.elapse(elapseBy);
        });
      });

      test('should call timers expiring due to elapseBlocking', () {
        FakeAsync().run((async) {
          Timer(elapseBy, () => async.elapseBlocking(elapseBy));
          Timer(elapseBy * 2, expectAsync0(() {}));
          async.elapse(elapseBy);
          expect(async.elapsed, elapseBy * 2);
        });
      });

      test('should call timers at their scheduled time', () {
        FakeAsync().run((async) {
          Timer(elapseBy ~/ 2, expectAsync0(() {
            expect(async.elapsed, elapseBy ~/ 2);
          }));

          var periodicCalledAt = <Duration>[];
          Timer.periodic(
              elapseBy ~/ 2, (_) => periodicCalledAt.add(async.elapsed));

          async.elapse(elapseBy);
          expect(periodicCalledAt, [elapseBy ~/ 2, elapseBy]);
        });
      });

      test('should not call timers expiring after end time', () {
        FakeAsync().run((async) {
          Timer(elapseBy * 2, neverCalled);
          async.elapse(elapseBy);
        });
      });

      test('should not call canceled timers', () {
        FakeAsync().run((async) {
          Timer(elapseBy ~/ 2, neverCalled).cancel();
          async.elapse(elapseBy);
        });
      });

      test('should call periodic timers each time the duration elapses', () {
        FakeAsync().run((async) {
          Timer.periodic(elapseBy ~/ 10, expectAsync1((_) {}, count: 10));
          async.elapse(elapseBy);
        });
      });

      test('should call timers occurring at the same time in FIFO order', () {
        FakeAsync().run((async) {
          var log = [];
          Timer(elapseBy ~/ 2, () => log.add('1'));
          Timer(elapseBy ~/ 2, () => log.add('2'));
          async.elapse(elapseBy);
          expect(log, ['1', '2']);
        });
      });

      test('should maintain FIFO order even with periodic timers', () {
        FakeAsync().run((async) {
          var log = [];
          Timer.periodic(elapseBy ~/ 2, (_) => log.add('periodic 1'));
          Timer(elapseBy ~/ 2, () => log.add('delayed 1'));
          Timer(elapseBy, () => log.add('delayed 2'));
          Timer.periodic(elapseBy, (_) => log.add('periodic 2'));

          async.elapse(elapseBy);
          expect(log, [
            'periodic 1',
            'delayed 1',
            'periodic 1',
            'delayed 2',
            'periodic 2'
          ]);
        });
      });

      test('should process microtasks surrounding each timer', () {
        FakeAsync().run((async) {
          var microtaskCalls = 0;
          var timerCalls = 0;
          void scheduleMicrotasks() {
            for (var i = 0; i < 5; i++) {
              scheduleMicrotask(() => microtaskCalls++);
            }
          }

          scheduleMicrotasks();
          Timer.periodic(elapseBy ~/ 5, (_) {
            timerCalls++;
            expect(microtaskCalls, 5 * timerCalls);
            scheduleMicrotasks();
          });
          async.elapse(elapseBy);
          expect(timerCalls, 5);
          expect(microtaskCalls, 5 * (timerCalls + 1));
        });
      });

      test('should pass the periodic timer itself to callbacks', () {
        FakeAsync().run((async) {
          late Timer constructed;
          constructed = Timer.periodic(elapseBy, expectAsync1((passed) {
            expect(passed, same(constructed));
          }));
          async.elapse(elapseBy);
        });
      });

      test('should call microtasks before advancing time', () {
        FakeAsync().run((async) {
          scheduleMicrotask(expectAsync0(() {
            expect(async.elapsed, Duration.zero);
          }));
          async.elapse(Duration(minutes: 1));
        });
      });

      test('should add event before advancing time', () {
        FakeAsync().run((async) {
          var controller = StreamController();
          expect(controller.stream.first.then((_) {
            expect(async.elapsed, Duration.zero);
          }), completes);
          controller.add(null);
          async.elapse(Duration(minutes: 1));
        });
      });

      test('should increase negative duration timers to zero duration', () {
        FakeAsync().run((async) {
          var negativeDuration = Duration(days: -1);
          Timer(negativeDuration, expectAsync0(() {
            expect(async.elapsed, Duration.zero);
          }));
          async.elapse(Duration(minutes: 1));
        });
      });

      test('should not be additive with elapseBlocking', () {
        FakeAsync().run((async) {
          Timer(Duration.zero, () => async.elapseBlocking(elapseBy * 5));
          async.elapse(elapseBy);
          expect(async.elapsed, elapseBy * 5);
        });
      });

      group('isActive', () {
        test('should be false after timer is run', () {
          FakeAsync().run((async) {
            var timer = Timer(elapseBy ~/ 2, () {});
            async.elapse(elapseBy);
            expect(timer.isActive, isFalse);
          });
        });

        test('should be true after periodic timer is run', () {
          FakeAsync().run((async) {
            var timer = Timer.periodic(elapseBy ~/ 2, (_) {});
            async.elapse(elapseBy);
            expect(timer.isActive, isTrue);
          });
        });

        test('should be false after timer is canceled', () {
          FakeAsync().run((async) {
            var timer = Timer(elapseBy ~/ 2, () {})..cancel();
            expect(timer.isActive, isFalse);
          });
        });
      });

      test('should work with new Future()', () {
        FakeAsync().run((async) {
          Future(expectAsync0(() {}));
          async.elapse(Duration.zero);
        });
      });

      test('should work with Future.delayed', () {
        FakeAsync().run((async) {
          Future.delayed(elapseBy, expectAsync0(() {}));
          async.elapse(elapseBy);
        });
      });

      test('should work with Future.timeout', () {
        FakeAsync().run((async) {
          var completer = Completer();
          expect(completer.future.timeout(elapseBy ~/ 2),
              throwsA(TypeMatcher<TimeoutException>()));
          async.elapse(elapseBy);
          completer.complete();
        });
      });

      // TODO: Pausing and resuming the timeout Stream doesn't work since
      // it uses `new Stopwatch()`.
      //
      // See https://code.google.com/p/dart/issues/detail?id=18149
      test('should work with Stream.periodic', () {
        FakeAsync().run((async) {
          expect(Stream.periodic(Duration(minutes: 1), (i) => i),
              emitsInOrder([0, 1, 2]));
          async.elapse(Duration(minutes: 3));
        });
      });

      test('should work with Stream.timeout', () {
        FakeAsync().run((async) {
          var controller = StreamController<int>();
          var timed = controller.stream.timeout(Duration(minutes: 2));

          var events = <int>[];
          var errors = [];
          timed.listen(events.add, onError: errors.add);

          controller.add(0);
          async.elapse(Duration(minutes: 1));
          expect(events, [0]);

          async.elapse(Duration(minutes: 1));
          expect(errors, hasLength(1));
          expect(errors.first, TypeMatcher<TimeoutException>());
        });
      });
    });
  });

  group('flushMicrotasks', () {
    test('should flush a microtask', () {
      FakeAsync().run((async) {
        Future.microtask(expectAsync0(() {}));
        async.flushMicrotasks();
      });
    });

    test('should flush microtasks scheduled by microtasks in order', () {
      FakeAsync().run((async) {
        var log = [];
        scheduleMicrotask(() {
          log.add(1);
          scheduleMicrotask(() => log.add(3));
        });
        scheduleMicrotask(() => log.add(2));

        async.flushMicrotasks();
        expect(log, [1, 2, 3]);
      });
    });

    test('should not run timers', () {
      FakeAsync().run((async) {
        var log = [];
        scheduleMicrotask(() => log.add(1));
        Timer.run(() => log.add(2));
        Timer.periodic(Duration(seconds: 1), (_) => log.add(2));

        async.flushMicrotasks();
        expect(log, [1]);
      });
    });
  });

  group('flushTimers', () {
    test('should flush timers in FIFO order', () {
      FakeAsync().run((async) {
        var log = [];
        Timer.run(() {
          log.add(1);
          Timer(elapseBy, () => log.add(3));
        });
        Timer.run(() => log.add(2));

        async.flushTimers(timeout: elapseBy * 2);
        expect(log, [1, 2, 3]);
        expect(async.elapsed, elapseBy);
      });
    });

    test(
        'should run collateral periodic timers with non-periodic first if '
        'scheduled first', () {
      FakeAsync().run((async) {
        var log = [];
        Timer(Duration(seconds: 2), () => log.add('delayed'));
        Timer.periodic(Duration(seconds: 1), (_) => log.add('periodic'));

        async.flushTimers(flushPeriodicTimers: false);
        expect(log, ['periodic', 'delayed', 'periodic']);
      });
    });

    test(
        'should run collateral periodic timers with periodic first '
        'if scheduled first', () {
      FakeAsync().run((async) {
        var log = [];
        Timer.periodic(Duration(seconds: 1), (_) => log.add('periodic'));
        Timer(Duration(seconds: 2), () => log.add('delayed'));

        async.flushTimers(flushPeriodicTimers: false);
        expect(log, ['periodic', 'periodic', 'delayed']);
      });
    });

    test('should time out', () {
      FakeAsync().run((async) {
        // Schedule 3 timers. All but the last one should fire.
        for (var delay in [30, 60, 90]) {
          Timer(Duration(minutes: delay),
              expectAsync0(() {}, count: delay == 90 ? 0 : 1));
        }

        expect(() => async.flushTimers(), throwsStateError);
      });
    });

    test('should time out a chain of timers', () {
      FakeAsync().run((async) {
        var count = 0;
        void createTimer() {
          Timer(Duration(minutes: 30), () {
            count++;
            createTimer();
          });
        }

        createTimer();
        expect(() => async.flushTimers(timeout: Duration(hours: 2)),
            throwsStateError);
        expect(count, 4);
      });
    });

    test('should time out periodic timers', () {
      FakeAsync().run((async) {
        Timer.periodic(Duration(minutes: 30), expectAsync1((_) {}, count: 2));
        expect(() => async.flushTimers(timeout: Duration(hours: 1)),
            throwsStateError);
      });
    });

    test('should flush periodic timers', () {
      FakeAsync().run((async) {
        var count = 0;
        Timer.periodic(Duration(minutes: 30), (timer) {
          if (count == 3) timer.cancel();
          count++;
        });
        async.flushTimers(timeout: Duration(hours: 20));
        expect(count, 4);
      });
    });

    test('should compute absolute timeout as elapsed + timeout', () {
      FakeAsync().run((async) {
        var count = 0;
        void createTimer() {
          Timer(Duration(minutes: 30), () {
            count++;
            if (count < 4) createTimer();
          });
        }

        createTimer();
        async
          ..elapse(Duration(hours: 1))
          ..flushTimers(timeout: Duration(hours: 1));
        expect(count, 4);
      });
    });
  });

  group('stats', () {
    test('should report the number of pending microtasks', () {
      FakeAsync().run((async) {
        expect(async.microtaskCount, 0);
        scheduleMicrotask(() {});
        expect(async.microtaskCount, 1);
        scheduleMicrotask(() {});
        expect(async.microtaskCount, 2);
        async.flushMicrotasks();
        expect(async.microtaskCount, 0);
      });
    });

    test('it should report the number of pending periodic timers', () {
      FakeAsync().run((async) {
        expect(async.periodicTimerCount, 0);
        var timer = Timer.periodic(Duration(minutes: 30), (_) {});
        expect(async.periodicTimerCount, 1);
        Timer.periodic(Duration(minutes: 20), (_) {});
        expect(async.periodicTimerCount, 2);
        async.elapse(Duration(minutes: 20));
        expect(async.periodicTimerCount, 2);
        timer.cancel();
        expect(async.periodicTimerCount, 1);
      });
    });

    test('it should report the number of pending non periodic timers', () {
      FakeAsync().run((async) {
        expect(async.nonPeriodicTimerCount, 0);
        var timer = Timer(Duration(minutes: 30), () {});
        expect(async.nonPeriodicTimerCount, 1);
        Timer(Duration(minutes: 20), () {});
        expect(async.nonPeriodicTimerCount, 2);
        async.elapse(Duration(minutes: 25));
        expect(async.nonPeriodicTimerCount, 1);
        timer.cancel();
        expect(async.nonPeriodicTimerCount, 0);
      });
    });

    test('should report debugging information of pending timers', () {
      FakeAsync().run((fakeAsync) {
        expect(fakeAsync.pendingTimers, isEmpty);
        var nonPeriodic = Timer(const Duration(seconds: 1), () {}) as FakeTimer;
        var periodic =
            Timer.periodic(const Duration(seconds: 2), (Timer timer) {})
                as FakeTimer;
        final debugInfo = fakeAsync.pendingTimers;
        expect(debugInfo.length, 2);
        expect(
          debugInfo,
          containsAll([
            nonPeriodic,
            periodic,
          ]),
        );

        const thisFileName = 'fake_async_test.dart';
        expect(nonPeriodic.debugString, contains(':01.0'));
        expect(nonPeriodic.debugString, contains('periodic: false'));
        expect(nonPeriodic.debugString, contains(thisFileName));
        expect(periodic.debugString, contains(':02.0'));
        expect(periodic.debugString, contains('periodic: true'));
        expect(periodic.debugString, contains(thisFileName));
      });
    });

    test(
        'should report debugging information of pending timers excluding '
        'stack traces', () {
      FakeAsync(includeTimerStackTrace: false).run((fakeAsync) {
        expect(fakeAsync.pendingTimers, isEmpty);
        var nonPeriodic = Timer(const Duration(seconds: 1), () {}) as FakeTimer;
        var periodic =
            Timer.periodic(const Duration(seconds: 2), (Timer timer) {})
                as FakeTimer;
        final debugInfo = fakeAsync.pendingTimers;
        expect(debugInfo.length, 2);
        expect(
          debugInfo,
          containsAll([
            nonPeriodic,
            periodic,
          ]),
        );

        const thisFileName = 'fake_async_test.dart';
        expect(nonPeriodic.debugString, contains(':01.0'));
        expect(nonPeriodic.debugString, contains('periodic: false'));
        expect(nonPeriodic.debugString, isNot(contains(thisFileName)));
        expect(periodic.debugString, contains(':02.0'));
        expect(periodic.debugString, contains('periodic: true'));
        expect(periodic.debugString, isNot(contains(thisFileName)));
      });
    });
  });

  group('timers', () {
    test("should become inactive as soon as they're invoked", () {
      return FakeAsync().run((async) {
        late Timer timer;
        timer = Timer(elapseBy, expectAsync0(() {
          expect(timer.isActive, isFalse);
        }));

        expect(timer.isActive, isTrue);
        async.elapse(elapseBy);
        expect(timer.isActive, isFalse);
      });
    });

    test('should increment tick in a non-periodic timer', () {
      return FakeAsync().run((async) {
        late Timer timer;
        timer = Timer(elapseBy, expectAsync0(() {
          expect(timer.tick, 1);
        }));

        expect(timer.tick, 0);
        async.elapse(elapseBy);
      });
    });

    test('should increment tick in a periodic timer', () {
      return FakeAsync().run((async) {
        final ticks = [];
        Timer.periodic(
            elapseBy,
            expectAsync1((timer) {
              ticks.add(timer.tick);
            }, count: 2));
        async
          ..elapse(elapseBy)
          ..elapse(elapseBy);
        expect(ticks, [1, 2]);
      });
    });
  });

  group('clock', () {
    test('updates following elapse()', () {
      FakeAsync().run((async) {
        var before = clock.now();
        async.elapse(elapseBy);
        expect(clock.now(), before.add(elapseBy));
      });
    });

    test('updates following elapseBlocking()', () {
      FakeAsync().run((async) {
        var before = clock.now();
        async.elapseBlocking(elapseBy);
        expect(clock.now(), before.add(elapseBy));
      });
    });

    group('starts at', () {
      test('the time at which the FakeAsync was created', () {
        var start = DateTime.now();
        FakeAsync().run((async) {
          expect(clock.now(), _closeToTime(start));
          async.elapse(elapseBy);
          expect(clock.now(), _closeToTime(start.add(elapseBy)));
        });
      });

      test('the value of clock.now()', () {
        var start = DateTime(1990, 8, 11);
        withClock(Clock.fixed(start), () {
          FakeAsync().run((async) {
            expect(clock.now(), start);
            async.elapse(elapseBy);
            expect(clock.now(), start.add(elapseBy));
          });
        });
      });

      test('an explicit value', () {
        var start = DateTime(1990, 8, 11);
        FakeAsync(initialTime: start).run((async) {
          expect(clock.now(), start);
          async.elapse(elapseBy);
          expect(clock.now(), start.add(elapseBy));
        });
      });
    });
  });
}

/// Returns a matcher that asserts that a [DateTime] is within 100ms of
/// [expected].
Matcher _closeToTime(DateTime expected) => predicate(
    (actual) =>
        expected.difference(actual as DateTime).inMilliseconds.abs() < 100,
    'is close to $expected');
