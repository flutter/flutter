// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('with no callbacks', () {
    test('forwards cancellation', () async {
      var isCanceled = false;
      var cancelCompleter = Completer<void>();
      var controller =
          StreamController(onCancel: expectAsync0<Future<void>>(() {
        isCanceled = true;
        return cancelCompleter.future;
      }));
      var subscription = controller.stream
          .transform(subscriptionTransformer())
          .listen(expectAsync1((_) {}, count: 0));

      var cancelFired = false;
      subscription.cancel().then(expectAsync1((_) {
        cancelFired = true;
      }));

      await flushMicrotasks();
      expect(isCanceled, isTrue);
      expect(cancelFired, isFalse);

      cancelCompleter.complete();
      await flushMicrotasks();
      expect(cancelFired, isTrue);

      // This shouldn't call the onCancel callback again.
      expect(subscription.cancel(), completes);
    });

    test('forwards pausing and resuming', () async {
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer())
          .listen(expectAsync1((_) {}, count: 0));

      subscription.pause();
      await flushMicrotasks();
      expect(controller.isPaused, isTrue);

      subscription.pause();
      await flushMicrotasks();
      expect(controller.isPaused, isTrue);

      subscription.resume();
      await flushMicrotasks();
      expect(controller.isPaused, isTrue);

      subscription.resume();
      await flushMicrotasks();
      expect(controller.isPaused, isFalse);
    });

    test('forwards pausing with a resume future', () async {
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer())
          .listen(expectAsync1((_) {}, count: 0));

      var completer = Completer();
      subscription.pause(completer.future);
      await flushMicrotasks();
      expect(controller.isPaused, isTrue);

      completer.complete();
      await flushMicrotasks();
      expect(controller.isPaused, isFalse);
    });
  });

  group('with a cancel callback', () {
    test('invokes the callback when the subscription is canceled', () async {
      var isCanceled = false;
      var callbackInvoked = false;
      var controller = StreamController(onCancel: expectAsync0(() {
        isCanceled = true;
      }));
      var subscription = controller.stream.transform(
          subscriptionTransformer(handleCancel: expectAsync1((inner) {
        callbackInvoked = true;
        inner.cancel();
        return Future.value();
      }))).listen(expectAsync1((_) {}, count: 0));

      await flushMicrotasks();
      expect(callbackInvoked, isFalse);
      expect(isCanceled, isFalse);

      subscription.cancel();
      await flushMicrotasks();
      expect(callbackInvoked, isTrue);
      expect(isCanceled, isTrue);
    });

    test('invokes the callback once and caches its result', () async {
      var completer = Completer();
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer(
              handleCancel: expectAsync1((inner) => completer.future)))
          .listen(expectAsync1((_) {}, count: 0));

      var cancelFired1 = false;
      subscription.cancel().then(expectAsync1((_) {
        cancelFired1 = true;
      }));

      var cancelFired2 = false;
      subscription.cancel().then(expectAsync1((_) {
        cancelFired2 = true;
      }));

      await flushMicrotasks();
      expect(cancelFired1, isFalse);
      expect(cancelFired2, isFalse);

      completer.complete();
      await flushMicrotasks();
      expect(cancelFired1, isTrue);
      expect(cancelFired2, isTrue);
    });
  });

  group('with a pause callback', () {
    test('invokes the callback when pause is called', () async {
      var pauseCount = 0;
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer(
              handlePause: expectAsync1((inner) {
            pauseCount++;
            inner.pause();
          }, count: 3)))
          .listen(expectAsync1((_) {}, count: 0));

      await flushMicrotasks();
      expect(pauseCount, equals(0));

      subscription.pause();
      await flushMicrotasks();
      expect(pauseCount, equals(1));

      subscription.pause();
      await flushMicrotasks();
      expect(pauseCount, equals(2));

      subscription.resume();
      subscription.resume();
      await flushMicrotasks();
      expect(pauseCount, equals(2));

      subscription.pause();
      await flushMicrotasks();
      expect(pauseCount, equals(3));
    });

    test("doesn't invoke the callback when the subscription has been canceled",
        () async {
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer(
              handlePause: expectAsync1((_) {}, count: 0)))
          .listen(expectAsync1((_) {}, count: 0));

      subscription.cancel();
      subscription.pause();
      subscription.pause();
      subscription.pause();
    });
  });

  group('with a resume callback', () {
    test('invokes the callback when resume is called', () async {
      var resumeCount = 0;
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer(
              handleResume: expectAsync1((inner) {
            resumeCount++;
            inner.resume();
          }, count: 3)))
          .listen(expectAsync1((_) {}, count: 0));

      await flushMicrotasks();
      expect(resumeCount, equals(0));

      subscription.resume();
      await flushMicrotasks();
      expect(resumeCount, equals(1));

      subscription.pause();
      subscription.pause();
      await flushMicrotasks();
      expect(resumeCount, equals(1));

      subscription.resume();
      await flushMicrotasks();
      expect(resumeCount, equals(2));

      subscription.resume();
      await flushMicrotasks();
      expect(resumeCount, equals(3));
    });

    test('invokes the callback when a resume future completes', () async {
      var resumed = false;
      var controller = StreamController();
      var subscription = controller.stream.transform(
          subscriptionTransformer(handleResume: expectAsync1((inner) {
        resumed = true;
        inner.resume();
      }))).listen(expectAsync1((_) {}, count: 0));

      var completer = Completer();
      subscription.pause(completer.future);
      await flushMicrotasks();
      expect(resumed, isFalse);

      completer.complete();
      await flushMicrotasks();
      expect(resumed, isTrue);
    });

    test("doesn't invoke the callback when the subscription has been canceled",
        () async {
      var controller = StreamController();
      var subscription = controller.stream
          .transform(subscriptionTransformer(
              handlePause: expectAsync1((_) {}, count: 0)))
          .listen(expectAsync1((_) {}, count: 0));

      subscription.cancel();
      subscription.resume();
      subscription.resume();
      subscription.resume();
    });
  });

  group('when the outer subscription is canceled but the inner is not', () {
    late StreamSubscription subscription;
    setUp(() {
      var controller = StreamController();
      subscription = controller.stream
          .transform(
              subscriptionTransformer(handleCancel: (_) => Future.value()))
          .listen(expectAsync1((_) {}, count: 0),
              onError: expectAsync2((_, __) {}, count: 0),
              onDone: expectAsync0(() {}, count: 0));
      subscription.cancel();
      controller.add(1);
      controller.addError('oh no!');
      controller.close();
    });

    test("doesn't call a new onData", () async {
      subscription.onData(expectAsync1((_) {}, count: 0));
      await flushMicrotasks();
    });

    test("doesn't call a new onError", () async {
      subscription.onError(expectAsync2((_, __) {}, count: 0));
      await flushMicrotasks();
    });

    test("doesn't call a new onDone", () async {
      subscription.onDone(expectAsync0(() {}, count: 0));
      await flushMicrotasks();
    });

    test('isPaused returns false', () {
      expect(subscription.isPaused, isFalse);
    });

    test('asFuture never completes', () async {
      subscription.asFuture().then(expectAsync1((_) {}, count: 0));
      await flushMicrotasks();
    });
  });
}
