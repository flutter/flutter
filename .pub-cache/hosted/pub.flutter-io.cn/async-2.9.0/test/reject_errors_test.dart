// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE filevents.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  late StreamController controller;
  setUp(() {
    controller = StreamController();
  });

  test('passes through data events', () {
    controller.sink.rejectErrors()
      ..add(1)
      ..add(2)
      ..add(3);
    expect(controller.stream, emitsInOrder([1, 2, 3]));
  });

  test('passes through close events', () {
    controller.sink.rejectErrors()
      ..add(1)
      ..close();
    expect(controller.stream, emitsInOrder([1, emitsDone]));
  });

  test('passes through data events from addStream()', () {
    controller.sink.rejectErrors().addStream(Stream.fromIterable([1, 2, 3]));
    expect(controller.stream, emitsInOrder([1, 2, 3]));
  });

  test('allows multiple addStream() calls', () async {
    var transformed = controller.sink.rejectErrors();
    await transformed.addStream(Stream.fromIterable([1, 2, 3]));
    await transformed.addStream(Stream.fromIterable([4, 5, 6]));
    expect(controller.stream, emitsInOrder([1, 2, 3, 4, 5, 6]));
  });

  group('on addError()', () {
    test('forwards the error to done', () {
      var transformed = controller.sink.rejectErrors();
      transformed.addError('oh no');
      expect(transformed.done, throwsA('oh no'));
    });

    test('closes the underlying sink', () {
      var transformed = controller.sink.rejectErrors();
      transformed.addError('oh no');
      transformed.done.catchError((_) {});

      expect(controller.stream, emitsDone);
    });

    test('ignores further events', () async {
      var transformed = controller.sink.rejectErrors();
      transformed.addError('oh no');
      transformed.done.catchError((_) {});
      expect(controller.stream, emitsDone);

      // Try adding events synchronously and asynchronously and verify that they
      // don't throw and also aren't passed to the underlying sink.
      transformed
        ..add(1)
        ..addError('another');
      await pumpEventQueue();
      transformed
        ..add(2)
        ..addError('yet another');
    });

    test('cancels the current subscription', () async {
      var inputCanceled = false;
      var inputController =
          StreamController(onCancel: () => inputCanceled = true);

      var transformed = controller.sink.rejectErrors()
        ..addStream(inputController.stream);
      inputController.addError('oh no');
      transformed.done.catchError((_) {});

      await pumpEventQueue();
      expect(inputCanceled, isTrue);
    });
  });

  group('when the inner sink\'s done future completes', () {
    test('done completes', () async {
      var completer = Completer();
      var transformed = NullStreamSink(done: completer.future).rejectErrors();

      var doneCompleted = false;
      transformed.done.then((_) => doneCompleted = true);
      await pumpEventQueue();
      expect(doneCompleted, isFalse);

      completer.complete();
      await pumpEventQueue();
      expect(doneCompleted, isTrue);
    });

    test('an outstanding addStream() completes', () async {
      var completer = Completer();
      var transformed = NullStreamSink(done: completer.future).rejectErrors();

      var addStreamCompleted = false;
      transformed
          .addStream(StreamController().stream)
          .then((_) => addStreamCompleted = true);
      await pumpEventQueue();
      expect(addStreamCompleted, isFalse);

      completer.complete();
      await pumpEventQueue();
      expect(addStreamCompleted, isTrue);
    });

    test('an outstanding addStream()\'s subscription is cancelled', () async {
      var completer = Completer();
      var transformed = NullStreamSink(done: completer.future).rejectErrors();

      var addStreamCancelled = false;
      transformed.addStream(
          StreamController(onCancel: () => addStreamCancelled = true).stream);
      await pumpEventQueue();
      expect(addStreamCancelled, isFalse);

      completer.complete();
      await pumpEventQueue();
      expect(addStreamCancelled, isTrue);
    });

    test('forwards an outstanding addStream()\'s cancellation error', () async {
      var completer = Completer();
      var transformed = NullStreamSink(done: completer.future).rejectErrors();

      expect(
          transformed.addStream(
              StreamController(onCancel: () => throw 'oh no').stream),
          throwsA('oh no'));
      completer.complete();
    });

    group('forwards its error', () {
      test('through done', () async {
        expect(NullStreamSink(done: Future.error('oh no')).rejectErrors().done,
            throwsA('oh no'));
      });

      test('through close', () async {
        expect(
            NullStreamSink(done: Future.error('oh no')).rejectErrors().close(),
            throwsA('oh no'));
      });
    });
  });

  group('after closing', () {
    test('throws on add()', () {
      var sink = controller.sink.rejectErrors()..close();
      expect(() => sink.add(1), throwsStateError);
    });

    test('throws on addError()', () {
      var sink = controller.sink.rejectErrors()..close();
      expect(() => sink.addError('oh no'), throwsStateError);
    });

    test('throws on addStream()', () {
      var sink = controller.sink.rejectErrors()..close();
      expect(() => sink.addStream(Stream.empty()), throwsStateError);
    });

    test('allows close()', () {
      var sink = controller.sink.rejectErrors()..close();
      sink.close(); // Shouldn't throw
    });
  });

  group('during an active addStream()', () {
    test('throws on add()', () {
      var sink = controller.sink.rejectErrors()
        ..addStream(StreamController().stream);
      expect(() => sink.add(1), throwsStateError);
    });

    test('throws on addError()', () {
      var sink = controller.sink.rejectErrors()
        ..addStream(StreamController().stream);
      expect(() => sink.addError('oh no'), throwsStateError);
    });

    test('throws on addStream()', () {
      var sink = controller.sink.rejectErrors()
        ..addStream(StreamController().stream);
      expect(() => sink.addStream(Stream.empty()), throwsStateError);
    });

    test('throws on close()', () {
      var sink = controller.sink.rejectErrors()
        ..addStream(StreamController().stream);
      expect(() => sink.close(), throwsStateError);
    });
  });
}
