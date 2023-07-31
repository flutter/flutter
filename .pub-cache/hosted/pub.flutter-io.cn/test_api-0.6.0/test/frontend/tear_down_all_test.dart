// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('runs once after all tests', () {
    return expectTestsPass(() {
      var test1Run = false;
      var test2Run = false;
      var tearDownAllRun = false;
      tearDownAll(() {
        expect(test1Run, isTrue);
        expect(test2Run, isTrue);
        expect(tearDownAllRun, isFalse);
        tearDownAllRun = true;
      });

      test('test 1', () {
        expect(tearDownAllRun, isFalse);
        test1Run = true;
      });

      test('test 2', () {
        expect(tearDownAllRun, isFalse);
        test2Run = true;
      });
    });
  });

  test('runs once per group, inside-out', () {
    return expectTestsPass(() {
      var tearDownAll1Run = false;
      var tearDownAll2Run = false;
      var tearDownAll3Run = false;
      var testRun = false;
      tearDownAll(() {
        expect(tearDownAll1Run, isFalse);
        expect(tearDownAll2Run, isTrue);
        expect(tearDownAll3Run, isTrue);
        expect(testRun, isTrue);
        tearDownAll1Run = true;
      });

      group('mid', () {
        tearDownAll(() {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isTrue);
          expect(testRun, isTrue);
          tearDownAll2Run = true;
        });

        group('inner', () {
          tearDownAll(() {
            expect(tearDownAll1Run, isFalse);
            expect(tearDownAll2Run, isFalse);
            expect(tearDownAll3Run, isFalse);
            expect(testRun, isTrue);
            tearDownAll3Run = true;
          });

          test('test', () {
            expect(tearDownAll1Run, isFalse);
            expect(tearDownAll2Run, isFalse);
            expect(tearDownAll3Run, isFalse);
            testRun = true;
          });
        });
      });
    });
  });

  test('runs after tearDowns', () {
    return expectTestsPass(() {
      var tearDown1Run = false;
      var tearDown2Run = false;
      var tearDownAllRun = false;
      tearDown(() {
        expect(tearDownAllRun, isFalse);
        tearDown1Run = true;
      });

      tearDownAll(() {
        expect(tearDown1Run, isTrue);
        expect(tearDown2Run, isTrue);
        expect(tearDownAllRun, isFalse);
        tearDownAllRun = true;
      });

      tearDown(() {
        expect(tearDownAllRun, isFalse);
        tearDown2Run = true;
      });

      test('test', () {
        expect(tearDownAllRun, isFalse);
      });
    });
  });

  test('multiples run in reverse order', () {
    return expectTestsPass(() {
      var tearDownAll1Run = false;
      var tearDownAll2Run = false;
      var tearDownAll3Run = false;
      tearDownAll(() {
        expect(tearDownAll1Run, isFalse);
        expect(tearDownAll2Run, isTrue);
        expect(tearDownAll3Run, isTrue);
        tearDownAll1Run = true;
      });

      tearDownAll(() {
        expect(tearDownAll1Run, isFalse);
        expect(tearDownAll2Run, isFalse);
        expect(tearDownAll3Run, isTrue);
        tearDownAll2Run = true;
      });

      tearDownAll(() {
        expect(tearDownAll1Run, isFalse);
        expect(tearDownAll2Run, isFalse);
        expect(tearDownAll3Run, isFalse);
        tearDownAll3Run = true;
      });

      test('test', () {
        expect(tearDownAll1Run, isFalse);
        expect(tearDownAll2Run, isFalse);
        expect(tearDownAll3Run, isFalse);
      });
    });
  });

  group('asynchronously', () {
    test('blocks additional tearDownAlls on in-band async', () {
      return expectTestsPass(() {
        var tearDownAll1Run = false;
        var tearDownAll2Run = false;
        var tearDownAll3Run = false;
        tearDownAll(() async {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isTrue);
          expect(tearDownAll3Run, isTrue);
          await pumpEventQueue();
          tearDownAll1Run = true;
        });

        tearDownAll(() async {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isTrue);
          await pumpEventQueue();
          tearDownAll2Run = true;
        });

        tearDownAll(() async {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isFalse);
          await pumpEventQueue();
          tearDownAll3Run = true;
        });

        test('test', () {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isFalse);
        });
      });
    });

    test("doesn't block additional tearDownAlls on out-of-band async", () {
      return expectTestsPass(() {
        var tearDownAll1Run = false;
        var tearDownAll2Run = false;
        var tearDownAll3Run = false;
        tearDownAll(() {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isFalse);

          expect(Future(() {
            tearDownAll1Run = true;
          }), completes);
        });

        tearDownAll(() {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isFalse);

          expect(Future(() {
            tearDownAll2Run = true;
          }), completes);
        });

        tearDownAll(() {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isFalse);

          expect(Future(() {
            tearDownAll3Run = true;
          }), completes);
        });

        test('test', () {
          expect(tearDownAll1Run, isFalse);
          expect(tearDownAll2Run, isFalse);
          expect(tearDownAll3Run, isFalse);
        });
      });
    });

    test('blocks further tests on in-band async', () {
      return expectTestsPass(() {
        var tearDownAllRun = false;
        group('group', () {
          tearDownAll(() async {
            expect(tearDownAllRun, isFalse);
            await pumpEventQueue();
            tearDownAllRun = true;
          });

          test('test', () {});
        });

        test('after', () {
          expect(tearDownAllRun, isTrue);
        });
      });
    });

    test('blocks further tests on out-of-band async', () {
      return expectTestsPass(() {
        var tearDownAllRun = false;
        group('group', () {
          tearDownAll(() async {
            expect(tearDownAllRun, isFalse);
            expect(
                pumpEventQueue().then((_) {
                  tearDownAllRun = true;
                }),
                completes);
          });

          test('test', () {});
        });

        test('after', () {
          expect(tearDownAllRun, isTrue);
        });
      });
    });
  });

  test("isn't run for a skipped group", () async {
    // Declare this in the outer test so if it runs, the outer test will fail.
    var shouldNotRun = expectAsync0(() {}, count: 0);

    var engine = declareEngine(() {
      group('skipped', () {
        tearDownAll(shouldNotRun);

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
      tearDownAll(() {});

      test('test', () {});
    });

    var queue = StreamQueue(engine.onTestStarted);
    var liveTestFuture = queue.next;
    var tearDownAllFuture = queue.next;

    await engine.run();

    var tearDownAllLiveTest = await tearDownAllFuture;
    expect(tearDownAllLiveTest.test.name, equals('(tearDownAll)'));
    expectTestPassed(tearDownAllLiveTest);

    // The fake test for tearDownAll should be removed from the engine's live
    // test list so that reporters don't display it as a passed test.
    expect(engine.liveTests, isNot(contains(tearDownAllLiveTest)));
    expect(engine.passed, isNot(contains(tearDownAllLiveTest)));
    expect(engine.failed, isNot(contains(tearDownAllLiveTest)));
    expect(engine.skipped, isNot(contains(tearDownAllLiveTest)));
    expect(engine.active, isNot(contains(tearDownAllLiveTest)));

    var liveTest = await liveTestFuture;
    expectTestPassed(await liveTestFuture);
    expect(engine.liveTests, contains(liveTest));
    expect(engine.passed, contains(liveTest));
  });

  group('with an error', () {
    test('reports the error and remains in Engine.liveTests', () async {
      var engine = declareEngine(() {
        tearDownAll(() => throw TestFailure('fail'));

        test('test', () {});
      });

      var queue = StreamQueue(engine.onTestStarted);
      expect(queue.next, completes);
      var tearDownAllFuture = queue.next;

      expect(await engine.run(), isFalse);

      var tearDownAllLiveTest = await tearDownAllFuture;
      expect(tearDownAllLiveTest.test.name, equals('(tearDownAll)'));
      expectTestFailed(tearDownAllLiveTest, 'fail');

      // The fake test for tearDownAll should be removed from the engine's live
      // test list so that reporters don't display it as a passed test.
      expect(engine.liveTests, contains(tearDownAllLiveTest));
      expect(engine.failed, contains(tearDownAllLiveTest));
      expect(engine.passed, isNot(contains(tearDownAllLiveTest)));
      expect(engine.skipped, isNot(contains(tearDownAllLiveTest)));
      expect(engine.active, isNot(contains(tearDownAllLiveTest)));
    });

    test('runs further tearDownAlls', () async {
      // Declare this in the outer test so if it doesn't runs, the outer test
      // will fail.
      var shouldRun = expectAsync0(() {});

      var engine = declareEngine(() {
        tearDownAll(() => throw 'error');
        tearDownAll(shouldRun);

        test('test', () {});
      });

      expect(await engine.run(), isFalse);
    });

    test('runs outer tearDownAlls', () async {
      // Declare this in the outer test so if it doesn't runs, the outer test
      // will fail.
      var shouldRun = expectAsync0(() {});

      var engine = declareEngine(() {
        tearDownAll(shouldRun);

        group('group', () {
          tearDownAll(() => throw 'error');

          test('test', () {});
        });
      });

      expect(await engine.run(), isFalse);
    });
  });
}
