// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: only_throw_errors

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_api/hooks_testing.dart';

import '../utils_new.dart';

void main() {
  group('synchronous', () {
    group('[throws]', () {
      test('with a function that throws an error', () {
        // ignore: deprecated_member_use_from_same_package
        expect(() => throw 'oh no', throws);
      });

      test("with a function that doesn't throw", () async {
        void local() {}
        var monitor = await TestCaseMonitor.run(() {
          // ignore: deprecated_member_use_from_same_package
          expect(local, throws);
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith('Expected: throws\n'
                  '  Actual: <'),
              endsWith('>\n'
                  '   Which: returned <null>\n')
            ]));
      });

      test('with a non-function', () async {
        var monitor = await TestCaseMonitor.run(() {
          // ignore: deprecated_member_use_from_same_package
          expect(10, throws);
        });

        expectTestFailed(
            monitor,
            'Expected: throws\n'
            '  Actual: <10>\n'
            '   Which: was not a Function or Future\n');
      });
    });

    group('[throwsA]', () {
      test('with a function that throws an identical error', () {
        expect(() => throw 'oh no', throwsA('oh no'));
      });

      test('with a function that throws a matching error', () {
        expect(() => throw const FormatException('bad'),
            throwsA(isFormatException));
      });

      test("with a function that doesn't throw", () async {
        void local() {}
        var monitor = await TestCaseMonitor.run(() {
          expect(local, throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith("Expected: throws 'oh no'\n"
                  '  Actual: <'),
              endsWith('>\n'
                  '   Which: returned <null>\n')
            ]));
      });

      test('with a non-function', () async {
        var monitor = await TestCaseMonitor.run(() {
          expect(10, throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            "Expected: throws 'oh no'\n"
            '  Actual: <10>\n'
            '   Which: was not a Function or Future\n');
      });

      test('with a function that throws the wrong error', () async {
        var monitor = await TestCaseMonitor.run(() {
          expect(() => throw 'aw dang', throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith("Expected: throws 'oh no'\n"
                  '  Actual: <'),
              contains('>\n'
                  "   Which: threw 'aw dang'\n"
                  '          stack'),
              endsWith('          which is different.\n'
                  '                Expected: oh no\n'
                  '                  Actual: aw dang\n'
                  '                          ^\n'
                  '                 Differ at offset 0\n')
            ]));
      });
    });
  });

  group('asynchronous', () {
    group('[throws]', () {
      test('with a Future that throws an error', () {
        // ignore: deprecated_member_use_from_same_package
        expect(Future.error('oh no'), throws);
      });

      test("with a Future that doesn't throw", () async {
        var monitor = await TestCaseMonitor.run(() {
          // ignore: deprecated_member_use_from_same_package
          expect(Future.value(), throws);
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith('Expected: throws\n'
                  '  Actual: <'),
              endsWith('>\n'
                  '   Which: emitted <null>\n')
            ]));
      });

      test('with a closure that returns a Future that throws an error', () {
        // ignore: deprecated_member_use_from_same_package
        expect(() => Future.error('oh no'), throws);
      });

      test("with a closure that returns a Future that doesn't throw", () async {
        var monitor = await TestCaseMonitor.run(() {
          // ignore: deprecated_member_use_from_same_package
          expect(Future.value, throws);
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith('Expected: throws\n'
                  '  Actual: <'),
              endsWith('>\n'
                  '   Which: returned a Future that emitted <null>\n')
            ]));
      });

      test("won't let the test end until the Future completes", () async {
        late void Function() callback;
        final monitor = TestCaseMonitor.start(() {
          final completer = Completer<void>();
          // ignore: deprecated_member_use_from_same_package
          expect(completer.future, throws);
          callback = () => completer.completeError('oh no');
        });
        await pumpEventQueue();
        expect(monitor.state, State.running);
        callback();
        await monitor.onDone;
        expectTestPassed(monitor);
      });
    });

    group('[throwsA]', () {
      test('with a Future that throws an identical error', () {
        expect(Future.error('oh no'), throwsA('oh no'));
      });

      test('with a Future that throws a matching error', () {
        expect(Future.error(const FormatException('bad')),
            throwsA(isFormatException));
      });

      test("with a Future that doesn't throw", () async {
        var monitor = await TestCaseMonitor.run(() {
          expect(Future.value(), throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith("Expected: throws 'oh no'\n"
                  '  Actual: <'),
              endsWith('>\n'
                  '   Which: emitted <null>\n')
            ]));
      });

      test('with a Future that throws the wrong error', () async {
        var monitor = await TestCaseMonitor.run(() {
          expect(Future.error('aw dang'), throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith("Expected: throws 'oh no'\n"
                  '  Actual: <'),
              contains('>\n'
                  "   Which: threw 'aw dang'\n")
            ]));
      });

      test('with a closure that returns a Future that throws a matching error',
          () {
        expect(() => Future.error(const FormatException('bad')),
            throwsA(isFormatException));
      });

      test("with a closure that returns a Future that doesn't throw", () async {
        var monitor = await TestCaseMonitor.run(() {
          expect(Future.value, throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith("Expected: throws 'oh no'\n"
                  '  Actual: <'),
              endsWith('>\n'
                  '   Which: returned a Future that emitted <null>\n')
            ]));
      });

      test('with closure that returns a Future that throws the wrong error',
          () async {
        var monitor = await TestCaseMonitor.run(() {
          expect(() => Future.error('aw dang'), throwsA('oh no'));
        });

        expectTestFailed(
            monitor,
            allOf([
              startsWith("Expected: throws 'oh no'\n"
                  '  Actual: <'),
              contains('>\n'
                  "   Which: threw 'aw dang'\n")
            ]));
      });

      test("won't let the test end until the Future completes", () async {
        late void Function() callback;
        final monitor = TestCaseMonitor.start(() {
          final completer = Completer<void>();
          expect(completer.future, throwsA('oh no'));
          callback = () => completer.completeError('oh no');
        });
        await pumpEventQueue();
        expect(monitor.state, State.running);
        callback();
        await monitor.onDone;

        expectTestPassed(monitor);
      });

      test("blocks expectLater's Future", () async {
        var completer = Completer();
        var fired = false;
        unawaited(expectLater(completer.future, throwsArgumentError).then((_) {
          fired = true;
        }));

        await pumpEventQueue();
        expect(fired, isFalse);

        completer.completeError(ArgumentError('oh no'));
        await pumpEventQueue();
        expect(fired, isTrue);
      });
    });
  });
}
