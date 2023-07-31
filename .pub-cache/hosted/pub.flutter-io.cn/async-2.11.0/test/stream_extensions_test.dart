// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE filevents.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  group('.slices', () {
    test('empty', () {
      expect(Stream.empty().slices(1).toList(), completion(equals([])));
    });

    test('with the same length as the iterable', () {
      expect(
          Stream.fromIterable([1, 2, 3]).slices(3).toList(),
          completion(equals([
            [1, 2, 3]
          ])));
    });

    test('with a longer length than the iterable', () {
      expect(
          Stream.fromIterable([1, 2, 3]).slices(5).toList(),
          completion(equals([
            [1, 2, 3]
          ])));
    });

    test('with a shorter length than the iterable', () {
      expect(
          Stream.fromIterable([1, 2, 3]).slices(2).toList(),
          completion(equals([
            [1, 2],
            [3]
          ])));
    });

    test('with length divisible by the iterable\'s', () {
      expect(
          Stream.fromIterable([1, 2, 3, 4]).slices(2).toList(),
          completion(equals([
            [1, 2],
            [3, 4]
          ])));
    });

    test('refuses negative length', () {
      expect(() => Stream.fromIterable([1]).slices(-1), throwsRangeError);
    });

    test('refuses length 0', () {
      expect(() => Stream.fromIterable([1]).slices(0), throwsRangeError);
    });
  });

  group('.firstOrNull', () {
    test('returns the first data event', () {
      expect(
          Stream.fromIterable([1, 2, 3, 4]).firstOrNull, completion(equals(1)));
    });

    test('returns the first error event', () {
      expect(Stream.error('oh no').firstOrNull, throwsA('oh no'));
    });

    test('returns null for an empty stream', () {
      expect(Stream.empty().firstOrNull, completion(isNull));
    });

    test('cancels the subscription after an event', () async {
      var isCancelled = false;
      var controller = StreamController<int>(onCancel: () {
        isCancelled = true;
      });
      controller.add(1);

      await expectLater(controller.stream.firstOrNull, completion(equals(1)));
      expect(isCancelled, isTrue);
    });

    test('cancels the subscription after an error', () async {
      var isCancelled = false;
      var controller = StreamController<int>(onCancel: () {
        isCancelled = true;
      });
      controller.addError('oh no');

      await expectLater(controller.stream.firstOrNull, throwsA('oh no'));
      expect(isCancelled, isTrue);
    });
  });

  group('.listenAndBuffer', () {
    test('emits events added before the listenAndBuffer is listened', () async {
      var controller = StreamController<int>()
        ..add(1)
        ..add(2)
        ..add(3)
        ..close();
      var stream = controller.stream.listenAndBuffer();
      await pumpEventQueue();

      expectLater(stream, emitsInOrder([1, 2, 3, emitsDone]));
    });

    test('emits events added after the listenAndBuffer is listened', () async {
      var controller = StreamController<int>();
      var stream = controller.stream.listenAndBuffer();
      expectLater(stream, emitsInOrder([1, 2, 3, emitsDone]));
      await pumpEventQueue();

      controller
        ..add(1)
        ..add(2)
        ..add(3)
        ..close();
    });

    test('emits events added before and after the listenAndBuffer is listened',
        () async {
      var controller = StreamController<int>()
        ..add(1)
        ..add(2)
        ..add(3);
      var stream = controller.stream.listenAndBuffer();
      expectLater(stream, emitsInOrder([1, 2, 3, 4, 5, 6, emitsDone]));
      await pumpEventQueue();

      controller
        ..add(4)
        ..add(5)
        ..add(6)
        ..close();
    });

    test('listens as soon as listenAndBuffer() is called', () async {
      var listened = false;
      var controller = StreamController<int>(onListen: () {
        listened = true;
      });
      controller.stream.listenAndBuffer();
      expect(listened, isTrue);
    });

    test('forwards pause and resume', () async {
      var controller = StreamController<int>();
      var stream = controller.stream.listenAndBuffer();
      expect(controller.isPaused, isFalse);
      var subscription = stream.listen(null);
      expect(controller.isPaused, isFalse);
      subscription.pause();
      expect(controller.isPaused, isTrue);
      subscription.resume();
      expect(controller.isPaused, isFalse);
    });

    test('forwards cancel', () async {
      var completer = Completer<void>();
      var canceled = false;
      var controller = StreamController<int>(onCancel: () {
        canceled = true;
        return completer.future;
      });
      var stream = controller.stream.listenAndBuffer();
      expect(canceled, isFalse);
      var subscription = stream.listen(null);
      expect(canceled, isFalse);

      var cancelCompleted = false;
      subscription.cancel().then((_) {
        cancelCompleted = true;
      });
      expect(canceled, isTrue);
      await pumpEventQueue();
      expect(cancelCompleted, isFalse);

      completer.complete();
      await pumpEventQueue();
      expect(cancelCompleted, isTrue);
    });
  });
}
