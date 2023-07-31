// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: only_throw_errors

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:test_api/hooks_testing.dart';

import 'utils_new.dart';

void main() {
  group('supports a function with this many arguments:', () {
    test('0', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync0(() {
          callbackRun = true;
        })();
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('1', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync1((int arg) {
          expect(arg, equals(1));
          callbackRun = true;
        })(1);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('2', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync2((arg1, arg2) {
          expect(arg1, equals(1));
          expect(arg2, equals(2));
          callbackRun = true;
        })(1, 2);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('3', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync3((arg1, arg2, arg3) {
          expect(arg1, equals(1));
          expect(arg2, equals(2));
          expect(arg3, equals(3));
          callbackRun = true;
        })(1, 2, 3);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('4', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync4((arg1, arg2, arg3, arg4) {
          expect(arg1, equals(1));
          expect(arg2, equals(2));
          expect(arg3, equals(3));
          expect(arg4, equals(4));
          callbackRun = true;
        })(1, 2, 3, 4);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('5', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync5((arg1, arg2, arg3, arg4, arg5) {
          expect(arg1, equals(1));
          expect(arg2, equals(2));
          expect(arg3, equals(3));
          expect(arg4, equals(4));
          expect(arg5, equals(5));
          callbackRun = true;
        })(1, 2, 3, 4, 5);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('6', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync6((arg1, arg2, arg3, arg4, arg5, arg6) {
          expect(arg1, equals(1));
          expect(arg2, equals(2));
          expect(arg3, equals(3));
          expect(arg4, equals(4));
          expect(arg5, equals(5));
          expect(arg6, equals(6));
          callbackRun = true;
        })(1, 2, 3, 4, 5, 6);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });
  });

  group('with optional arguments', () {
    test('allows them to be passed', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync1(([arg = 1]) {
          expect(arg, equals(2));
          callbackRun = true;
        })(2);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('allows them not to be passed', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        expectAsync1(([arg = 1]) {
          expect(arg, equals(1));
          callbackRun = true;
        })();
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });
  });

  group('by default', () {
    test("won't allow the test to complete until it's called", () async {
      late void Function() callback;
      final monitor = TestCaseMonitor.start(() {
        callback = expectAsync0(() {});
      });

      await pumpEventQueue();
      expect(monitor.state, equals(State.running));
      callback();
      await monitor.onDone;

      expectTestPassed(monitor);
    });

    test('may only be called once', () async {
      var monitor = await TestCaseMonitor.run(() {
        var callback = expectAsync0(() {});
        callback();
        callback();
      });

      expectTestFailed(
          monitor, 'Callback called more times than expected (1).');
    });
  });

  group('with count', () {
    test(
        "won't allow the test to complete until it's called at least that "
        'many times', () async {
      late void Function() callback;
      final monitor = TestCaseMonitor.start(() {
        callback = expectAsync0(() {}, count: 3);
      });

      await pumpEventQueue();
      expect(monitor.state, equals(State.running));
      callback();

      await pumpEventQueue();
      expect(monitor.state, equals(State.running));
      callback();

      await pumpEventQueue();
      expect(monitor.state, equals(State.running));
      callback();

      await monitor.onDone;

      expectTestPassed(monitor);
    });

    test("will throw an error if it's called more than that many times",
        () async {
      var monitor = await TestCaseMonitor.run(() {
        var callback = expectAsync0(() {}, count: 3);
        callback();
        callback();
        callback();
        callback();
      });

      expectTestFailed(
          monitor, 'Callback called more times than expected (3).');
    });

    group('0,', () {
      test("won't block the test's completion", () {
        expectAsync0(() {}, count: 0);
      });

      test("will throw an error if it's ever called", () async {
        var monitor = await TestCaseMonitor.run(() {
          expectAsync0(() {}, count: 0)();
        });

        expectTestFailed(
            monitor, 'Callback called more times than expected (0).');
      });
    });
  });

  group('with max', () {
    test('will allow the callback to be called that many times', () {
      var callback = expectAsync0(() {}, max: 3);
      callback();
      callback();
      callback();
    });

    test('will allow the callback to be called fewer than that many times', () {
      var callback = expectAsync0(() {}, max: 3);
      callback();
    });

    test("will throw an error if it's called more than that many times",
        () async {
      var monitor = await TestCaseMonitor.run(() {
        var callback = expectAsync0(() {}, max: 3);
        callback();
        callback();
        callback();
        callback();
      });

      expectTestFailed(
          monitor, 'Callback called more times than expected (3).');
    });

    test('-1, will allow the callback to be called any number of times', () {
      var callback = expectAsync0(() {}, max: -1);
      for (var i = 0; i < 20; i++) {
        callback();
      }
    });
  });

  test('will throw an error if max is less than count', () {
    expect(() => expectAsync0(() {}, max: 1, count: 2), throwsArgumentError);
  });

  group('expectAsyncUntil()', () {
    test("won't allow the test to complete until isDone returns true",
        () async {
      late TestCaseMonitor monitor;
      late Future future;
      monitor = TestCaseMonitor.start(() {
        var done = false;
        var callback = expectAsyncUntil0(() {}, () => done);

        future = () async {
          await pumpEventQueue();
          expect(monitor.state, equals(State.running));
          callback();
          await pumpEventQueue();
          expect(monitor.state, equals(State.running));
          done = true;
          callback();
        }();
      });
      await monitor.onDone;

      expectTestPassed(monitor);
      // Ensure that the outer test doesn't complete until the inner future
      // completes.
      await future;
    });

    test("doesn't call isDone until after the callback is called", () {
      var callbackRun = false;
      expectAsyncUntil0(() => callbackRun = true, () {
        expect(callbackRun, isTrue);
        return true;
      })();
    });
  });

  test('allows errors', () async {
    var monitor = await TestCaseMonitor.run(() {
      expect(expectAsync0(() => throw 'oh no'), throwsA('oh no'));
    });

    expectTestPassed(monitor);
  });

  test('may be called in a non-test zone', () async {
    var monitor = await TestCaseMonitor.run(() {
      var callback = expectAsync0(() {});
      Zone.root.run(callback);
    });
    expectTestPassed(monitor);
  });

  test('may be called in a FakeAsync zone that does not run further', () async {
    var monitor = await TestCaseMonitor.run(() {
      FakeAsync().run((_) {
        var callback = expectAsync0(() {});
        callback();
      });
    });
    expectTestPassed(monitor);
  });

  group('old-style expectAsync()', () {
    test('works with no arguments', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        // ignore: deprecated_member_use_from_same_package
        expectAsync(() {
          callbackRun = true;
        })();
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('works with dynamic arguments', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        // ignore: deprecated_member_use_from_same_package
        expectAsync((arg1, arg2) {
          callbackRun = true;
        })(1, 2);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('works with non-nullable arguments', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        // ignore: deprecated_member_use_from_same_package
        expectAsync((int arg1, int arg2) {
          callbackRun = true;
        })(1, 2);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test('works with 6 arguments', () async {
      var callbackRun = false;
      var monitor = await TestCaseMonitor.run(() {
        // ignore: deprecated_member_use_from_same_package
        expectAsync((arg1, arg2, arg3, arg4, arg5, arg6) {
          callbackRun = true;
        })(1, 2, 3, 4, 5, 6);
      });

      expectTestPassed(monitor);
      expect(callbackRun, isTrue);
    });

    test("doesn't support a function with 7 arguments", () {
      // ignore: deprecated_member_use_from_same_package
      expect(() => expectAsync((a, b, c, d, e, f, g) {}), throwsArgumentError);
    });
  });
}
