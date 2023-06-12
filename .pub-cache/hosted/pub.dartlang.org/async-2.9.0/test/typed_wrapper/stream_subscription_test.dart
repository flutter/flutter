// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/src/typed/stream_subscription.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('with valid types, forwards', () {
    late StreamController controller;
    late StreamSubscription wrapper;
    late bool isCanceled;
    setUp(() {
      isCanceled = false;
      controller = StreamController<Object>(onCancel: () {
        isCanceled = true;
      });
      wrapper = TypeSafeStreamSubscription<int>(controller.stream.listen(null));
    });

    test('onData()', () {
      wrapper.onData(expectAsync1((data) {
        expect(data, equals(1));
      }));
      controller.add(1);
    });

    test('onError()', () {
      wrapper.onError(expectAsync1((error) {
        expect(error, equals('oh no'));
      }));
      controller.addError('oh no');
    });

    test('onDone()', () {
      wrapper.onDone(expectAsync0(() {}));
      controller.close();
    });

    test('pause(), resume(), and isPaused', () async {
      expect(wrapper.isPaused, isFalse);

      wrapper.pause();
      await flushMicrotasks();
      expect(controller.isPaused, isTrue);
      expect(wrapper.isPaused, isTrue);

      wrapper.resume();
      await flushMicrotasks();
      expect(controller.isPaused, isFalse);
      expect(wrapper.isPaused, isFalse);
    });

    test('cancel()', () async {
      wrapper.cancel();
      await flushMicrotasks();
      expect(isCanceled, isTrue);
    });

    test('asFuture()', () {
      expect(wrapper.asFuture(12), completion(equals(12)));
      controller.close();
    });
  });

  group('with invalid types,', () {
    late StreamController controller;
    late StreamSubscription wrapper;
    late bool isCanceled;
    setUp(() {
      isCanceled = false;
      controller = StreamController<Object>(onCancel: () {
        isCanceled = true;
      });
      wrapper = TypeSafeStreamSubscription<int>(controller.stream.listen(null));
    });

    group('throws a TypeError for', () {
      test('onData()', () {
        expect(() {
          // TODO(nweiz): Use the wrapper declared in setUp when sdk#26226 is
          // fixed.
          controller = StreamController<Object>();
          wrapper =
              TypeSafeStreamSubscription<int>(controller.stream.listen(null));

          wrapper.onData(expectAsync1((_) {}, count: 0));
          controller.add('foo');
        }, throwsZonedTypeError);
      });
    });

    group("doesn't throw a TypeError for", () {
      test('onError()', () {
        wrapper.onError(expectAsync1((error) {
          expect(error, equals('oh no'));
        }));
        controller.add('foo');
        controller.addError('oh no');
      });

      test('onDone()', () {
        wrapper.onDone(expectAsync0(() {}));
        controller.add('foo');
        controller.close();
      });

      test('pause(), resume(), and isPaused', () async {
        controller.add('foo');

        expect(wrapper.isPaused, isFalse);

        wrapper.pause();
        await flushMicrotasks();
        expect(controller.isPaused, isTrue);
        expect(wrapper.isPaused, isTrue);

        wrapper.resume();
        await flushMicrotasks();
        expect(controller.isPaused, isFalse);
        expect(wrapper.isPaused, isFalse);
      });

      test('cancel()', () async {
        controller.add('foo');

        wrapper.cancel();
        await flushMicrotasks();
        expect(isCanceled, isTrue);
      });

      test('asFuture()', () {
        expect(wrapper.asFuture(12), completion(equals(12)));
        controller.add('foo');
        controller.close();
      });
    });
  });
}
