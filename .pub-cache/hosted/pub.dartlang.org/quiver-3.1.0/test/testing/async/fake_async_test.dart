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

library quiver.testing.async.fake_async_test;

import 'dart:async';

import 'package:quiver/testing/src/async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAsync', () {
    var initialTime = DateTime(2000);
    var elapseBy = const Duration(days: 1);

    test('should set initial time', () {
      expect(FakeAsync().getClock(initialTime).now(), initialTime);
    });

    group('elapseBlocking', () {
      test('should elapse time without calling timers', () {
        var timerCalled = false;
        var timer = Timer(elapseBy ~/ 2, () => timerCalled = true);
        FakeAsync().elapseBlocking(elapseBy);
        expect(timerCalled, isFalse);
        timer.cancel();
      });

      test('should elapse time by the specified amount', () {
        var it = FakeAsync();
        it.elapseBlocking(elapseBy);
        expect(it.getClock(initialTime).now(), initialTime.add(elapseBy));
      });

      test('should throw when called with a negative duration', () {
        expect(() {
          FakeAsync().elapseBlocking(const Duration(days: -1));
        }, throwsA(isA<ArgumentError>()));
      });
    });

    group('elapse', () {
      test('should elapse time by the specified amount', () {
        FakeAsync().run((async) {
          async.elapse(elapseBy);
          expect(async.getClock(initialTime).now(), initialTime.add(elapseBy));
        });
      });

      test('should throw ArgumentError when called with a negative duration',
          () {
        expect(() => FakeAsync().elapse(const Duration(days: -1)),
            throwsA(isA<ArgumentError>()));
      });

      test('should throw when called before previous call is complete', () {
        FakeAsync().run((async) {
          dynamic error;
          Timer(elapseBy ~/ 2, () {
            try {
              async.elapse(elapseBy);
            } catch (e) {
              error = e;
            }
          });
          async.elapse(elapseBy);
          expect(error, isA<StateError>());
        });
      });

      group('when creating timers', () {
        test('should call timers expiring before or at end time', () {
          FakeAsync().run((async) {
            var beforeCallCount = 0;
            var atCallCount = 0;
            Timer(elapseBy ~/ 2, () {
              beforeCallCount++;
            });
            Timer(elapseBy, () {
              atCallCount++;
            });
            async.elapse(elapseBy);
            expect(beforeCallCount, 1);
            expect(atCallCount, 1);
          });
        });

        test('should call timers expiring due to elapseBlocking', () {
          FakeAsync().run((async) {
            bool secondaryCalled = false;
            Timer(elapseBy, () {
              async.elapseBlocking(elapseBy);
            });
            Timer(elapseBy * 2, () {
              secondaryCalled = true;
            });
            async.elapse(elapseBy);
            expect(secondaryCalled, isTrue);
            expect(async.getClock(initialTime).now(),
                initialTime.add(elapseBy * 2));
          });
        });

        test('should call timers at their scheduled time', () {
          FakeAsync().run((async) {
            DateTime? calledAt;
            var periodicCalledAt = <DateTime>[];
            Timer(elapseBy ~/ 2, () {
              calledAt = async.getClock(initialTime).now();
            });
            Timer.periodic(elapseBy ~/ 2, (_) {
              periodicCalledAt.add(async.getClock(initialTime).now());
            });
            async.elapse(elapseBy);
            expect(calledAt, initialTime.add(elapseBy ~/ 2));
            expect(periodicCalledAt,
                [elapseBy ~/ 2, elapseBy].map(initialTime.add));
          });
        });

        test('should not call timers expiring after end time', () {
          FakeAsync().run((async) {
            var timerCallCount = 0;
            Timer(elapseBy * 2, () {
              timerCallCount++;
            });
            async.elapse(elapseBy);
            expect(timerCallCount, 0);
          });
        });

        test('should not call canceled timers', () {
          FakeAsync().run((async) {
            int timerCallCount = 0;
            var timer = Timer(elapseBy ~/ 2, () {
              timerCallCount++;
            });
            timer.cancel();
            async.elapse(elapseBy);
            expect(timerCallCount, 0);
          });
        });

        test('should call periodic timers each time the duration elapses', () {
          FakeAsync().run((async) {
            var periodicCallCount = 0;
            Timer.periodic(elapseBy ~/ 10, (_) {
              periodicCallCount++;
            });
            async.elapse(elapseBy);
            expect(periodicCallCount, 10);
          });
        });

        test('should call timers occurring at the same time in FIFO order', () {
          FakeAsync().run((async) {
            var log = [];
            Timer(elapseBy ~/ 2, () {
              log.add('1');
            });
            Timer(elapseBy ~/ 2, () {
              log.add('2');
            });
            async.elapse(elapseBy);
            expect(log, ['1', '2']);
          });
        });

        test('should maintain FIFO order even with periodic timers', () {
          FakeAsync().run((async) {
            var log = [];
            Timer.periodic(elapseBy ~/ 2, (_) {
              log.add('periodic 1');
            });
            Timer(elapseBy ~/ 2, () {
              log.add('delayed 1');
            });
            Timer(elapseBy, () {
              log.add('delayed 2');
            });
            Timer.periodic(elapseBy, (_) {
              log.add('periodic 2');
            });
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
              for (int i = 0; i < 5; i++) {
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
            Timer? passedTimer;
            Timer periodic = Timer.periodic(elapseBy, (timer) {
              passedTimer = timer;
            });
            async.elapse(elapseBy);
            expect(periodic, same(passedTimer));
          });
        });

        test('should call microtasks before advancing time', () {
          FakeAsync().run((async) {
            DateTime? calledAt;
            scheduleMicrotask(() {
              calledAt = async.getClock(initialTime).now();
            });
            async.elapse(const Duration(minutes: 1));
            expect(calledAt, initialTime);
          });
        });

        test('should add event before advancing time', () {
          return Future(() => FakeAsync().run((async) {
                var controller = StreamController();
                var ret = controller.stream.first.then((_) {
                  expect(async.getClock(initialTime).now(), initialTime);
                });
                controller.add(null);
                async.elapse(const Duration(minutes: 1));
                return ret;
              }));
        });

        test('should increase negative duration timers to zero duration', () {
          FakeAsync().run((async) {
            var negativeDuration = const Duration(days: -1);
            DateTime? calledAt;
            Timer(negativeDuration, () {
              calledAt = async.getClock(initialTime).now();
            });
            async.elapse(const Duration(minutes: 1));
            expect(calledAt, initialTime);
          });
        });

        test('should not be additive with elapseBlocking', () {
          FakeAsync().run((async) {
            Timer(Duration.zero, () => async.elapseBlocking(elapseBy * 5));
            async.elapse(elapseBy);
            expect(async.getClock(initialTime).now(),
                initialTime.add(elapseBy * 5));
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
              var timer = Timer(elapseBy ~/ 2, () {});
              timer.cancel();
              expect(timer.isActive, isFalse);
            });
          });
        });

        test('should work with new Future()', () {
          FakeAsync().run((async) {
            var callCount = 0;
            Future(() => callCount++);
            async.elapse(Duration.zero);
            expect(callCount, 1);
          });
        });

        test('should work with Future.delayed', () {
          FakeAsync().run((async) {
            int? result;
            Future.delayed(elapseBy, () => result = 5);
            async.elapse(elapseBy);
            expect(result, 5);
          });
        });

        test('should work with Future.timeout', () {
          FakeAsync().run((async) {
            var completer = Completer();
            TimeoutException? timeout;
            completer.future.timeout(elapseBy ~/ 2).catchError((err) {
              timeout = err;
            });
            async.elapse(elapseBy);
            expect(timeout, isA<TimeoutException>());
            completer.complete();
          });
        });

        // TODO(yjbanov): Pausing and resuming the timeout Stream doesn't work
        // since it uses `Stopwatch()`.
        //
        // See https://github.com/dart-lang/sdk/issues/18149
        test('should work with Stream.periodic', () {
          FakeAsync().run((async) {
            var events = <int>[];
            StreamSubscription subscription;
            var periodic =
                Stream.periodic(const Duration(minutes: 1), (i) => i);
            subscription = periodic.listen(events.add);
            async.elapse(const Duration(minutes: 3));
            expect(events, [0, 1, 2]);
            subscription.cancel();
          });
        });

        test('should work with Stream.timeout', () {
          FakeAsync().run((async) {
            var events = <int>[];
            var errors = [];
            var controller = StreamController<int>();
            var timed = controller.stream.timeout(const Duration(minutes: 2));
            var subscription = timed.listen(events.add, onError: errors.add);
            controller.add(0);
            async.elapse(const Duration(minutes: 1));
            expect(events, [0]);
            async.elapse(const Duration(minutes: 1));
            expect(errors, hasLength(1));
            expect(errors.first, isA<TimeoutException>());
            subscription.cancel();
            controller.close();
          });
        });
      });
    });

    group('flushMicrotasks', () {
      test('should flush a microtask', () {
        FakeAsync().run((async) {
          bool microtaskRan = false;
          Future.microtask(() {
            microtaskRan = true;
          });
          expect(microtaskRan, isFalse,
              reason: 'should not flush until asked to');
          async.flushMicrotasks();
          expect(microtaskRan, isTrue);
        });
      });
      test('should flush microtasks scheduled by microtasks in order', () {
        FakeAsync().run((async) {
          final log = [];
          Future.microtask(() {
            log.add(1);
            Future.microtask(() {
              log.add(3);
            });
          });
          Future.microtask(() {
            log.add(2);
          });
          expect(log, hasLength(0), reason: 'should not flush until asked to');
          async.flushMicrotasks();
          expect(log, [1, 2, 3]);
        });
      });
      test('should not run timers', () {
        FakeAsync().run((async) {
          final log = [];
          Future.microtask(() {
            log.add(1);
          });
          Future(() {
            log.add(2);
          });
          Timer.periodic(const Duration(seconds: 1), (_) {
            log.add(2);
          });
          async.flushMicrotasks();
          expect(log, [1]);
        });
      });
    });

    group('flushTimers', () {
      test('should flush timers in FIFO order', () {
        FakeAsync().run((async) {
          final log = [];
          Future(() {
            log.add(1);
            Future.delayed(elapseBy, () {
              log.add(3);
            });
          });
          Future(() {
            log.add(2);
          });
          expect(log, hasLength(0), reason: 'should not flush until asked to');
          async.flushTimers(timeout: elapseBy * 2, flushPeriodicTimers: false);
          expect(log, [1, 2, 3]);
          expect(async.getClock(initialTime).now(), initialTime.add(elapseBy));
        });
      });

      test(
          'should run collateral periodic timers with non-periodic first if '
          'scheduled first', () {
        FakeAsync().run((async) {
          final log = [];
          Future.delayed(const Duration(seconds: 2), () {
            log.add('delayed');
          });
          Timer.periodic(const Duration(seconds: 1), (_) {
            log.add('periodic');
          });
          expect(log, hasLength(0), reason: 'should not flush until asked to');
          async.flushTimers(flushPeriodicTimers: false);
          expect(log, ['periodic', 'delayed', 'periodic']);
        });
      });

      test(
          'should run collateral periodic timers with periodic first '
          'if scheduled first', () {
        FakeAsync().run((async) {
          final log = [];
          Timer.periodic(const Duration(seconds: 1), (_) {
            log.add('periodic');
          });
          Future.delayed(const Duration(seconds: 2), () {
            log.add('delayed');
          });
          expect(log, hasLength(0), reason: 'should not flush until asked to');
          async.flushTimers(flushPeriodicTimers: false);
          expect(log, ['periodic', 'periodic', 'delayed']);
        });
      });

      test('should timeout', () {
        FakeAsync().run((async) {
          int count = 0;
          // Schedule 3 timers. All but the last one should fire.
          for (final delay in [30, 60, 90]) {
            Future.delayed(Duration(minutes: delay), () {
              count++;
            });
          }
          expect(() => async.flushTimers(flushPeriodicTimers: false),
              throwsStateError);
          expect(count, 2);
        });
      });

      test('should timeout a chain of timers', () {
        FakeAsync().run((async) {
          int count = 0;
          void createTimer() {
            Future.delayed(const Duration(minutes: 30), () {
              count++;
              createTimer();
            });
          }

          createTimer();
          expect(
              () => async.flushTimers(
                  timeout: const Duration(hours: 2),
                  flushPeriodicTimers: false),
              throwsStateError);
          expect(count, 4);
        });
      });

      test('should timeout periodic timers', () {
        FakeAsync().run((async) {
          int count = 0;
          Timer.periodic(const Duration(minutes: 30), (Timer timer) {
            count++;
          });
          expect(() => async.flushTimers(timeout: const Duration(hours: 1)),
              throwsStateError);
          expect(count, 2);
        });
      });

      test('should flush periodic timers', () {
        FakeAsync().run((async) {
          int count = 0;
          Timer.periodic(const Duration(minutes: 30), (Timer timer) {
            if (count == 3) {
              timer.cancel();
            }
            count++;
          });
          async.flushTimers(timeout: const Duration(hours: 20));
          expect(count, 4);
        });
      });

      test('should compute absolute timeout as elapsed + timeout', () {
        FakeAsync().run((async) {
          final log = [];
          int count = 0;
          void createTimer() {
            Future.delayed(const Duration(minutes: 30), () {
              log.add(count);
              count++;
              if (count < 4) {
                createTimer();
              }
            });
          }

          createTimer();
          async.elapse(const Duration(hours: 1));
          async.flushTimers(timeout: const Duration(hours: 1));
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

      test('should report the number of pending periodic timers', () {
        FakeAsync().run((async) {
          expect(async.periodicTimerCount, 0);
          Timer timer =
              Timer.periodic(const Duration(minutes: 30), (Timer timer) {});
          expect(async.periodicTimerCount, 1);
          Timer.periodic(const Duration(minutes: 20), (Timer timer) {});
          expect(async.periodicTimerCount, 2);
          async.elapse(const Duration(minutes: 20));
          expect(async.periodicTimerCount, 2);
          timer.cancel();
          expect(async.periodicTimerCount, 1);
        });
      });

      test('should report the number of pending non periodic timers', () {
        FakeAsync().run((async) {
          expect(async.nonPeriodicTimerCount, 0);
          Timer timer = Timer(const Duration(minutes: 30), () {});
          expect(async.nonPeriodicTimerCount, 1);
          Timer(const Duration(minutes: 20), () {});
          expect(async.nonPeriodicTimerCount, 2);
          async.elapse(const Duration(minutes: 25));
          expect(async.nonPeriodicTimerCount, 1);
          timer.cancel();
          expect(async.nonPeriodicTimerCount, 0);
        });
      });

      test('should report debugging information of pending timers', () {
        FakeAsync().run((async) {
          expect(async.pendingTimersDebugInfo, isEmpty);
          // Use `dynamic` to subvert the type checks and access `_FakeAsync`
          // internals.
          dynamic nonPeriodic = Timer(const Duration(seconds: 1), () {});
          dynamic periodic =
              Timer.periodic(const Duration(seconds: 2), (Timer timer) {});
          final debugInfo = async.pendingTimersDebugInfo;
          expect(debugInfo.length, 2);
          expect(
            debugInfo,
            containsAll([
              nonPeriodic.debugInfo,
              periodic.debugInfo,
            ]),
          );

          // Substrings expected to be included in the first line of
          // [Timer.debugInfo].
          final expectedInFirstLine = {
            nonPeriodic: [':01.0', 'periodic: false'],
            periodic: [':02.0', 'periodic: true'],
          };

          const thisFileName = 'fake_async_test.dart';
          for (final expectedEntry in expectedInFirstLine.entries) {
            final debugInfo = expectedEntry.key.debugInfo;
            final firstLineEnd = debugInfo.indexOf('\n');
            final firstLine = debugInfo.substring(0, firstLineEnd);
            final rest = debugInfo.substring(firstLineEnd + 1);

            for (final expectedValue in expectedEntry.value) {
              expect(firstLine, contains(expectedValue));
            }

            expect(rest, contains(thisFileName));
          }
        });
      });
    });

    group('timers', () {
      test('should behave like real timers', () {
        return FakeAsync().run((async) {
          var timeout = const Duration(minutes: 1);
          int counter = 0;
          late Timer timer;
          timer = Timer(timeout, () {
            counter++;
            expect(timer.isActive, isFalse,
                reason: 'is not active while executing callback');
          });
          expect(timer.isActive, isTrue,
              reason: 'is active before executing callback');
          async.elapse(timeout);
          expect(counter, equals(1), reason: 'timer executed');
          expect(timer.isActive, isFalse,
              reason: 'is not active after executing callback');
        });
      });
    });
  });
}
