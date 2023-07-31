// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('without being canceled', () {
    late CancelableCompleter completer;
    setUp(() {
      completer = CancelableCompleter(onCancel: expectAsync0(() {}, count: 0));
    });

    test('sends values to the future', () {
      expect(completer.operation.value, completion(equals(1)));
      expect(completer.isCompleted, isFalse);
      completer.complete(1);
      expect(completer.isCompleted, isTrue);
    });

    test('sends null values to the future', () {
      expect(completer.operation.value, completion(equals(null)));
      expect(completer.isCompleted, isFalse);
      completer.complete(null);
      expect(completer.isCompleted, isTrue);
    });

    test('sends errors to the future', () {
      expect(completer.operation.value, throwsA('error'));
      expect(completer.isCompleted, isFalse);
      completer.completeError('error');
      expect(completer.isCompleted, isTrue);
    });

    test('sends values in a future to the future', () {
      expect(completer.operation.value, completion(equals(1)));
      expect(completer.isCompleted, isFalse);
      completer.complete(Future.value(1));
      expect(completer.isCompleted, isTrue);
    });

    test('sends errors in a future to the future', () async {
      expect(completer.operation.value, throwsA('error'));
      expect(completer.isCompleted, isFalse);
      expect(completer.operation.isCompleted, isFalse);
      completer.complete(Future.error('error'));
      expect(completer.isCompleted, isTrue);
      await flushMicrotasks();
      expect(completer.operation.isCompleted, isTrue);
    });

    test('sends values from a cancelable operation to the future', () {
      expect(completer.operation.value, completion(equals(1)));
      completer
          .completeOperation(CancelableOperation.fromFuture(Future.value(1)));
    });

    test('sends values from a completed cancelable operation to the future',
        () async {
      final operation = CancelableOperation.fromFuture(Future.value(1));
      await operation.value;
      expect(completer.operation.value, completion(equals(1)));
      completer.completeOperation(operation);
    });

    test('sends errors from a cancelable operation to the future', () {
      expect(completer.operation.value, throwsA('error'));
      completer.completeOperation(
          CancelableOperation.fromFuture(Future.error('error')..ignore()));
    });

    test('sends errors from a completed cancelable operation to the future',
        () async {
      final operation =
          CancelableOperation.fromFuture(Future.error('error')..ignore());
      try {
        await operation.value;
      } on Object {
        // ignore
      }
      expect(completer.operation.value, throwsA('error'));
      completer.completeOperation(operation);
    });

    test('sends values to valueOrCancellation', () {
      expect(completer.operation.valueOrCancellation(), completion(equals(1)));
      completer.complete(1);
    });

    test('sends errors to valueOrCancellation', () {
      expect(completer.operation.valueOrCancellation(), throwsA('error'));
      completer.completeError('error');
    });

    test('chains null values through .then calls', () async {
      var operation = CancelableOperation.fromFuture(Future.value(null));
      expect(await operation.then((_) {}).value, null);
    });

    test('is not complete until the result is available', () async {
      var backingWork = Completer();
      var operation = CancelableOperation.fromFuture(backingWork.future);
      expect(operation.isCompleted, isFalse);
      backingWork.complete();
      await backingWork.future;
      expect(operation.isCompleted, isTrue);
    });

    group('throws a StateError if completed', () {
      test('successfully twice', () {
        completer.complete(1);
        expect(() => completer.complete(1), throwsStateError);
      });

      test('successfully then unsuccessfully', () {
        completer.complete(1);
        expect(() => completer.completeError('error'), throwsStateError);
      });

      test('unsuccessfully twice', () {
        expect(completer.operation.value, throwsA('error'));
        completer.completeError('error');
        expect(() => completer.completeError('error'), throwsStateError);
      });

      test('successfully then with a future', () {
        completer.complete(1);
        expect(() => completer.complete(Completer().future), throwsStateError);
      });

      test('with a future then successfully', () {
        completer.complete(Completer().future);
        expect(() => completer.complete(1), throwsStateError);
      });

      test('with a future twice', () {
        completer.complete(Completer().future);
        expect(() => completer.complete(Completer().future), throwsStateError);
      });
    });

    group('CancelableOperation.fromFuture', () {
      test('forwards values', () {
        var operation = CancelableOperation.fromFuture(Future.value(1));
        expect(operation.value, completion(equals(1)));
      });

      test('forwards errors', () {
        var operation = CancelableOperation.fromFuture(Future.error('error'));
        expect(operation.value, throwsA('error'));
      });
    });

    group('CancelableOperation.fromSubscription', () {
      test('forwards a done event once it completes', () async {
        var controller = StreamController<void>();
        var operationCompleted = false;
        CancelableOperation.fromSubscription(controller.stream.listen(null))
            .then((_) {
          operationCompleted = true;
        });

        await flushMicrotasks();
        expect(operationCompleted, isFalse);

        controller.close();
        await flushMicrotasks();
        expect(operationCompleted, isTrue);
      });

      test('forwards errors', () {
        var operation = CancelableOperation.fromSubscription(
            Stream.error('error').listen(null));
        expect(operation.value, throwsA('error'));
      });
    });
  });

  group('when canceled', () {
    test('causes the future never to fire', () async {
      var completer = CancelableCompleter();
      completer.operation.value.whenComplete(expectAsync0(() {}, count: 0));
      completer.operation.cancel();

      // Give the future plenty of time to fire if it's going to.
      await flushMicrotasks();
      completer.complete();
      await flushMicrotasks();
    });

    test('fires onCancel', () {
      var canceled = false;
      late CancelableCompleter completer;
      completer = CancelableCompleter(onCancel: expectAsync0(() {
        expect(completer.isCanceled, isTrue);
        canceled = true;
      }));

      expect(canceled, isFalse);
      expect(completer.isCanceled, isFalse);
      expect(completer.operation.isCanceled, isFalse);
      expect(completer.isCompleted, isFalse);
      expect(completer.operation.isCompleted, isFalse);
      completer.operation.cancel();
      expect(canceled, isTrue);
      expect(completer.isCanceled, isTrue);
      expect(completer.operation.isCanceled, isTrue);
      expect(completer.isCompleted, isFalse);
      expect(completer.operation.isCompleted, isFalse);
    });

    test('returns the onCancel future each time cancel is called', () {
      var completer = CancelableCompleter(onCancel: expectAsync0(() {
        return Future.value(1);
      }));
      expect(completer.operation.cancel(), completion(equals(1)));
      expect(completer.operation.cancel(), completion(equals(1)));
      expect(completer.operation.cancel(), completion(equals(1)));
    });

    test("returns a future even if onCancel doesn't", () {
      var completer = CancelableCompleter(onCancel: expectAsync0(() {}));
      expect(completer.operation.cancel(), completes);
    });

    test("doesn't call onCancel if the completer has completed", () {
      var completer =
          CancelableCompleter(onCancel: expectAsync0(() {}, count: 0));
      completer.complete(1);
      expect(completer.operation.value, completion(equals(1)));
      expect(completer.operation.cancel(), completes);
    });

    test(
        'does call onCancel if the completer has completed to an unfired '
        'Future', () {
      var completer = CancelableCompleter(onCancel: expectAsync0(() {}));
      completer.complete(Completer().future);
      expect(completer.operation.cancel(), completes);
    });

    test(
        "doesn't call onCancel if the completer has completed to a fired "
        'Future', () async {
      var completer =
          CancelableCompleter(onCancel: expectAsync0(() {}, count: 0));
      completer.complete(Future.value(1));
      await completer.operation.value;
      expect(completer.operation.cancel(), completes);
    });

    test('can be completed once after being canceled', () async {
      var completer = CancelableCompleter();
      completer.operation.value.whenComplete(expectAsync0(() {}, count: 0));
      await completer.operation.cancel();
      completer.complete(1);
      expect(() => completer.complete(1), throwsStateError);
    });

    test('fires valueOrCancellation with the given value', () {
      var completer = CancelableCompleter();
      expect(completer.operation.valueOrCancellation(1), completion(equals(1)));
      completer.operation.cancel();
    });

    test('pipes an error through valueOrCancellation', () {
      var completer = CancelableCompleter(onCancel: () {
        throw 'error';
      });
      expect(completer.operation.valueOrCancellation(1), throwsA('error'));
      completer.operation.cancel();
    });

    test('valueOrCancellation waits on the onCancel future', () async {
      var innerCompleter = Completer();
      var completer =
          CancelableCompleter(onCancel: () => innerCompleter.future);

      var fired = false;
      completer.operation.valueOrCancellation().then((_) {
        fired = true;
      });

      completer.operation.cancel();
      await flushMicrotasks();
      expect(fired, isFalse);

      innerCompleter.complete();
      await flushMicrotasks();
      expect(fired, isTrue);
    });

    test('CancelableOperation.fromSubscription() cancels the subscription',
        () async {
      var cancelCompleter = Completer<void>();
      var canceled = false;
      var controller = StreamController<void>(onCancel: () {
        canceled = true;
        return cancelCompleter.future;
      });
      var operation =
          CancelableOperation.fromSubscription(controller.stream.listen(null));

      await flushMicrotasks();
      expect(canceled, isFalse);

      // The `cancel()` call shouldn't complete until
      // `StreamSubscription.cancel` completes.
      var cancelCompleted = false;
      expect(
          operation.cancel().then((_) {
            cancelCompleted = true;
          }),
          completes);
      await flushMicrotasks();
      expect(canceled, isTrue);
      expect(cancelCompleted, isFalse);

      cancelCompleter.complete();
      await flushMicrotasks();
      expect(cancelCompleted, isTrue);
    });

    group('completeOperation', () {
      test('sends cancellation from a cancelable operation', () async {
        final completer = CancelableCompleter<void>();
        completer.operation.value.whenComplete(expectAsync0(() {}, count: 0));
        completer
            .completeOperation(CancelableCompleter<void>().operation..cancel());
        await completer.operation.valueOrCancellation();
        expect(completer.operation.isCanceled, true);
      });

      test('sends errors from a completed cancelable operation to the future',
          () async {
        final operation = CancelableCompleter<void>().operation..cancel();
        await operation.valueOrCancellation();
        final completer = CancelableCompleter<void>();
        completer.operation.value.whenComplete(expectAsync0(() {}, count: 0));
        completer.completeOperation(operation);
        await completer.operation.valueOrCancellation();
        expect(completer.operation.isCanceled, true);
      });

      test('propagates cancellation', () {
        final completer = CancelableCompleter<void>();
        final operation =
            CancelableCompleter<void>(onCancel: expectAsync0(() {}, count: 1))
                .operation;
        completer.completeOperation(operation);
        completer.operation.cancel();
      });

      test('propagates cancellation from already canceld completer', () async {
        final completer = CancelableCompleter<void>()..operation.cancel();
        await completer.operation.valueOrCancellation();
        final operation =
            CancelableCompleter<void>(onCancel: expectAsync0(() {}, count: 1))
                .operation;
        completer.completeOperation(operation);
      });
      test('cancel propagation can be disabled', () {
        final completer = CancelableCompleter<void>();
        final operation =
            CancelableCompleter<void>(onCancel: expectAsync0(() {}, count: 0))
                .operation;
        completer.completeOperation(operation, propagateCancel: false);
        completer.operation.cancel();
      });

      test('cancel propagation can be disabled from already canceled completed',
          () async {
        final completer = CancelableCompleter<void>()..operation.cancel();
        await completer.operation.valueOrCancellation();
        final operation =
            CancelableCompleter<void>(onCancel: expectAsync0(() {}, count: 0))
                .operation;
        completer.completeOperation(operation, propagateCancel: false);
      });
    });
  });

  group('asStream()', () {
    test('emits a value and then closes', () {
      var completer = CancelableCompleter();
      expect(completer.operation.asStream().toList(), completion(equals([1])));
      completer.complete(1);
    });

    test('emits an error and then closes', () {
      var completer = CancelableCompleter();
      var queue = StreamQueue(completer.operation.asStream());
      expect(queue.next, throwsA('error'));
      expect(queue.hasNext, completion(isFalse));
      completer.completeError('error');
    });

    test('cancels the completer when the subscription is canceled', () {
      var completer = CancelableCompleter(onCancel: expectAsync0(() {}));
      var sub =
          completer.operation.asStream().listen(expectAsync1((_) {}, count: 0));
      completer.operation.value.whenComplete(expectAsync0(() {}, count: 0));
      sub.cancel();
      expect(completer.isCanceled, isTrue);
    });
  });

  group('then', () {
    FutureOr<String> Function(int)? onValue;
    FutureOr<String> Function(Object, StackTrace)? onError;
    FutureOr<String> Function()? onCancel;
    late bool propagateCancel;
    late CancelableCompleter<int> originalCompleter;

    setUp(() {
      // Initialize all functions to ones that expect to not be called.
      onValue = expectAsync1((_) => 'Fake', count: 0, id: 'onValue');
      onError = expectAsync2((e, s) => 'Fake', count: 0, id: 'onError');
      onCancel = expectAsync0(() => 'Fake', count: 0, id: 'onCancel');
      propagateCancel = false;
      originalCompleter = CancelableCompleter();
    });

    CancelableOperation<String> runThen() {
      return originalCompleter.operation.then(onValue!,
          onError: onError,
          onCancel: onCancel,
          propagateCancel: propagateCancel);
    }

    group('original operation completes successfully', () {
      test('onValue completes successfully', () {
        onValue = expectAsync1((v) => v.toString(), count: 1, id: 'onValue');

        expect(runThen().value, completion('1'));
        originalCompleter.complete(1);
      });

      test('onValue throws error', () {
        // expectAsync1 only works with functions that do not throw.
        onValue = (_) => throw 'error';

        expect(runThen().value, throwsA('error'));
        originalCompleter.complete(1);
      });

      test('onValue returns Future that throws error', () {
        onValue =
            expectAsync1((v) => Future.error('error'), count: 1, id: 'onValue');

        expect(runThen().value, throwsA('error'));
        originalCompleter.complete(1);
      });

      test('and returned operation is canceled with propagateCancel = false',
          () async {
        propagateCancel = false;

        runThen().cancel();

        // onValue should not be called.
        originalCompleter.complete(1);
      });
    });

    group('original operation completes with error', () {
      test('onError not set', () {
        onError = null;

        expect(runThen().value, throwsA('error'));
        originalCompleter.completeError('error');
      });

      test('onError completes successfully', () {
        onError = expectAsync2((e, s) => 'onError caught $e',
            count: 1, id: 'onError');

        expect(runThen().value, completion('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('onError throws', () {
        // expectAsync2 does not work with functions that throw.
        onError = (e, s) => throw 'onError caught $e';

        expect(runThen().value, throwsA('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('onError returns Future that throws', () {
        onError = expectAsync2((e, s) => Future.error('onError caught $e'),
            count: 1, id: 'onError');

        expect(runThen().value, throwsA('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('and returned operation is canceled with propagateCancel = false',
          () async {
        propagateCancel = false;

        runThen().cancel();

        // onError should not be called.
        originalCompleter.completeError('error');
      });
    });

    group('original operation canceled', () {
      test('onCancel not set', () async {
        onCancel = null;

        final operation = runThen();

        await expectLater(originalCompleter.operation.cancel(), completes);
        expect(operation.isCanceled, true);
      });

      test('onCancel completes successfully', () {
        onCancel = expectAsync0(() => 'canceled', count: 1, id: 'onCancel');

        expect(runThen().value, completion('canceled'));
        originalCompleter.operation.cancel();
      });

      test('onCancel throws error', () {
        // expectAsync0 only works with functions that do not throw.
        onCancel = () => throw 'error';

        expect(runThen().value, throwsA('error'));
        originalCompleter.operation.cancel();
      });

      test('onCancel returns Future that throws error', () {
        onCancel =
            expectAsync0(() => Future.error('error'), count: 1, id: 'onCancel');

        expect(runThen().value, throwsA('error'));
        originalCompleter.operation.cancel();
      });

      test('after completing with a future does not invoke `onValue`',
          () async {
        onValue = expectAsync1((_) => '', count: 0);
        onCancel = null;
        var operation = runThen();
        var workCompleter = Completer<int>();
        originalCompleter.complete(workCompleter.future);
        var cancelation = originalCompleter.operation.cancel();
        expect(originalCompleter.isCanceled, true);
        workCompleter.complete(0);
        await cancelation;
        expect(operation.isCanceled, true);
        await workCompleter.future;
      });

      test('after the value is completed invokes `onValue`', () {
        onValue = expectAsync1((_) => 'foo', count: 1);
        onCancel = expectAsync1((_) => '', count: 0);
        originalCompleter.complete(0);
        originalCompleter.operation.cancel();
        var operation = runThen();
        expect(operation.value, completion('foo'));
        expect(operation.isCanceled, false);
      });
    });

    group('returned operation canceled', () {
      test('propagateCancel is true', () async {
        propagateCancel = true;

        await runThen().cancel();

        expect(originalCompleter.isCanceled, true);
      });

      test('propagateCancel is false', () async {
        propagateCancel = false;

        await runThen().cancel();

        expect(originalCompleter.isCanceled, false);
      });

      test('onValue callback not called after cancel', () async {
        var called = false;
        onValue = expectAsync1((_) {
          called = true;
          fail('onValue unreachable');
        }, count: 0);

        await runThen().cancel();
        originalCompleter.complete(0);
        await flushMicrotasks();
        expect(called, false);
      });

      test('onError callback not called after cancel', () async {
        var called = false;
        onError = expectAsync2((_, __) {
          called = true;
          fail('onError unreachable');
        }, count: 0);

        await runThen().cancel();
        originalCompleter.completeError('Error', StackTrace.empty);
        await flushMicrotasks();
        expect(called, false);
      });

      test('onCancel callback not called after cancel', () async {
        var called = false;
        onCancel = expectAsync0(() {
          called = true;
          fail('onCancel unreachable');
        }, count: 0);

        await runThen().cancel();
        await originalCompleter.operation.cancel();
        await flushMicrotasks();
        expect(called, false);
      });
    });
  });

  group('thenOperation', () {
    late void Function(int, CancelableCompleter<String>) onValue;
    void Function(Object, StackTrace, CancelableCompleter<String>)? onError;
    void Function(CancelableCompleter<String>)? onCancel;
    late bool propagateCancel;
    late CancelableCompleter<int> originalCompleter;

    setUp(() {
      // Initialize all functions to ones that expect to not be called.
      onValue = expectAsync2((value, completer) => completer.complete('$value'),
          count: 0, id: 'onValue');
      onError = null;
      onCancel = null;
      propagateCancel = false;
      originalCompleter = CancelableCompleter();
    });

    CancelableOperation<String> runThenOperation() {
      return originalCompleter.operation.thenOperation(onValue,
          onError: onError,
          onCancel: onCancel,
          propagateCancel: propagateCancel);
    }

    group('original operation completes successfully', () {
      test('onValue completes successfully', () {
        onValue =
            expectAsync2((v, c) => c.complete('$v'), count: 1, id: 'onValue');

        expect(runThenOperation().value, completion('1'));
        originalCompleter.complete(1);
      });

      test('onValue throws error', () {
        // expectAsync1 only works with functions that do not throw.
        onValue = (_, __) => throw 'error';

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.complete(1);
      });

      test('onValue completes operation as error', () {
        onValue = expectAsync2(
            (_, completer) => completer.completeError('error'),
            count: 1,
            id: 'onValue');

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.complete(1);
      });

      test('onValue returns a Future that throws error', () {
        onValue = expectAsync2((_, completer) => Future.error('error'),
            count: 1, id: 'onValue');

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.complete(1);
      });

      test('and returned operation is canceled', () async {
        onValue = expectAsync2((_, __) => throw 'never called', count: 0);
        runThenOperation().cancel();
        // onValue should not be called.
        originalCompleter.complete(1);
      });
    });

    group('original operation completes with error', () {
      test('onError not set', () {
        onError = null;

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.completeError('error');
      });

      test('onError completes operation', () {
        onError = expectAsync3((e, s, c) => c.complete('onError caught $e'),
            count: 1, id: 'onError');

        expect(runThenOperation().value, completion('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('onError throws', () {
        // expectAsync3 does not work with functions that throw.
        onError = (e, s, c) => throw 'onError caught $e';

        expect(runThenOperation().value, throwsA('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('onError returns Future that throws error', () {
        onError = expectAsync3((e, s, c) => Future.error('onError caught $e'),
            count: 1, id: 'onError');

        expect(runThenOperation().value, throwsA('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('onError completes operation as an error', () {
        onError = expectAsync3(
            (e, s, c) => c.completeError('onError caught $e'),
            count: 1,
            id: 'onError');

        expect(runThenOperation().value, throwsA('onError caught error'));
        originalCompleter.completeError('error');
      });

      test('and returned operation is canceled with propagateCancel = false',
          () async {
        onError = expectAsync3((e, s, c) {}, count: 0);

        runThenOperation().cancel();

        // onError should not be called.
        originalCompleter.completeError('error');
      });
    });

    group('original operation canceled', () {
      test('onCancel not set', () async {
        onCancel = null;

        final operation = runThenOperation();

        await expectLater(originalCompleter.operation.cancel(), completes);
        expect(operation.isCanceled, true);
      });

      test('onCancel completes successfully', () {
        onCancel = expectAsync1((c) => c.complete('canceled'),
            count: 1, id: 'onCancel');

        expect(runThenOperation().value, completion('canceled'));
        originalCompleter.operation.cancel();
      });

      test('onCancel throws error', () {
        // expectAsync0 only works with functions that do not throw.
        onCancel = (_) => throw 'error';

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.operation.cancel();
      });

      test('onCancel completes operation as error', () {
        onCancel = expectAsync1((c) => c.completeError('error'),
            count: 1, id: 'onCancel');

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.operation.cancel();
      });

      test('onCancel returns Future that throws error', () {
        onCancel = expectAsync1((c) => Future.error('error'),
            count: 1, id: 'onCancel');

        expect(runThenOperation().value, throwsA('error'));
        originalCompleter.operation.cancel();
      });

      test('after completing with a future does not invoke `onValue`',
          () async {
        onValue = expectAsync2((_, __) {}, count: 0);
        onCancel = null;
        var operation = runThenOperation();
        var workCompleter = Completer<int>();
        originalCompleter.complete(workCompleter.future);
        var cancelation = originalCompleter.operation.cancel();
        expect(originalCompleter.isCanceled, true);
        workCompleter.complete(0);
        await cancelation;
        expect(operation.isCanceled, true);
        await workCompleter.future;
      });

      test('after the value is completed invokes `onValue`', () {
        onValue = expectAsync2((v, c) => c.complete('foo'), count: 1);
        onCancel = expectAsync1((_) {}, count: 0);
        originalCompleter.complete(0);
        originalCompleter.operation.cancel();
        var operation = runThenOperation();
        expect(operation.value, completion('foo'));
        expect(operation.isCanceled, false);
      });
    });

    group('returned operation canceled', () {
      test('propagateCancel is true', () async {
        propagateCancel = true;

        await runThenOperation().cancel();

        expect(originalCompleter.isCanceled, true);
      });

      test('propagateCancel is false', () async {
        propagateCancel = false;

        await runThenOperation().cancel();

        expect(originalCompleter.isCanceled, false);
      });

      test('onValue callback not called after cancel', () async {
        onValue = expectAsync2((_, c) {}, count: 0);

        await runThenOperation().cancel();
        originalCompleter.complete(0);
      });

      test('onError callback not called after cancel', () async {
        onError = expectAsync3((_, __, ___) {}, count: 0);

        await runThenOperation().cancel();
        originalCompleter.completeError('Error', StackTrace.empty);
      });

      test('onCancel callback not called after cancel', () async {
        onCancel = expectAsync1((_) {}, count: 0);

        await runThenOperation().cancel();
        await originalCompleter.operation.cancel();
      });
    });
  });

  group('race()', () {
    late bool canceled1;
    late CancelableCompleter<int> completer1;
    late bool canceled2;
    late CancelableCompleter<int> completer2;
    late bool canceled3;
    late CancelableCompleter<int> completer3;
    late CancelableOperation<int> operation;
    setUp(() {
      canceled1 = false;
      completer1 = CancelableCompleter<int>(onCancel: () {
        canceled1 = true;
      });

      canceled2 = false;
      completer2 = CancelableCompleter<int>(onCancel: () {
        canceled2 = true;
      });

      canceled3 = false;
      completer3 = CancelableCompleter<int>(onCancel: () {
        canceled3 = true;
      });

      operation = CancelableOperation.race(
          [completer1.operation, completer2.operation, completer3.operation]);
    });

    test('returns the first value to complete', () {
      completer1.complete(1);
      completer2.complete(2);
      completer3.complete(3);

      expect(operation.value, completion(equals(1)));
    });

    test('throws the first error to complete', () {
      completer1.completeError('error 1');
      completer2.completeError('error 2');
      completer3.completeError('error 3');

      expect(operation.value, throwsA('error 1'));
    });

    test('cancels any completers that haven\'t completed', () async {
      completer1.complete(1);
      await expectLater(operation.value, completion(equals(1)));
      expect(canceled1, isFalse);
      expect(canceled2, isTrue);
      expect(canceled3, isTrue);
    });

    test('cancels all completers when the operation is completed', () async {
      await operation.cancel();

      expect(canceled1, isTrue);
      expect(canceled2, isTrue);
      expect(canceled3, isTrue);
    });
  });
}
