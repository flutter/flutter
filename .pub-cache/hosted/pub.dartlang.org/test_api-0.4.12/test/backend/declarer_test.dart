// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/invoker.dart';
import 'package:test_api/src/backend/suite.dart';
import 'package:test_api/src/backend/test.dart';

import '../utils.dart';

late Suite _suite;

void main() {
  setUp(() {
    _suite = Suite(Group.root([]), suitePlatform, ignoreTimeouts: false);
  });

  group('.test()', () {
    test('declares a test with a description and body', () async {
      var bodyRun = false;
      var tests = declare(() {
        test('description', () {
          bodyRun = true;
        });
      });

      expect(tests, hasLength(1));
      expect(tests.single.name, equals('description'));

      await _runTest(tests[0] as Test);
      expect(bodyRun, isTrue);
    });

    test('declares a test with an object as the description', () async {
      var tests = declare(() {
        test(Object, () {});
      });

      expect(tests.single.name, equals('Object'));
    });

    test('declares multiple tests', () {
      var tests = declare(() {
        test('description 1', () {});
        test('description 2', () {});
        test('description 3', () {});
      });

      expect(tests, hasLength(3));
      expect(tests[0].name, equals('description 1'));
      expect(tests[1].name, equals('description 2'));
      expect(tests[2].name, equals('description 3'));
    });
  });

  group('.setUp()', () {
    test('is run before all tests', () async {
      var setUpRun = false;
      var tests = declare(() {
        setUp(() => setUpRun = true);

        test(
            'description 1',
            expectAsync0(() {
              expect(setUpRun, isTrue);
              setUpRun = false;
            }, max: 1));

        test(
            'description 2',
            expectAsync0(() {
              expect(setUpRun, isTrue);
              setUpRun = false;
            }, max: 1));
      });

      await _runTest(tests[0] as Test);
      await _runTest(tests[1] as Test);
    });

    test('can return a Future', () {
      var setUpRun = false;
      var tests = declare(() {
        setUp(() {
          return Future(() => setUpRun = true);
        });

        test(
            'description',
            expectAsync0(() {
              expect(setUpRun, isTrue);
            }, max: 1));
      });

      return _runTest(tests.single as Test);
    });

    test('runs in call order within a group', () async {
      var firstSetUpRun = false;
      var secondSetUpRun = false;
      var thirdSetUpRun = false;
      var tests = declare(() {
        setUp(expectAsync0(() async {
          expect(secondSetUpRun, isFalse);
          expect(thirdSetUpRun, isFalse);
          firstSetUpRun = true;
        }));

        setUp(expectAsync0(() async {
          expect(firstSetUpRun, isTrue);
          expect(thirdSetUpRun, isFalse);
          secondSetUpRun = true;
        }));

        setUp(expectAsync0(() async {
          expect(firstSetUpRun, isTrue);
          expect(secondSetUpRun, isTrue);
          thirdSetUpRun = true;
        }));

        test('description', expectAsync0(() {
          expect(firstSetUpRun, isTrue);
          expect(secondSetUpRun, isTrue);
          expect(thirdSetUpRun, isTrue);
        }));
      });

      await _runTest(tests.single as Test);
    });
  });

  group('.tearDown()', () {
    test('is run after all tests', () async {
      late bool tearDownRun;
      var tests = declare(() {
        setUp(() => tearDownRun = false);
        tearDown(() => tearDownRun = true);

        test(
            'description 1',
            expectAsync0(() {
              expect(tearDownRun, isFalse);
            }, max: 1));

        test(
            'description 2',
            expectAsync0(() {
              expect(tearDownRun, isFalse);
            }, max: 1));
      });

      await _runTest(tests[0] as Test);
      expect(tearDownRun, isTrue);
      await _runTest(tests[1] as Test);
      expect(tearDownRun, isTrue);
    });

    test('is run after an out-of-band failure', () async {
      late bool tearDownRun;
      var tests = declare(() {
        setUp(() => tearDownRun = false);
        tearDown(() => tearDownRun = true);

        test(
            'description 1',
            expectAsync0(() {
              Invoker.current!.addOutstandingCallback();
              Future(() => throw TestFailure('oh no'));
            }, max: 1));
      });

      await _runTest(tests.single as Test, shouldFail: true);
      expect(tearDownRun, isTrue);
    });

    test('can return a Future', () async {
      var tearDownRun = false;
      var tests = declare(() {
        tearDown(() {
          return Future(() => tearDownRun = true);
        });

        test(
            'description',
            expectAsync0(() {
              expect(tearDownRun, isFalse);
            }, max: 1));
      });

      await _runTest(tests.single as Test);
      expect(tearDownRun, isTrue);
    });

    test("isn't run until there are no outstanding callbacks", () async {
      var outstandingCallbackRemoved = false;
      var outstandingCallbackRemovedBeforeTeardown = false;
      var tests = declare(() {
        tearDown(() {
          outstandingCallbackRemovedBeforeTeardown = outstandingCallbackRemoved;
        });

        test('description', () {
          Invoker.current!.addOutstandingCallback();
          pumpEventQueue().then((_) {
            outstandingCallbackRemoved = true;
            Invoker.current!.removeOutstandingCallback();
          });
        });
      });

      await _runTest(tests.single as Test);
      expect(outstandingCallbackRemovedBeforeTeardown, isTrue);
    });

    test("doesn't complete until there are no outstanding callbacks", () async {
      var outstandingCallbackRemoved = false;
      var tests = declare(() {
        tearDown(() {
          Invoker.current!.addOutstandingCallback();
          pumpEventQueue().then((_) {
            outstandingCallbackRemoved = true;
            Invoker.current!.removeOutstandingCallback();
          });
        });

        test('description', () {});
      });

      await _runTest(tests.single as Test);
      expect(outstandingCallbackRemoved, isTrue);
    });

    test('runs in reverse call order within a group', () async {
      var firstTearDownRun = false;
      var secondTearDownRun = false;
      var thirdTearDownRun = false;
      var tests = declare(() {
        tearDown(expectAsync0(() async {
          expect(secondTearDownRun, isTrue);
          expect(thirdTearDownRun, isTrue);
          firstTearDownRun = true;
        }));

        tearDown(expectAsync0(() async {
          expect(firstTearDownRun, isFalse);
          expect(thirdTearDownRun, isTrue);
          secondTearDownRun = true;
        }));

        tearDown(expectAsync0(() async {
          expect(firstTearDownRun, isFalse);
          expect(secondTearDownRun, isFalse);
          thirdTearDownRun = true;
        }));

        test(
            'description',
            expectAsync0(() {
              expect(firstTearDownRun, isFalse);
              expect(secondTearDownRun, isFalse);
              expect(thirdTearDownRun, isFalse);
            }, max: 1));
      });

      await _runTest(tests.single as Test);
    });

    test('runs further tearDowns in a group even if one fails', () async {
      var tests = declare(() {
        tearDown(expectAsync0(() {}));

        tearDown(() async {
          throw 'error';
        });

        test('description', expectAsync0(() {}));
      });

      await _runTest(tests.single as Test, shouldFail: true);
    });

    test('runs in the same error zone as the test', () {
      return expectTestsPass(() {
        late Zone testBodyZone;

        tearDown(() {
          final tearDownZone = Zone.current;
          expect(tearDownZone.inSameErrorZone(testBodyZone), isTrue,
              reason: 'The tear down callback is in a different error zone '
                  'than the test body.');
        });

        test('test', () {
          testBodyZone = Zone.current;
        });
      });
    });
  });

  group('in a group,', () {
    test("tests inherit the group's description", () {
      var entries = declare(() {
        group('group', () {
          test('description', () {});
        });
      });

      expect(entries, hasLength(1));
      var testGroup = entries.single as Group;
      expect(testGroup.name, equals('group'));
      expect(testGroup.entries, hasLength(1));
      expect(testGroup.entries.single, TypeMatcher<Test>());
      expect(testGroup.entries.single.name, 'group description');
    });

    test("tests inherit the group's description when it's not a string", () {
      var entries = declare(() {
        group(Object, () {
          test('description', () {});
        });
      });

      expect(entries, hasLength(1));
      var testGroup = entries.single as Group;
      expect(testGroup.name, equals('Object'));
      expect(testGroup.entries, hasLength(1));
      expect(testGroup.entries.single, TypeMatcher<Test>());
      expect(testGroup.entries.single.name, 'Object description');
    });

    test("a test's timeout factor is applied to the group's", () {
      var entries = declare(() {
        group('group', () {
          test('test', () {}, timeout: Timeout.factor(3));
        }, timeout: Timeout.factor(2));
      });

      expect(entries, hasLength(1));
      var testGroup = entries.single as Group;
      expect(testGroup.metadata.timeout.scaleFactor, equals(2));
      expect(testGroup.entries, hasLength(1));
      expect(testGroup.entries.single, TypeMatcher<Test>());
      expect(testGroup.entries.single.metadata.timeout.scaleFactor, equals(6));
    });

    test("a test's timeout factor is applied to the group's duration", () {
      var entries = declare(() {
        group('group', () {
          test('test', () {}, timeout: Timeout.factor(2));
        }, timeout: Timeout(Duration(seconds: 10)));
      });

      expect(entries, hasLength(1));
      var testGroup = entries.single as Group;
      expect(
          testGroup.metadata.timeout.duration, equals(Duration(seconds: 10)));
      expect(testGroup.entries, hasLength(1));
      expect(testGroup.entries.single, TypeMatcher<Test>());
      expect(testGroup.entries.single.metadata.timeout.duration,
          equals(Duration(seconds: 20)));
    });

    test("a test's timeout duration is applied over the group's", () {
      var entries = declare(() {
        group('group', () {
          test('test', () {}, timeout: Timeout(Duration(seconds: 15)));
        }, timeout: Timeout(Duration(seconds: 10)));
      });

      expect(entries, hasLength(1));
      var testGroup = entries.single as Group;
      expect(
          testGroup.metadata.timeout.duration, equals(Duration(seconds: 10)));
      expect(testGroup.entries, hasLength(1));
      expect(testGroup.entries.single, TypeMatcher<Test>());
      expect(testGroup.entries.single.metadata.timeout.duration,
          equals(Duration(seconds: 15)));
    });

    test('disallows asynchronous groups', () async {
      declare(() {
        expect(() => group('group', () async {}), throwsArgumentError);
      });
    });

    group('.setUp()', () {
      test('is scoped to the group', () async {
        var setUpRun = false;
        var entries = declare(() {
          group('group', () {
            setUp(() => setUpRun = true);

            test(
                'description 1',
                expectAsync0(() {
                  expect(setUpRun, isTrue);
                  setUpRun = false;
                }, max: 1));
          });

          test(
              'description 2',
              expectAsync0(() {
                expect(setUpRun, isFalse);
                setUpRun = false;
              }, max: 1));
        });

        await _runTest((entries[0] as Group).entries.single as Test);
        await _runTest(entries[1] as Test);
      });

      test('runs from the outside in', () {
        var outerSetUpRun = false;
        var middleSetUpRun = false;
        var innerSetUpRun = false;
        var entries = declare(() {
          setUp(expectAsync0(() {
            expect(middleSetUpRun, isFalse);
            expect(innerSetUpRun, isFalse);
            outerSetUpRun = true;
          }, max: 1));

          group('middle', () {
            setUp(expectAsync0(() {
              expect(outerSetUpRun, isTrue);
              expect(innerSetUpRun, isFalse);
              middleSetUpRun = true;
            }, max: 1));

            group('inner', () {
              setUp(expectAsync0(() {
                expect(outerSetUpRun, isTrue);
                expect(middleSetUpRun, isTrue);
                innerSetUpRun = true;
              }, max: 1));

              test(
                  'description',
                  expectAsync0(() {
                    expect(outerSetUpRun, isTrue);
                    expect(middleSetUpRun, isTrue);
                    expect(innerSetUpRun, isTrue);
                  }, max: 1));
            });
          });
        });

        var middleGroup = entries.single as Group;
        var innerGroup = middleGroup.entries.single as Group;
        return _runTest(innerGroup.entries.single as Test);
      });

      test('handles Futures when chained', () {
        var outerSetUpRun = false;
        var innerSetUpRun = false;
        var entries = declare(() {
          setUp(expectAsync0(() {
            expect(innerSetUpRun, isFalse);
            return Future(() => outerSetUpRun = true);
          }, max: 1));

          group('inner', () {
            setUp(expectAsync0(() {
              expect(outerSetUpRun, isTrue);
              return Future(() => innerSetUpRun = true);
            }, max: 1));

            test(
                'description',
                expectAsync0(() {
                  expect(outerSetUpRun, isTrue);
                  expect(innerSetUpRun, isTrue);
                }, max: 1));
          });
        });

        var innerGroup = entries.single as Group;
        return _runTest(innerGroup.entries.single as Test);
      });

      test("inherits group's tags", () {
        var tests = declare(() {
          group('outer', () {
            group('inner', () {
              test('with tags', () {}, tags: 'd');
            }, tags: ['b', 'c']);
          }, tags: 'a');
        });

        var outerGroup = tests.single as Group;
        var innerGroup = outerGroup.entries.single as Group;
        var testWithTags = innerGroup.entries.single;
        expect(outerGroup.metadata.tags, unorderedEquals(['a']));
        expect(innerGroup.metadata.tags, unorderedEquals(['a', 'b', 'c']));
        expect(
            testWithTags.metadata.tags, unorderedEquals(['a', 'b', 'c', 'd']));
      });

      test('throws on invalid tags', () {
        expect(() {
          declare(() {
            group('a', () {}, tags: 1);
          });
        }, throwsArgumentError);
      });
    });

    group('.tearDown()', () {
      test('is scoped to the group', () async {
        late bool tearDownRun;
        var entries = declare(() {
          setUp(() => tearDownRun = false);

          group('group', () {
            tearDown(() => tearDownRun = true);

            test(
                'description 1',
                expectAsync0(() {
                  expect(tearDownRun, isFalse);
                }, max: 1));
          });

          test(
              'description 2',
              expectAsync0(() {
                expect(tearDownRun, isFalse);
              }, max: 1));
        });

        var testGroup = entries[0] as Group;
        await _runTest(testGroup.entries.single as Test);
        expect(tearDownRun, isTrue);
        await _runTest(entries[1] as Test);
        expect(tearDownRun, isFalse);
      });

      test('runs from the inside out', () async {
        var innerTearDownRun = false;
        var middleTearDownRun = false;
        var outerTearDownRun = false;
        var entries = declare(() {
          tearDown(expectAsync0(() {
            expect(innerTearDownRun, isTrue);
            expect(middleTearDownRun, isTrue);
            outerTearDownRun = true;
          }, max: 1));

          group('middle', () {
            tearDown(expectAsync0(() {
              expect(innerTearDownRun, isTrue);
              expect(outerTearDownRun, isFalse);
              middleTearDownRun = true;
            }, max: 1));

            group('inner', () {
              tearDown(expectAsync0(() {
                expect(outerTearDownRun, isFalse);
                expect(middleTearDownRun, isFalse);
                innerTearDownRun = true;
              }, max: 1));

              test(
                  'description',
                  expectAsync0(() {
                    expect(outerTearDownRun, isFalse);
                    expect(middleTearDownRun, isFalse);
                    expect(innerTearDownRun, isFalse);
                  }, max: 1));
            });
          });
        });

        var middleGroup = entries.single as Group;
        var innerGroup = middleGroup.entries.single as Group;
        await _runTest(innerGroup.entries.single as Test);
        expect(innerTearDownRun, isTrue);
        expect(middleTearDownRun, isTrue);
        expect(outerTearDownRun, isTrue);
      });

      test('handles Futures when chained', () async {
        var outerTearDownRun = false;
        var innerTearDownRun = false;
        var entries = declare(() {
          tearDown(expectAsync0(() {
            expect(innerTearDownRun, isTrue);
            return Future(() => outerTearDownRun = true);
          }, max: 1));

          group('inner', () {
            tearDown(expectAsync0(() {
              expect(outerTearDownRun, isFalse);
              return Future(() => innerTearDownRun = true);
            }, max: 1));

            test(
                'description',
                expectAsync0(() {
                  expect(outerTearDownRun, isFalse);
                  expect(innerTearDownRun, isFalse);
                }, max: 1));
          });
        });

        var innerGroup = entries.single as Group;
        await _runTest(innerGroup.entries.single as Test);
        expect(innerTearDownRun, isTrue);
        expect(outerTearDownRun, isTrue);
      });

      test('runs outer callbacks even when inner ones fail', () async {
        var outerTearDownRun = false;
        var entries = declare(() {
          tearDown(() {
            return Future(() => outerTearDownRun = true);
          });

          group('inner', () {
            tearDown(() {
              throw 'inner error';
            });

            test(
                'description',
                expectAsync0(() {
                  expect(outerTearDownRun, isFalse);
                }, max: 1));
          });
        });

        var innerGroup = entries.single as Group;
        await _runTest(innerGroup.entries.single as Test, shouldFail: true);
        expect(outerTearDownRun, isTrue);
      });
    });
  });

  group('duplicate names', () {
    test('can be enabled', () {
      expect(
          () => declare(() {
                test('a', expectAsync0(() {}, count: 0));
                test('a', expectAsync0(() {}, count: 0));
              }, allowDuplicateTestNames: false),
          throwsA(isA<DuplicateTestNameException>()
              .having((e) => e.name, 'name', 'a')));
    });

    test('are allowed by default', () {
      expect(
          declare(() {
            test('a', expectAsync0(() {}, count: 0));
            test('a', expectAsync0(() {}, count: 0));
          }).map((e) => e.name),
          equals(['a', 'a']));
    });
  });
}

/// Runs [test].
///
/// This automatically sets up an `onError` listener to ensure that the test
/// doesn't throw any invisible exceptions.
Future _runTest(Test test, {bool shouldFail = false}) {
  var liveTest = test.load(_suite);

  if (shouldFail) {
    liveTest.onError.listen(expectAsync1((_) {}));
  } else {
    liveTest.onError.listen((e) => registerException(e.error, e.stackTrace));
  }

  return liveTest.run();
}
