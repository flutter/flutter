// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE filevents.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late StreamController controller;
  setUp(() {
    controller = StreamController();
  });

  group('fromStreamTransformer', () {
    test('transforms data events', () {
      var transformer = StreamSinkTransformer.fromStreamTransformer(
          StreamTransformer.fromHandlers(handleData: (int i, sink) {
        sink.add(i * 2);
      }));
      var sink = transformer.bind(controller.sink);

      var results = [];
      controller.stream.listen(results.add, onDone: expectAsync0(() {
        expect(results, equals([2, 4, 6]));
      }));

      sink.add(1);
      sink.add(2);
      sink.add(3);
      sink.close();
    });

    test('transforms error events', () {
      var transformer = StreamSinkTransformer.fromStreamTransformer(
          StreamTransformer.fromHandlers(handleError: (i, stackTrace, sink) {
        sink.addError((i as num) * 2, stackTrace);
      }));
      var sink = transformer.bind(controller.sink);

      var results = [];
      controller.stream.listen(expectAsync1((_) {}, count: 0),
          onError: (error, stackTrace) {
        results.add(error);
      }, onDone: expectAsync0(() {
        expect(results, equals([2, 4, 6]));
      }));

      sink.addError(1);
      sink.addError(2);
      sink.addError(3);
      sink.close();
    });

    test('transforms done events', () {
      var transformer = StreamSinkTransformer.fromStreamTransformer(
          StreamTransformer.fromHandlers(handleDone: (sink) {
        sink.add(1);
        sink.close();
      }));
      var sink = transformer.bind(controller.sink);

      var results = [];
      controller.stream.listen(results.add, onDone: expectAsync0(() {
        expect(results, equals([1]));
      }));

      sink.close();
    });

    test('forwards the future from inner.close', () async {
      var transformer = StreamSinkTransformer.fromStreamTransformer(
          StreamTransformer.fromHandlers());
      var innerSink = CompleterStreamSink();
      var sink = transformer.bind(innerSink);

      // The futures shouldn't complete until the inner sink's close future
      // completes.
      var doneResult = ResultFuture(sink.done);
      doneResult.catchError((_) {});
      var closeResult = ResultFuture(sink.close());
      closeResult.catchError((_) {});
      await flushMicrotasks();
      expect(doneResult.isComplete, isFalse);
      expect(closeResult.isComplete, isFalse);

      // Once the inner sink is completed, the futures should fire.
      innerSink.completer.complete();
      await flushMicrotasks();
      expect(doneResult.isComplete, isTrue);
      expect(closeResult.isComplete, isTrue);
    });

    test("doesn't top-level the future from inner.close", () async {
      var transformer = StreamSinkTransformer.fromStreamTransformer(
          StreamTransformer.fromHandlers(handleData: (_, sink) {
        sink.close();
      }));
      var innerSink = CompleterStreamSink();
      var sink = transformer.bind(innerSink);

      // This will close the inner sink, but it shouldn't top-level the error.
      sink.add(1);
      innerSink.completer.completeError('oh no');
      await flushMicrotasks();

      // The error should be piped through done and close even if they're called
      // after the underlying sink is closed.
      expect(sink.done, throwsA('oh no'));
      expect(sink.close(), throwsA('oh no'));
    });
  });

  group('fromHandlers', () {
    test('transforms data events', () {
      var transformer =
          StreamSinkTransformer.fromHandlers(handleData: (int i, sink) {
        sink.add(i * 2);
      });
      var sink = transformer.bind(controller.sink);

      var results = [];
      controller.stream.listen(results.add, onDone: expectAsync0(() {
        expect(results, equals([2, 4, 6]));
      }));

      sink.add(1);
      sink.add(2);
      sink.add(3);
      sink.close();
    });

    test('transforms error events', () {
      var transformer = StreamSinkTransformer.fromHandlers(
          handleError: (i, stackTrace, sink) {
        sink.addError((i as num) * 2, stackTrace);
      });
      var sink = transformer.bind(controller.sink);

      var results = [];
      controller.stream.listen(expectAsync1((_) {}, count: 0),
          onError: (error, stackTrace) {
        results.add(error);
      }, onDone: expectAsync0(() {
        expect(results, equals([2, 4, 6]));
      }));

      sink.addError(1);
      sink.addError(2);
      sink.addError(3);
      sink.close();
    });

    test('transforms done events', () {
      var transformer = StreamSinkTransformer.fromHandlers(handleDone: (sink) {
        sink.add(1);
        sink.close();
      });
      var sink = transformer.bind(controller.sink);

      var results = [];
      controller.stream.listen(results.add, onDone: expectAsync0(() {
        expect(results, equals([1]));
      }));

      sink.close();
    });

    test('forwards the future from inner.close', () async {
      var transformer = StreamSinkTransformer.fromHandlers();
      var innerSink = CompleterStreamSink();
      var sink = transformer.bind(innerSink);

      // The futures shouldn't complete until the inner sink's close future
      // completes.
      var doneResult = ResultFuture(sink.done);
      doneResult.catchError((_) {});
      var closeResult = ResultFuture(sink.close());
      closeResult.catchError((_) {});
      await flushMicrotasks();
      expect(doneResult.isComplete, isFalse);
      expect(closeResult.isComplete, isFalse);

      // Once the inner sink is completed, the futures should fire.
      innerSink.completer.complete();
      await flushMicrotasks();
      expect(doneResult.isComplete, isTrue);
      expect(closeResult.isComplete, isTrue);
    });

    test("doesn't top-level the future from inner.close", () async {
      var transformer =
          StreamSinkTransformer.fromHandlers(handleData: (_, sink) {
        sink.close();
      });
      var innerSink = CompleterStreamSink();
      var sink = transformer.bind(innerSink);

      // This will close the inner sink, but it shouldn't top-level the error.
      sink.add(1);
      innerSink.completer.completeError('oh no');
      await flushMicrotasks();

      // The error should be piped through done and close even if they're called
      // after the underlying sink is closed.
      expect(sink.done, throwsA('oh no'));
      expect(sink.close(), throwsA('oh no'));
    });
  });
}
