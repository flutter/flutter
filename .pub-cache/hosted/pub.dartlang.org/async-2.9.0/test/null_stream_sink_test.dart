// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('constructors', () {
    test('done defaults to a completed future', () {
      var sink = NullStreamSink();
      expect(sink.done, completes);
    });

    test('a custom future may be passed to done', () async {
      var completer = Completer();
      var sink = NullStreamSink(done: completer.future);

      var doneFired = false;
      sink.done.then((_) {
        doneFired = true;
      });
      await flushMicrotasks();
      expect(doneFired, isFalse);

      completer.complete();
      await flushMicrotasks();
      expect(doneFired, isTrue);
    });

    test('NullStreamSink.error passes an error to done', () {
      var sink = NullStreamSink.error('oh no');
      expect(sink.done, throwsA('oh no'));
    });
  });

  group('events', () {
    test('are silently dropped before close', () {
      var sink = NullStreamSink();
      sink.add(1);
      sink.addError('oh no');
    });

    test('throw StateErrors after close', () {
      var sink = NullStreamSink();
      expect(sink.close(), completes);

      expect(() => sink.add(1), throwsStateError);
      expect(() => sink.addError('oh no'), throwsStateError);
      expect(() => sink.addStream(Stream.empty()), throwsStateError);
    });

    group('addStream', () {
      test('listens to the stream then cancels immediately', () async {
        var sink = NullStreamSink();
        var canceled = false;
        var controller = StreamController(onCancel: () {
          canceled = true;
        });

        expect(sink.addStream(controller.stream), completes);
        await flushMicrotasks();
        expect(canceled, isTrue);
      });

      test('returns the cancel future', () async {
        var completer = Completer();
        var sink = NullStreamSink();
        var controller = StreamController(onCancel: () => completer.future);

        var addStreamFired = false;
        sink.addStream(controller.stream).then((_) {
          addStreamFired = true;
        });
        await flushMicrotasks();
        expect(addStreamFired, isFalse);

        completer.complete();
        await flushMicrotasks();
        expect(addStreamFired, isTrue);
      });

      test('pipes errors from the cancel future through addStream', () async {
        var sink = NullStreamSink();
        var controller = StreamController(onCancel: () => throw 'oh no');
        expect(sink.addStream(controller.stream), throwsA('oh no'));
      });

      test('causes events to throw StateErrors until the future completes',
          () async {
        var sink = NullStreamSink();
        var future = sink.addStream(Stream.empty());
        expect(() => sink.add(1), throwsStateError);
        expect(() => sink.addError('oh no'), throwsStateError);
        expect(() => sink.addStream(Stream.empty()), throwsStateError);

        await future;
        sink.add(1);
        sink.addError('oh no');
        expect(sink.addStream(Stream.empty()), completes);
      });
    });
  });

  test('close returns the done future', () {
    var sink = NullStreamSink.error('oh no');
    expect(sink.close(), throwsA('oh no'));
  });
}
