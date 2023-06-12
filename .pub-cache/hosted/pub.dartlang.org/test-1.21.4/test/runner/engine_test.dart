// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:test/test.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_core/src/runner/engine.dart';

import '../utils.dart';

void main() {
  test('runs each test in each suite in order', () async {
    var testsRun = 0;
    var tests = declare(() {
      for (var i = 0; i < 4; i++) {
        test(
            'test ${i + 1}',
            expectAsync0(() {
              expect(testsRun, equals(i));
              testsRun++;
            }, max: 1));
      }
    });

    var engine = Engine.withSuites([
      runnerSuite(Group.root(tests.take(2))),
      runnerSuite(Group.root(tests.skip(2)))
    ]);

    await engine.run();
    expect(testsRun, equals(4));
  });

  test('runs tests in a suite added after run() was called', () {
    var testsRun = 0;
    var tests = declare(() {
      for (var i = 0; i < 4; i++) {
        test(
            'test ${i + 1}',
            expectAsync0(() {
              expect(testsRun, equals(i));
              testsRun++;
            }, max: 1));
      }
    });

    var engine = Engine();
    expect(
        engine.run().then((_) {
          expect(testsRun, equals(4));
        }),
        completes);

    engine.suiteSink.add(runnerSuite(Group.root(tests)));
    engine.suiteSink.close();
  });

  test('returns fail if any test does not complete', () async {
    var completer = Completer();
    var engine = declareEngine(() {
      test('completes', () {});
      test('does not complete', () async {
        await completer.future;
      });
    });
    expect(engine.run(), completion(isFalse));
    await pumpEventQueue();
    unawaited(engine.close());
    // We need to complete this so the outer test finishes.
    completer.complete();
  });

  test(
      'emits each test before it starts running and after the previous test '
      'finished', () {
    var testsRun = 0;
    var engine = declareEngine(() {
      for (var i = 0; i < 3; i++) {
        test('test ${i + 1}', expectAsync0(() => testsRun++, max: 1));
      }
    });

    engine.onTestStarted.listen(expectAsync1((liveTest) {
      // [testsRun] should be one less than the test currently running.
      expect(liveTest.test.name, equals('test ${testsRun + 1}'));

      // [Engine.onTestStarted] is guaranteed to fire before the first
      // [LiveTest.onStateChange].
      expect(liveTest.onStateChange.first,
          completion(equals(const State(Status.running, Result.success))));
    }, count: 3, max: 3));

    return engine.run();
  });

  test('.run() returns true if every test passes', () {
    var engine = declareEngine(() {
      for (var i = 0; i < 2; i++) {
        test('test ${i + 1}', () {});
      }
    });

    expect(engine.run(), completion(isTrue));
  });

  test('.run() returns false if any test fails', () {
    var engine = declareEngine(() {
      for (var i = 0; i < 2; i++) {
        test('test ${i + 1}', () {});
      }
      test('failure', () => throw TestFailure('oh no'));
    });

    expect(engine.run(), completion(isFalse));
  });

  test('.run() returns false if any test errors', () {
    var engine = declareEngine(() {
      for (var i = 0; i < 2; i++) {
        test('test ${i + 1}', () {});
      }
      test('failure', () => throw 'oh no');
    });

    expect(engine.run(), completion(isFalse));
  });

  test('.run() may not be called more than once', () {
    var engine = Engine.withSuites([]);
    expect(engine.run(), completes);
    expect(engine.run, throwsStateError);
  });

  test('runs tearDown after a test times out', () {
    // Declare this here so the expect is in the context of this test, rather
    // than the inner test.
    var secondTestStarted = false;
    var firstTestFinished = false;
    var tearDownBody = expectAsync0(() {
      expect(secondTestStarted, isFalse);
      expect(firstTestFinished, isFalse);
    });

    var engine = declareEngine(() {
      // This ensures that the first test doesn't actually finish until the
      // second test runs.
      var firstTestCompleter = Completer();

      group('group', () {
        tearDown(tearDownBody);

        test('first test', () async {
          await firstTestCompleter.future;
          firstTestFinished = true;
        }, timeout: Timeout(Duration.zero));
      });

      test('second test', () {
        secondTestStarted = true;
        firstTestCompleter.complete();
      });
    });

    expect(engine.run(), completes);
  });

  group('for a skipped test', () {
    test("doesn't run the test's body", () async {
      var bodyRun = false;
      var engine = declareEngine(() {
        test('test', () => bodyRun = true, skip: true);
      });

      await engine.run();
      expect(bodyRun, isFalse);
    });

    test("runs the test's body with --run-skipped", () async {
      var bodyRun = false;
      var engine = declareEngine(() {
        test('test', () => bodyRun = true, skip: true);
      }, runSkipped: true);

      await engine.run();
      expect(bodyRun, isTrue);
    });

    test('exposes a LiveTest that emits the correct states', () {
      var tests = declare(() {
        test('test', () {}, skip: true);
      });

      var engine = Engine.withSuites([runnerSuite(Group.root(tests))]);

      engine.onTestStarted.listen(expectAsync1((liveTest) {
        expect(liveTest, same(engine.liveTests.single));
        expect(liveTest.test.name, equals(tests.single.name));

        var i = 0;
        liveTest.onStateChange.listen(expectAsync1((state) {
          if (i == 0) {
            expect(state, equals(const State(Status.running, Result.success)));
          } else if (i == 1) {
            expect(state, equals(const State(Status.running, Result.skipped)));
          } else if (i == 2) {
            expect(state, equals(const State(Status.complete, Result.skipped)));
          }
          i++;
        }, count: 3));

        expect(liveTest.onComplete, completes);
      }));

      return engine.run();
    });
  });

  group('for a skipped group', () {
    test("doesn't run a test in the group", () async {
      var bodyRun = false;
      var engine = declareEngine(() {
        group('group', () {
          test('test', () => bodyRun = true);
        }, skip: true);
      });

      await engine.run();
      expect(bodyRun, isFalse);
    });

    test('runs tests in the group with --run-skipped', () async {
      var bodyRun = false;
      var engine = declareEngine(() {
        group('group', () {
          test('test', () => bodyRun = true);
        }, skip: true);
      }, runSkipped: true);

      await engine.run();
      expect(bodyRun, isTrue);
    });

    test('exposes a LiveTest that emits the correct states', () {
      var entries = declare(() {
        group('group', () {
          test('test', () {});
        }, skip: true);
      });

      var engine = Engine.withSuites([runnerSuite(Group.root(entries))]);

      engine.onTestStarted.listen(expectAsync1((liveTest) {
        expect(liveTest, same(engine.liveTests.single));
        expect(liveTest.test.name, equals('group test'));

        var i = 0;
        liveTest.onStateChange.listen(expectAsync1((state) {
          if (i == 0) {
            expect(state, equals(const State(Status.running, Result.success)));
          } else if (i == 1) {
            expect(state, equals(const State(Status.running, Result.skipped)));
          } else if (i == 2) {
            expect(state, equals(const State(Status.complete, Result.skipped)));
          }
          i++;
        }, count: 3));

        expect(liveTest.onComplete, completes);
      }));

      return engine.run();
    });
  });

  group('concurrency', () {
    test('is shared between runner and load suites', () async {
      for (var concurrency = 1; concurrency < 5; concurrency++) {
        var testsLoaded = 0;
        var maxLoadConcurrency = 0;
        var testsRunning = 0;
        var maxTestConcurrency = 0;
        var testCount = concurrency * 2;

        Future<void> updateAndCheckConcurrency(
            {bool isLoadSuite = false}) async {
          if (isLoadSuite) {
            testsLoaded++;
            maxLoadConcurrency = max(maxLoadConcurrency, testsLoaded);
            expect(testsLoaded, lessThanOrEqualTo(concurrency));
          } else {
            testsRunning++;
            maxTestConcurrency = max(maxTestConcurrency, testsRunning);
            expect(testsRunning, lessThanOrEqualTo(concurrency));
          }
          // Simulate the test/loading taking some amount of time so that
          // we actually reach max concurrency.
          await Future.delayed(Duration(milliseconds: 100));
          if (!isLoadSuite) {
            testsRunning--;
            testsLoaded--;
          }
        }

        var tests = declare(() {
          for (var i = 0; i < testCount; i++) {
            test('test ${i + 1}', () async {
              await updateAndCheckConcurrency();
            });
          }
        });
        var engine = Engine.withSuites([
          for (var i = 0; i < testCount; i++)
            loadSuite('group $i', () async {
              await updateAndCheckConcurrency(isLoadSuite: true);
              return runnerSuite(Group.root([tests[i]]));
            }),
        ], concurrency: concurrency);

        await engine.run();
        expect(engine.liveTests.length, testCount);

        // We should reach but not exceed max concurrency
        expect(maxTestConcurrency, concurrency);
        expect(maxLoadConcurrency, concurrency);
      }
    });
  });
}
