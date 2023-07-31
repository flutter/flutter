// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_api/hooks_testing.dart';

import '../utils_new.dart';

void main() {
  group('[doesNotComplete]', () {
    test('fails when provided a non future', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(10, doesNotComplete);
      });

      expectTestFailed(monitor, contains('10 is not a Future'));
    });

    test('succeeds when a future does not complete', () {
      var completer = Completer();
      expect(completer.future, doesNotComplete);
    });

    test('fails when a future does complete', () async {
      var monitor = await TestCaseMonitor.run(() {
        var completer = Completer();
        completer.complete(null);
        expect(completer.future, doesNotComplete);
      });

      expectTestFailed(
          monitor,
          'Future was not expected to complete but completed with a value of'
          ' null');
    });

    test('fails when a future completes after the expect', () async {
      var monitor = await TestCaseMonitor.run(() {
        var completer = Completer();
        expect(completer.future, doesNotComplete);
        completer.complete(null);
      });

      expectTestFailed(
          monitor,
          'Future was not expected to complete but completed with a value of'
          ' null');
    });

    test('fails when a future eventually completes', () async {
      var monitor = await TestCaseMonitor.run(() {
        var completer = Completer();
        expect(completer.future, doesNotComplete);
        Future(() async {
          await pumpEventQueue(times: 10);
        }).then(completer.complete);
      });

      expectTestFailed(
          monitor,
          'Future was not expected to complete but completed with a value of'
          ' null');
    });
  });
  group('[completes]', () {
    test('blocks the test until the Future completes', () async {
      final completer = Completer<void>();
      final monitor = TestCaseMonitor.start(() {
        expect(completer.future, completes);
      });
      await pumpEventQueue();
      expect(monitor.state, State.running);
      completer.complete();
      await monitor.onDone;
      expectTestPassed(monitor);
    });

    test('with an error', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(Future.error('X'), completes);
      });

      expect(monitor.state, equals(State.failed));
      expect(monitor.errors, [isAsyncError(equals('X'))]);
    });

    test('with a failure', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(Future.error(TestFailure('oh no')), completes);
      });

      expectTestFailed(monitor, 'oh no');
    });

    test('with a non-future', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(10, completes);
      });

      expectTestFailed(
          monitor,
          'Expected: completes successfully\n'
          '  Actual: <10>\n'
          '   Which: was not a Future\n');
    });

    test('with a successful future', () {
      expect(Future.value('1'), completes);
    });
  });

  group('[completion]', () {
    test('blocks the test until the Future completes', () async {
      final completer = Completer<Object?>();
      final monitor = TestCaseMonitor.start(() {
        expect(completer.future, completion(isNull));
      });
      await pumpEventQueue();
      expect(monitor.state, State.running);
      completer.complete(null);
      await monitor.onDone;
      expectTestPassed(monitor);
    });

    test('with an error', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(Future.error('X'), completion(isNull));
      });

      expect(monitor.state, equals(State.failed));
      expect(monitor.errors, [isAsyncError(equals('X'))]);
    });

    test('with a failure', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(Future.error(TestFailure('oh no')), completion(isNull));
      });

      expectTestFailed(monitor, 'oh no');
    });

    test('with a non-future', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(10, completion(equals(10)));
      });

      expectTestFailed(
          monitor,
          'Expected: completes to a value that <10>\n'
          '  Actual: <10>\n'
          '   Which: was not a Future\n');
    });

    test('with an incorrect value', () async {
      var monitor = await TestCaseMonitor.run(() {
        expect(Future.value('a'), completion(equals('b')));
      });

      expectTestFailed(
          monitor,
          allOf([
            startsWith("Expected: completes to a value that 'b'\n"
                '  Actual: <'),
            endsWith('>\n'
                "   Which: emitted 'a'\n"
                '            which is different.\n'
                '                  Expected: b\n'
                '                    Actual: a\n'
                '                            ^\n'
                '                   Differ at offset 0\n')
          ]));
    });

    test("blocks expectLater's Future", () async {
      var completer = Completer();
      var fired = false;
      unawaited(expectLater(completer.future, completion(equals(1))).then((_) {
        fired = true;
      }));

      await pumpEventQueue();
      expect(fired, isFalse);

      completer.complete(1);
      await pumpEventQueue();
      expect(fired, isTrue);
    });
  });
}
