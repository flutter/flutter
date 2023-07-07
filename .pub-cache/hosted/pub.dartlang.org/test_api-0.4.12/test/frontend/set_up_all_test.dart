// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('runs once before all tests', () {
    return expectTestsPass(() {
      var setUpAllRun = false;
      setUpAll(() {
        expect(setUpAllRun, isFalse);
        setUpAllRun = true;
      });

      test('test 1', () {
        expect(setUpAllRun, isTrue);
      });

      test('test 2', () {
        expect(setUpAllRun, isTrue);
      });
    });
  });

  test('runs once per group, outside-in', () {
    return expectTestsPass(() {
      var setUpAll1Run = false;
      var setUpAll2Run = false;
      var setUpAll3Run = false;
      setUpAll(() {
        expect(setUpAll1Run, isFalse);
        expect(setUpAll2Run, isFalse);
        expect(setUpAll3Run, isFalse);
        setUpAll1Run = true;
      });

      group('mid', () {
        setUpAll(() {
          expect(setUpAll1Run, isTrue);
          expect(setUpAll2Run, isFalse);
          expect(setUpAll3Run, isFalse);
          setUpAll2Run = true;
        });

        group('inner', () {
          setUpAll(() {
            expect(setUpAll1Run, isTrue);
            expect(setUpAll2Run, isTrue);
            expect(setUpAll3Run, isFalse);
            setUpAll3Run = true;
          });

          test('test', () {
            expect(setUpAll1Run, isTrue);
            expect(setUpAll2Run, isTrue);
            expect(setUpAll3Run, isTrue);
          });
        });
      });
    });
  });

  test('runs before setUps', () {
    return expectTestsPass(() {
      var setUpAllRun = false;
      setUp(() {
        expect(setUpAllRun, isTrue);
      });

      setUpAll(() {
        expect(setUpAllRun, isFalse);
        setUpAllRun = true;
      });

      setUp(() {
        expect(setUpAllRun, isTrue);
      });

      test('test', () {
        expect(setUpAllRun, isTrue);
      });
    });
  });

  test('multiples run in order', () {
    return expectTestsPass(() {
      var setUpAll1Run = false;
      var setUpAll2Run = false;
      var setUpAll3Run = false;
      setUpAll(() {
        expect(setUpAll1Run, isFalse);
        expect(setUpAll2Run, isFalse);
        expect(setUpAll3Run, isFalse);
        setUpAll1Run = true;
      });

      setUpAll(() {
        expect(setUpAll1Run, isTrue);
        expect(setUpAll2Run, isFalse);
        expect(setUpAll3Run, isFalse);
        setUpAll2Run = true;
      });

      setUpAll(() {
        expect(setUpAll1Run, isTrue);
        expect(setUpAll2Run, isTrue);
        expect(setUpAll3Run, isFalse);
        setUpAll3Run = true;
      });

      test('test', () {
        expect(setUpAll1Run, isTrue);
        expect(setUpAll2Run, isTrue);
        expect(setUpAll3Run, isTrue);
      });
    });
  });

  group('asynchronously', () {
    test('blocks additional setUpAlls on in-band async', () {
      return expectTestsPass(() {
        var setUpAll1Run = false;
        var setUpAll2Run = false;
        var setUpAll3Run = false;
        setUpAll(() async {
          expect(setUpAll1Run, isFalse);
          expect(setUpAll2Run, isFalse);
          expect(setUpAll3Run, isFalse);
          await pumpEventQueue();
          setUpAll1Run = true;
        });

        setUpAll(() async {
          expect(setUpAll1Run, isTrue);
          expect(setUpAll2Run, isFalse);
          expect(setUpAll3Run, isFalse);
          await pumpEventQueue();
          setUpAll2Run = true;
        });

        setUpAll(() async {
          expect(setUpAll1Run, isTrue);
          expect(setUpAll2Run, isTrue);
          expect(setUpAll3Run, isFalse);
          await pumpEventQueue();
          setUpAll3Run = true;
        });

        test('test', () {
          expect(setUpAll1Run, isTrue);
          expect(setUpAll2Run, isTrue);
          expect(setUpAll3Run, isTrue);
        });
      });
    });

    test("doesn't block additional setUpAlls on out-of-band async", () {
      return expectTestsPass(() {
        var setUpAll1Run = false;
        var setUpAll2Run = false;
        var setUpAll3Run = false;
        setUpAll(() {
          expect(setUpAll1Run, isFalse);
          expect(setUpAll2Run, isFalse);
          expect(setUpAll3Run, isFalse);

          expect(
              pumpEventQueue().then((_) {
                setUpAll1Run = true;
              }),
              completes);
        });

        setUpAll(() {
          expect(setUpAll1Run, isFalse);
          expect(setUpAll2Run, isFalse);
          expect(setUpAll3Run, isFalse);

          expect(
              pumpEventQueue().then((_) {
                setUpAll2Run = true;
              }),
              completes);
        });

        setUpAll(() {
          expect(setUpAll1Run, isFalse);
          expect(setUpAll2Run, isFalse);
          expect(setUpAll3Run, isFalse);

          expect(
              pumpEventQueue().then((_) {
                setUpAll3Run = true;
              }),
              completes);
        });

        test('test', () {
          expect(setUpAll1Run, isTrue);
          expect(setUpAll2Run, isTrue);
          expect(setUpAll3Run, isTrue);
        });
      });
    });
  });

  test("isn't run for a skipped group", () async {
    // Declare this in the outer test so if it runs, the outer test will fail.
    var shouldNotRun = expectAsync0(() {}, count: 0);

    var engine = declareEngine(() {
      group('skipped', () {
        setUpAll(shouldNotRun);

        test('test', () {});
      }, skip: true);
    });

    await engine.run();
    expect(engine.liveTests, hasLength(1));
    expect(engine.skipped, hasLength(1));
    expect(engine.liveTests, equals(engine.skipped));
  });

  test('is emitted through Engine.onTestStarted', () async {
    var engine = declareEngine(() {
      setUpAll(() {});

      test('test', () {});
    });

    var queue = StreamQueue(engine.onTestStarted);
    var setUpAllFuture = queue.next;
    var liveTestFuture = queue.next;

    await engine.run();

    var setUpAllLiveTest = await setUpAllFuture;
    expect(setUpAllLiveTest.test.name, equals('(setUpAll)'));
    expectTestPassed(setUpAllLiveTest);

    // The fake test for setUpAll should be removed from the engine's live
    // test list so that reporters don't display it as a passed test.
    expect(engine.liveTests, isNot(contains(setUpAllLiveTest)));
    expect(engine.passed, isNot(contains(setUpAllLiveTest)));
    expect(engine.failed, isNot(contains(setUpAllLiveTest)));
    expect(engine.skipped, isNot(contains(setUpAllLiveTest)));
    expect(engine.active, isNot(contains(setUpAllLiveTest)));

    var liveTest = await liveTestFuture;
    expectTestPassed(await liveTestFuture);
    expect(engine.liveTests, contains(liveTest));
    expect(engine.passed, contains(liveTest));
  });

  group('with an error', () {
    test('reports the error and remains in Engine.liveTests', () async {
      var engine = declareEngine(() {
        setUpAll(() => throw TestFailure('fail'));

        test('test', () {});
      });

      var queue = StreamQueue(engine.onTestStarted);
      var setUpAllFuture = queue.next;

      expect(await engine.run(), isFalse);

      var setUpAllLiveTest = await setUpAllFuture;
      expect(setUpAllLiveTest.test.name, equals('(setUpAll)'));
      expectTestFailed(setUpAllLiveTest, 'fail');

      // The fake test for setUpAll should be removed from the engine's live
      // test list so that reporters don't display it as a passed test.
      expect(engine.liveTests, contains(setUpAllLiveTest));
      expect(engine.failed, contains(setUpAllLiveTest));
      expect(engine.passed, isNot(contains(setUpAllLiveTest)));
      expect(engine.skipped, isNot(contains(setUpAllLiveTest)));
      expect(engine.active, isNot(contains(setUpAllLiveTest)));
    });

    test("doesn't run tests in the group", () async {
      // Declare this in the outer test so if it runs, the outer test will fail.
      var shouldNotRun = expectAsync0(() {}, count: 0);

      var engine = declareEngine(() {
        setUpAll(() => throw 'error');

        test('test', shouldNotRun);
      });

      expect(await engine.run(), isFalse);
    });

    test("doesn't run inner groups", () async {
      // Declare this in the outer test so if it runs, the outer test will fail.
      var shouldNotRun = expectAsync0(() {}, count: 0);

      var engine = declareEngine(() {
        setUpAll(() => throw 'error');

        group('group', () {
          test('test', shouldNotRun);
        });
      });

      expect(await engine.run(), isFalse);
    });

    test("doesn't run further setUpAlls", () async {
      // Declare this in the outer test so if it runs, the outer test will fail.
      var shouldNotRun = expectAsync0(() {}, count: 0);

      var engine = declareEngine(() {
        setUpAll(() => throw 'error');
        setUpAll(shouldNotRun);

        test('test', shouldNotRun);
      });

      expect(await engine.run(), isFalse);
    });
  });
}
