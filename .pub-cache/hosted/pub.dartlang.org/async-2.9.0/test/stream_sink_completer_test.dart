// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late StreamSinkCompleter completer;
  setUp(() {
    completer = StreamSinkCompleter();
  });

  group('when a stream is linked before events are added', () {
    test('data events are forwarded', () {
      var sink = TestSink();
      completer.setDestinationSink(sink);
      completer.sink
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4);

      expect(sink.results[0].asValue!.value, equals(1));
      expect(sink.results[1].asValue!.value, equals(2));
      expect(sink.results[2].asValue!.value, equals(3));
      expect(sink.results[3].asValue!.value, equals(4));
    });

    test('error events are forwarded', () {
      var sink = TestSink();
      completer.setDestinationSink(sink);
      completer.sink
        ..addError('oh no')
        ..addError("that's bad");

      expect(sink.results[0].asError!.error, equals('oh no'));
      expect(sink.results[1].asError!.error, equals("that's bad"));
    });

    test('addStream is forwarded', () async {
      var sink = TestSink();
      completer.setDestinationSink(sink);

      var controller = StreamController();
      completer.sink.addStream(controller.stream);

      controller.add(1);
      controller.addError('oh no');
      controller.add(2);
      controller.addError("that's bad");
      await flushMicrotasks();

      expect(sink.results[0].asValue!.value, equals(1));
      expect(sink.results[1].asError!.error, equals('oh no'));
      expect(sink.results[2].asValue!.value, equals(2));
      expect(sink.results[3].asError!.error, equals("that's bad"));
      expect(sink.isClosed, isFalse);

      controller.close();
      await flushMicrotasks();
      expect(sink.isClosed, isFalse);
    });

    test('close() is forwarded', () {
      var sink = TestSink();
      completer.setDestinationSink(sink);
      completer.sink.close();
      expect(sink.isClosed, isTrue);
    });

    test('the future from the inner close() is returned', () async {
      var closeCompleter = Completer();
      var sink = TestSink(onDone: () => closeCompleter.future);
      completer.setDestinationSink(sink);

      var closeCompleted = false;
      completer.sink.close().then(expectAsync1((_) {
        closeCompleted = true;
      }));

      await flushMicrotasks();
      expect(closeCompleted, isFalse);

      closeCompleter.complete();
      await flushMicrotasks();
      expect(closeCompleted, isTrue);
    });

    test('errors are forwarded from the inner close()', () {
      var sink = TestSink(onDone: () => throw 'oh no');
      completer.setDestinationSink(sink);
      expect(completer.sink.done, throwsA('oh no'));
      expect(completer.sink.close(), throwsA('oh no'));
    });

    test("errors aren't top-leveled if only close() is listened to", () async {
      var sink = TestSink(onDone: () => throw 'oh no');
      completer.setDestinationSink(sink);
      expect(completer.sink.close(), throwsA('oh no'));

      // Give the event loop a chance to top-level errors if it's going to.
      await flushMicrotasks();
    });

    test("errors aren't top-leveled if only done is listened to", () async {
      var sink = TestSink(onDone: () => throw 'oh no');
      completer.setDestinationSink(sink);
      completer.sink.close();
      expect(completer.sink.done, throwsA('oh no'));

      // Give the event loop a chance to top-level errors if it's going to.
      await flushMicrotasks();
    });
  });

  group('when a stream is linked after events are added', () {
    test('data events are forwarded', () async {
      completer.sink
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4);
      await flushMicrotasks();

      var sink = TestSink();
      completer.setDestinationSink(sink);
      await flushMicrotasks();

      expect(sink.results[0].asValue!.value, equals(1));
      expect(sink.results[1].asValue!.value, equals(2));
      expect(sink.results[2].asValue!.value, equals(3));
      expect(sink.results[3].asValue!.value, equals(4));
    });

    test('error events are forwarded', () async {
      completer.sink
        ..addError('oh no')
        ..addError("that's bad");
      await flushMicrotasks();

      var sink = TestSink();
      completer.setDestinationSink(sink);
      await flushMicrotasks();

      expect(sink.results[0].asError!.error, equals('oh no'));
      expect(sink.results[1].asError!.error, equals("that's bad"));
    });

    test('addStream is forwarded', () async {
      var controller = StreamController();
      completer.sink.addStream(controller.stream);

      controller.add(1);
      controller.addError('oh no');
      controller.add(2);
      controller.addError("that's bad");
      controller.close();
      await flushMicrotasks();

      var sink = TestSink();
      completer.setDestinationSink(sink);
      await flushMicrotasks();

      expect(sink.results[0].asValue!.value, equals(1));
      expect(sink.results[1].asError!.error, equals('oh no'));
      expect(sink.results[2].asValue!.value, equals(2));
      expect(sink.results[3].asError!.error, equals("that's bad"));
      expect(sink.isClosed, isFalse);
    });

    test('close() is forwarded', () async {
      completer.sink.close();
      await flushMicrotasks();

      var sink = TestSink();
      completer.setDestinationSink(sink);
      await flushMicrotasks();

      expect(sink.isClosed, isTrue);
    });

    test('the future from the inner close() is returned', () async {
      var closeCompleted = false;
      completer.sink.close().then(expectAsync1((_) {
        closeCompleted = true;
      }));
      await flushMicrotasks();

      var closeCompleter = Completer();
      var sink = TestSink(onDone: () => closeCompleter.future);
      completer.setDestinationSink(sink);
      await flushMicrotasks();
      expect(closeCompleted, isFalse);

      closeCompleter.complete();
      await flushMicrotasks();
      expect(closeCompleted, isTrue);
    });

    test('errors are forwarded from the inner close()', () async {
      expect(completer.sink.done, throwsA('oh no'));
      expect(completer.sink.close(), throwsA('oh no'));
      await flushMicrotasks();

      var sink = TestSink(onDone: () => throw 'oh no');
      completer.setDestinationSink(sink);
    });

    test("errors aren't top-leveled if only close() is listened to", () async {
      expect(completer.sink.close(), throwsA('oh no'));
      await flushMicrotasks();

      var sink = TestSink(onDone: () => throw 'oh no');
      completer.setDestinationSink(sink);

      // Give the event loop a chance to top-level errors if it's going to.
      await flushMicrotasks();
    });

    test("errors aren't top-leveled if only done is listened to", () async {
      completer.sink.close();
      expect(completer.sink.done, throwsA('oh no'));
      await flushMicrotasks();

      var sink = TestSink(onDone: () => throw 'oh no');
      completer.setDestinationSink(sink);

      // Give the event loop a chance to top-level errors if it's going to.
      await flushMicrotasks();
    });
  });

  test('the sink is closed, the destination is set, then done is read',
      () async {
    expect(completer.sink.close(), completes);
    await flushMicrotasks();

    completer.setDestinationSink(TestSink());
    await flushMicrotasks();

    expect(completer.sink.done, completes);
  });

  test('done is read, the destination is set, then the sink is closed',
      () async {
    expect(completer.sink.done, completes);
    await flushMicrotasks();

    completer.setDestinationSink(TestSink());
    await flushMicrotasks();

    expect(completer.sink.close(), completes);
  });

  group('fromFuture()', () {
    test('with a successful completion', () async {
      var futureCompleter = Completer<StreamSink>();
      var sink = StreamSinkCompleter.fromFuture(futureCompleter.future);
      sink.add(1);
      sink.add(2);
      sink.add(3);
      sink.close();

      var testSink = TestSink();
      futureCompleter.complete(testSink);
      await testSink.done;

      expect(testSink.results[0].asValue!.value, equals(1));
      expect(testSink.results[1].asValue!.value, equals(2));
      expect(testSink.results[2].asValue!.value, equals(3));
    });

    test('with an error', () async {
      var futureCompleter = Completer<StreamSink>();
      var sink = StreamSinkCompleter.fromFuture(futureCompleter.future);
      expect(sink.done, throwsA('oh no'));
      futureCompleter.completeError('oh no');
    });
  });

  group('setError()', () {
    test('produces a closed sink with the error', () {
      completer.setError('oh no');
      expect(completer.sink.done, throwsA('oh no'));
      expect(completer.sink.close(), throwsA('oh no'));
    });

    test('produces an error even if done was accessed earlier', () async {
      expect(completer.sink.done, throwsA('oh no'));
      expect(completer.sink.close(), throwsA('oh no'));
      await flushMicrotasks();

      completer.setError('oh no');
    });
  });

  test("doesn't allow the destination sink to be set multiple times", () {
    completer.setDestinationSink(TestSink());
    expect(() => completer.setDestinationSink(TestSink()), throwsStateError);
    expect(() => completer.setDestinationSink(TestSink()), throwsStateError);
  });
}
