// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';

import '../../src/common.dart';

void main() {
  group('throwToolExit', () {
    test('throws ToolExit', () {
      expect(() => throwToolExit('message'), throwsToolExit());
    });

    test('throws ToolExit with exitCode', () {
      expect(() => throwToolExit('message', exitCode: 42), throwsToolExit(exitCode: 42));
    });

    test('throws ToolExit with message', () {
      expect(() => throwToolExit('message'), throwsToolExit(message: 'message'));
    });

    test('throws ToolExit with message and exit code', () {
      expect(
        () => throwToolExit('message', exitCode: 42),
        throwsToolExit(exitCode: 42, message: 'message'),
      );
    });

    testWithoutContext('Throws if accessing the Zone', () {
      expect(() => context.get<Object>(), throwsUnsupportedError);
    });
  });

  group('FutureErrorHandling', () {
    test('does not invoke onError when future completes with a value', () async {
      var errorCalled = false;
      await Future<int>.value(42).handleError((Object error, StackTrace stackTrace) {
        errorCalled = true;
      });
      expect(errorCalled, isFalse);
    });

    test(
      'invokes onError with error and stack trace when future completes with an error',
      () async {
        Object? capturedError;
        StackTrace? capturedStackTrace;
        final exception = Exception('test failure');
        final StackTrace stack = StackTrace.current;

        await Future<void>.error(exception, stack).handleError((
          Object error,
          StackTrace stackTrace,
        ) {
          capturedError = error;
          capturedStackTrace = stackTrace;
        });

        expect(capturedError, same(exception));
        expect(capturedStackTrace, same(stack));
      },
    );

    test('invokes onError when test predicate returns true', () async {
      var errorCalled = false;
      const exception = FormatException('invalid format');

      await Future<void>.error(exception).handleError((Object error, StackTrace stackTrace) {
        errorCalled = true;
      }, test: (Object error) => error is FormatException);

      expect(errorCalled, isTrue);
    });

    test('does not invoke onError and rethrows original error and stack trace when test predicate returns false', () async {
      var errorCalled = false;
      final exception = Exception('other exception');
      final StackTrace stack = StackTrace.current;

      Object? rethrownError;
      StackTrace? rethrownStackTrace;
      try {
        await Future<void>.error(exception, stack).handleError((
          Object error,
          StackTrace stackTrace,
        ) {
          errorCalled = true;
        }, test: (Object error) => error is FormatException);
      } on Object catch (error, stackTrace) {
        rethrownError = error;
        rethrownStackTrace = stackTrace;
      }

      expect(errorCalled, isFalse);
      expect(rethrownError, same(exception));
      expect(rethrownStackTrace, same(stack));
    });
  });
}
