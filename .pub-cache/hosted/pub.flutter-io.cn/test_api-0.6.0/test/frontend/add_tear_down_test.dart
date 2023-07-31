// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('in a test', () {
    test('runs after the test body', () {
      return expectTestsPass(() {
        var test1Run = false;
        var tearDownRun = false;
        test('test 1', () {
          addTearDown(() {
            expect(test1Run, isTrue);
            expect(tearDownRun, isFalse);
            tearDownRun = true;
          });

          expect(tearDownRun, isFalse);
          test1Run = true;
        });

        test('test 2', () {
          expect(tearDownRun, isTrue);
        });
      });
    });

    test('multiples run in reverse order', () {
      return expectTestsPass(() {
        var tearDown1Run = false;
        var tearDown2Run = false;
        var tearDown3Run = false;

        test('test 1', () {
          addTearDown(() {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isTrue);
            expect(tearDown3Run, isTrue);
            tearDown1Run = true;
          });

          addTearDown(() {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isTrue);
            tearDown2Run = true;
          });

          addTearDown(() {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
            tearDown3Run = true;
          });

          expect(tearDown1Run, isFalse);
          expect(tearDown2Run, isFalse);
          expect(tearDown3Run, isFalse);
        });

        test('test 2', () {
          expect(tearDown1Run, isTrue);
          expect(tearDown2Run, isTrue);
          expect(tearDown3Run, isTrue);
        });
      });
    });

    test('can be called in addTearDown', () {
      return expectTestsPass(() {
        var tearDown2Run = false;
        var tearDown3Run = false;

        test('test 1', () {
          addTearDown(() {
            expect(tearDown2Run, isTrue);
            expect(tearDown3Run, isFalse);
            tearDown3Run = true;
          });

          addTearDown(() {
            addTearDown(() {
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);
              tearDown2Run = true;
            });
          });
        });

        test('test 2', () {
          expect(tearDown2Run, isTrue);
          expect(tearDown3Run, isTrue);
        });
      });
    });

    test('can be called in tearDown', () {
      return expectTestsPass(() {
        var tearDown2Run = false;
        var tearDown3Run = false;

        tearDown(() {
          expect(tearDown2Run, isTrue);
          expect(tearDown3Run, isFalse);
          tearDown3Run = true;
        });

        tearDown(() {
          tearDown2Run = false;
          tearDown3Run = false;

          addTearDown(() {
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
            tearDown2Run = true;
          });
        });

        test('test 1', () {});

        test('test 2', () {
          expect(tearDown2Run, isTrue);
          expect(tearDown3Run, isTrue);
        });
      });
    });

    test('runs before a normal tearDown', () {
      return expectTestsPass(() {
        var groupTearDownRun = false;
        var testTearDownRun = false;
        group('group', () {
          tearDown(() {
            expect(testTearDownRun, isTrue);
            expect(groupTearDownRun, isFalse);
            groupTearDownRun = true;
          });

          test('test 1', () {
            addTearDown(() {
              expect(groupTearDownRun, isFalse);
              expect(testTearDownRun, isFalse);
              testTearDownRun = true;
            });

            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);
          });
        });

        test('test 2', () {
          expect(groupTearDownRun, isTrue);
          expect(testTearDownRun, isTrue);
        });
      });
    });

    test('runs in the same error zone as the test', () {
      return expectTestsPass(() {
        test('test', () {
          final testBodyZone = Zone.current;

          addTearDown(() {
            final tearDownZone = Zone.current;
            expect(tearDownZone.inSameErrorZone(testBodyZone), isTrue,
                reason: 'The tear down callback is in a different error zone '
                    'than the test body.');
          });
        });
      });
    });

    group('asynchronously', () {
      test('blocks additional test tearDowns on in-band async', () {
        return expectTestsPass(() {
          var tearDown1Run = false;
          var tearDown2Run = false;
          var tearDown3Run = false;
          test('test', () {
            addTearDown(() async {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isTrue);
              expect(tearDown3Run, isTrue);
              await pumpEventQueue();
              tearDown1Run = true;
            });

            addTearDown(() async {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isTrue);
              await pumpEventQueue();
              tearDown2Run = true;
            });

            addTearDown(() async {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);
              await pumpEventQueue();
              tearDown3Run = true;
            });

            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
          });
        });
      });

      test("doesn't block additional test tearDowns on out-of-band async", () {
        return expectTestsPass(() {
          var tearDown1Run = false;
          var tearDown2Run = false;
          var tearDown3Run = false;
          test('test', () {
            addTearDown(() {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);

              expect(Future(() {
                tearDown1Run = true;
              }), completes);
            });

            addTearDown(() {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);

              expect(Future(() {
                tearDown2Run = true;
              }), completes);
            });

            addTearDown(() {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);

              expect(Future(() {
                tearDown3Run = true;
              }), completes);
            });

            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
          });
        });
      });

      test('blocks additional group tearDowns on in-band async', () {
        return expectTestsPass(() {
          var groupTearDownRun = false;
          var testTearDownRun = false;
          tearDown(() async {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isTrue);
            await pumpEventQueue();
            groupTearDownRun = true;
          });

          test('test', () {
            addTearDown(() async {
              expect(groupTearDownRun, isFalse);
              expect(testTearDownRun, isFalse);
              await pumpEventQueue();
              testTearDownRun = true;
            });

            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);
          });
        });
      });

      test("doesn't block additional group tearDowns on out-of-band async", () {
        return expectTestsPass(() {
          var groupTearDownRun = false;
          var testTearDownRun = false;
          tearDown(() {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);

            expect(Future(() {
              groupTearDownRun = true;
            }), completes);
          });

          test('test', () {
            addTearDown(() {
              expect(groupTearDownRun, isFalse);
              expect(testTearDownRun, isFalse);

              expect(Future(() {
                testTearDownRun = true;
              }), completes);
            });

            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);
          });
        });
      });

      test('blocks further tests on in-band async', () {
        return expectTestsPass(() {
          var tearDownRun = false;
          test('test 1', () {
            addTearDown(() async {
              expect(tearDownRun, isFalse);
              await pumpEventQueue();
              tearDownRun = true;
            });
          });

          test('test 2', () {
            expect(tearDownRun, isTrue);
          });
        });
      });

      test('blocks further tests on out-of-band async', () {
        return expectTestsPass(() {
          var tearDownRun = false;
          test('test 1', () {
            addTearDown(() async {
              expect(tearDownRun, isFalse);
              expect(
                  pumpEventQueue().then((_) {
                    tearDownRun = true;
                  }),
                  completes);
            });
          });

          test('after', () {
            expect(tearDownRun, isTrue);
          });
        });
      });
    });

    group('with an error', () {
      test('reports the error', () async {
        var engine = declareEngine(() {
          test('test', () {
            addTearDown(() => throw TestFailure('fail'));
          });
        });

        var queue = StreamQueue(engine.onTestStarted);
        var liveTestFuture = queue.next;

        expect(await engine.run(), isFalse);

        var liveTest = await liveTestFuture;
        expect(liveTest.test.name, equals('test'));
        expectTestFailed(liveTest, 'fail');
      });

      test('runs further test tearDowns', () async {
        // Declare this in the outer test so if it doesn't run, the outer test
        // will fail.
        var shouldRun = expectAsync0(() {});

        var engine = declareEngine(() {
          test('test', () {
            addTearDown(() => throw 'error');
            addTearDown(shouldRun);
          });
        });

        expect(await engine.run(), isFalse);
      });

      test('runs further group tearDowns', () async {
        // Declare this in the outer test so if it doesn't run, the outer test
        // will fail.
        var shouldRun = expectAsync0(() {});

        var engine = declareEngine(() {
          tearDown(shouldRun);

          test('test', () {
            addTearDown(() => throw 'error');
          });
        });

        expect(await engine.run(), isFalse);
      });
    });
  });

  group('in setUpAll()', () {
    test('runs after all tests', () async {
      var test1Run = false;
      var test2Run = false;
      var tearDownRun = false;
      await expectTestsPass(() {
        setUpAll(() {
          addTearDown(() {
            expect(test1Run, isTrue);
            expect(test2Run, isTrue);
            expect(tearDownRun, isFalse);
            tearDownRun = true;
          });
        });

        test('test 1', () {
          test1Run = true;
          expect(tearDownRun, isFalse);
        });

        test('test 2', () {
          test2Run = true;
          expect(tearDownRun, isFalse);
        });
      });

      expect(test1Run, isTrue);
      expect(test2Run, isTrue);
      expect(tearDownRun, isTrue);
    });

    test('multiples run in reverse order', () async {
      var tearDown1Run = false;
      var tearDown2Run = false;
      var tearDown3Run = false;
      await expectTestsPass(() {
        setUpAll(() {
          addTearDown(() {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isTrue);
            expect(tearDown3Run, isTrue);
            tearDown1Run = true;
          });

          addTearDown(() {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isTrue);
            tearDown2Run = true;
          });

          addTearDown(() {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
            tearDown3Run = true;
          });

          expect(tearDown1Run, isFalse);
          expect(tearDown2Run, isFalse);
          expect(tearDown3Run, isFalse);
        });

        test('test', () {
          expect(tearDown1Run, isFalse);
          expect(tearDown2Run, isFalse);
          expect(tearDown3Run, isFalse);
        });
      });

      expect(tearDown1Run, isTrue);
      expect(tearDown2Run, isTrue);
      expect(tearDown3Run, isTrue);
    });

    test('can be called in addTearDown', () async {
      var tearDown2Run = false;
      var tearDown3Run = false;
      await expectTestsPass(() {
        setUpAll(() {
          addTearDown(() {
            expect(tearDown2Run, isTrue);
            expect(tearDown3Run, isFalse);
            tearDown3Run = true;
          });

          addTearDown(() {
            addTearDown(() {
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);
              tearDown2Run = true;
            });
          });
        });

        test('test', () {
          expect(tearDown2Run, isFalse);
          expect(tearDown3Run, isFalse);
        });
      });

      expect(tearDown2Run, isTrue);
      expect(tearDown3Run, isTrue);
    });

    test('can be called in tearDownAll', () async {
      var tearDown2Run = false;
      var tearDown3Run = false;
      await expectTestsPass(() {
        tearDownAll(() {
          expect(tearDown2Run, isTrue);
          expect(tearDown3Run, isFalse);
          tearDown3Run = true;
        });

        tearDownAll(() {
          tearDown2Run = false;
          tearDown3Run = false;

          addTearDown(() {
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
            tearDown2Run = true;
          });
        });

        test('test', () {});
      });

      expect(tearDown2Run, isTrue);
      expect(tearDown3Run, isTrue);
    });

    test('runs before a normal tearDownAll', () async {
      var groupTearDownRun = false;
      var testTearDownRun = false;
      await expectTestsPass(() {
        tearDownAll(() {
          expect(testTearDownRun, isTrue);
          expect(groupTearDownRun, isFalse);
          groupTearDownRun = true;
        });

        setUpAll(() {
          addTearDown(() {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);
            testTearDownRun = true;
          });
        });

        test('test', () {
          expect(groupTearDownRun, isFalse);
          expect(testTearDownRun, isFalse);
        });
      });

      expect(groupTearDownRun, isTrue);
      expect(testTearDownRun, isTrue);
    });

    test('runs in the same error zone as the setUpAll', () async {
      return expectTestsPass(() {
        setUpAll(() {
          final setUpAllZone = Zone.current;

          addTearDown(() {
            final tearDownZone = Zone.current;
            expect(tearDownZone.inSameErrorZone(setUpAllZone), isTrue,
                reason: 'The tear down callback is in a different error zone '
                    'than the set up all callback.');
          });
        });

        test('test', () {});
      });
    });

    group('asynchronously', () {
      test('blocks additional tearDowns on in-band async', () async {
        var tearDown1Run = false;
        var tearDown2Run = false;
        var tearDown3Run = false;
        await expectTestsPass(() {
          setUpAll(() {
            addTearDown(() async {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isTrue);
              expect(tearDown3Run, isTrue);
              await pumpEventQueue();
              tearDown1Run = true;
            });

            addTearDown(() async {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isTrue);
              await pumpEventQueue();
              tearDown2Run = true;
            });

            addTearDown(() async {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);
              await pumpEventQueue();
              tearDown3Run = true;
            });
          });

          test('test', () {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
          });
        });

        expect(tearDown1Run, isTrue);
        expect(tearDown2Run, isTrue);
        expect(tearDown3Run, isTrue);
      });

      test("doesn't block additional tearDowns on out-of-band async", () async {
        var tearDown1Run = false;
        var tearDown2Run = false;
        var tearDown3Run = false;
        await expectTestsPass(() {
          setUpAll(() {
            addTearDown(() {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);

              expect(Future(() {
                tearDown1Run = true;
              }), completes);
            });

            addTearDown(() {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);

              expect(Future(() {
                tearDown2Run = true;
              }), completes);
            });

            addTearDown(() {
              expect(tearDown1Run, isFalse);
              expect(tearDown2Run, isFalse);
              expect(tearDown3Run, isFalse);

              expect(Future(() {
                tearDown3Run = true;
              }), completes);
            });
          });

          test('test', () {
            expect(tearDown1Run, isFalse);
            expect(tearDown2Run, isFalse);
            expect(tearDown3Run, isFalse);
          });
        });

        expect(tearDown1Run, isTrue);
        expect(tearDown2Run, isTrue);
        expect(tearDown3Run, isTrue);
      });

      test('blocks additional tearDownAlls on in-band async', () async {
        var groupTearDownRun = false;
        var testTearDownRun = false;
        await expectTestsPass(() {
          tearDownAll(() async {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isTrue);
            await pumpEventQueue();
            groupTearDownRun = true;
          });

          setUpAll(() {
            addTearDown(() async {
              expect(groupTearDownRun, isFalse);
              expect(testTearDownRun, isFalse);
              await pumpEventQueue();
              testTearDownRun = true;
            });
          });

          test('test', () {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);
          });
        });

        expect(groupTearDownRun, isTrue);
        expect(testTearDownRun, isTrue);
      });

      test("doesn't block additional tearDownAlls on out-of-band async",
          () async {
        var groupTearDownRun = false;
        var testTearDownRun = false;
        await expectTestsPass(() {
          tearDownAll(() {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);

            expect(Future(() {
              groupTearDownRun = true;
            }), completes);
          });

          setUpAll(() {
            addTearDown(() {
              expect(groupTearDownRun, isFalse);
              expect(testTearDownRun, isFalse);

              expect(Future(() {
                testTearDownRun = true;
              }), completes);
            });
          });

          test('test', () {
            expect(groupTearDownRun, isFalse);
            expect(testTearDownRun, isFalse);
          });
        });

        expect(groupTearDownRun, isTrue);
        expect(testTearDownRun, isTrue);
      });
    });

    group('with an error', () {
      test('reports the error', () async {
        var engine = declareEngine(() {
          setUpAll(() {
            addTearDown(() => throw TestFailure('fail'));
          });

          test('test', () {});
        });

        var queue = StreamQueue(engine.onTestStarted);
        unawaited(queue.skip(2));
        var liveTestFuture = queue.next;

        expect(await engine.run(), isFalse);

        var liveTest = await liveTestFuture;
        expect(liveTest.test.name, equals('(tearDownAll)'));
        expectTestFailed(liveTest, 'fail');
      });

      test('runs further tearDowns', () async {
        // Declare this in the outer test so if it doesn't run, the outer test
        // will fail.
        var shouldRun = expectAsync0(() {});

        var engine = declareEngine(() {
          setUpAll(() {
            addTearDown(() => throw 'error');
            addTearDown(shouldRun);
          });

          test('test', () {});
        });

        expect(await engine.run(), isFalse);
      });

      test('runs further tearDownAlls', () async {
        // Declare this in the outer test so if it doesn't run, the outer test
        // will fail.
        var shouldRun = expectAsync0(() {});

        var engine = declareEngine(() {
          tearDownAll(shouldRun);

          setUpAll(() {
            addTearDown(() => throw 'error');
          });

          test('test', () {});
        });

        expect(await engine.run(), isFalse);
      });
    });
  });
}
