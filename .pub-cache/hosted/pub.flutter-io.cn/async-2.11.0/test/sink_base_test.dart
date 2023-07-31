// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('Tests deprecated functionality')
library sink_base_test;

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:test/test.dart';

const int letterA = 0x41;

void main() {
  // We don't explicitly test [EventSinkBase] because it shares all the relevant
  // implementation with [StreamSinkBase].
  group('StreamSinkBase', () {
    test('forwards add() to onAdd()', () {
      var sink = _StreamSink(onAdd: expectAsync1((value) {
        expect(value, equals(123));
      }));
      sink.add(123);
    });

    test('forwards addError() to onError()', () {
      var sink = _StreamSink(onError: expectAsync2((error, [stackTrace]) {
        expect(error, equals('oh no'));
        expect(stackTrace, isA<StackTrace>());
      }));
      sink.addError('oh no', StackTrace.current);
    });

    test('forwards addStream() to onAdd() and onError()', () {
      var sink = _StreamSink(
          onAdd: expectAsync1((value) {
            expect(value, equals(123));
          }, count: 1),
          onError: expectAsync2((error, [stackTrace]) {
            expect(error, equals('oh no'));
            expect(stackTrace, isA<StackTrace>());
          }));

      var controller = StreamController<int>();
      sink.addStream(controller.stream);

      controller.add(123);
      controller.addError('oh no', StackTrace.current);
    });

    test('addStream() returns once the stream closes', () async {
      var sink = _StreamSink();
      var controller = StreamController<int>();
      var addStreamCompleted = false;
      sink.addStream(controller.stream).then((_) => addStreamCompleted = true);

      await pumpEventQueue();
      expect(addStreamCompleted, isFalse);

      controller.addError('oh no', StackTrace.current);
      await pumpEventQueue();
      expect(addStreamCompleted, isFalse);

      controller.close();
      await pumpEventQueue();
      expect(addStreamCompleted, isTrue);
    });

    test('forwards close() to onClose()', () {
      var sink = _StreamSink(onClose: expectAsync0(() {}));
      expect(sink.close(), completes);
    });

    test('onClose() is only invoked once', () {
      var sink = _StreamSink(onClose: expectAsync0(() {}, count: 1));
      expect(sink.close(), completes);
      expect(sink.close(), completes);
      expect(sink.close(), completes);
    });

    test('all invocations of close() return the same future', () async {
      var completer = Completer();
      var sink = _StreamSink(onClose: expectAsync0(() => completer.future));

      var close1Completed = false;
      sink.close().then((_) => close1Completed = true);

      var close2Completed = false;
      sink.close().then((_) => close2Completed = true);

      var doneCompleted = false;
      sink.done.then((_) => doneCompleted = true);

      await pumpEventQueue();
      expect(close1Completed, isFalse);
      expect(close2Completed, isFalse);
      expect(doneCompleted, isFalse);

      completer.complete();
      await pumpEventQueue();
      expect(close1Completed, isTrue);
      expect(close2Completed, isTrue);
      expect(doneCompleted, isTrue);
    });

    test('done returns a future that completes once close() completes',
        () async {
      var completer = Completer();
      var sink = _StreamSink(onClose: expectAsync0(() => completer.future));

      var doneCompleted = false;
      sink.done.then((_) => doneCompleted = true);

      await pumpEventQueue();
      expect(doneCompleted, isFalse);

      expect(sink.close(), completes);
      await pumpEventQueue();
      expect(doneCompleted, isFalse);

      completer.complete();
      await pumpEventQueue();
      expect(doneCompleted, isTrue);
    });

    group('during addStream()', () {
      test('add() throws an error', () {
        var sink = _StreamSink(onAdd: expectAsync1((_) {}, count: 0));
        sink.addStream(StreamController<int>().stream);
        expect(() => sink.add(1), throwsStateError);
      });

      test('addError() throws an error', () {
        var sink = _StreamSink(onError: expectAsync2((_, [__]) {}, count: 0));
        sink.addStream(StreamController<int>().stream);
        expect(() => sink.addError('oh no'), throwsStateError);
      });

      test('addStream() throws an error', () {
        var sink = _StreamSink(onAdd: expectAsync1((_) {}, count: 0));
        sink.addStream(StreamController<int>().stream);
        expect(() => sink.addStream(Stream.value(123)), throwsStateError);
      });

      test('close() throws an error', () {
        var sink = _StreamSink(onClose: expectAsync0(() {}, count: 0));
        sink.addStream(StreamController<int>().stream);
        expect(() => sink.close(), throwsStateError);
      });
    });

    group("once it's closed", () {
      test('add() throws an error', () {
        var sink = _StreamSink(onAdd: expectAsync1((_) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.add(1), throwsStateError);
      });

      test('addError() throws an error', () {
        var sink = _StreamSink(onError: expectAsync2((_, [__]) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.addError('oh no'), throwsStateError);
      });

      test('addStream() throws an error', () {
        var sink = _StreamSink(onAdd: expectAsync1((_) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.addStream(Stream.value(123)), throwsStateError);
      });
    });
  });

  group('IOSinkBase', () {
    group('write()', () {
      test("doesn't call add() for the empty string", () async {
        var sink = _IOSink(onAdd: expectAsync1((_) {}, count: 0));
        sink.write('');
      });

      test('converts the text to data and passes it to add', () async {
        var sink = _IOSink(onAdd: expectAsync1((data) {
          expect(data, equals(utf8.encode('hello')));
        }));
        sink.write('hello');
      });

      test('calls Object.toString()', () async {
        var sink = _IOSink(onAdd: expectAsync1((data) {
          expect(data, equals(utf8.encode('123')));
        }));
        sink.write(123);
      });

      test('respects the encoding', () async {
        var sink = _IOSink(
            onAdd: expectAsync1((data) {
              expect(data, equals(latin1.encode('Æ')));
            }),
            encoding: latin1);
        sink.write('Æ');
      });

      test('throws if the sink is closed', () async {
        var sink = _IOSink(onAdd: expectAsync1((_) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.write('hello'), throwsStateError);
      });
    });

    group('writeAll()', () {
      test('writes nothing for an empty iterable', () async {
        var sink = _IOSink(onAdd: expectAsync1((_) {}, count: 0));
        sink.writeAll([]);
      });

      test('writes each object in the iterable', () async {
        var chunks = <List<int>>[];
        var sink = _IOSink(
            onAdd: expectAsync1((data) {
          chunks.add(data);
        }, count: 3));

        sink.writeAll(['hello', null, 123]);
        expect(chunks, equals(['hello', 'null', '123'].map(utf8.encode)));
      });

      test('writes separators between each object', () async {
        var chunks = <List<int>>[];
        var sink = _IOSink(
            onAdd: expectAsync1((data) {
          chunks.add(data);
        }, count: 5));

        sink.writeAll(['hello', null, 123], '/');
        expect(chunks,
            equals(['hello', '/', 'null', '/', '123'].map(utf8.encode)));
      });

      test('throws if the sink is closed', () async {
        var sink = _IOSink(onAdd: expectAsync1((_) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.writeAll(['hello']), throwsStateError);
      });
    });

    group('writeln()', () {
      test('only writes a newline by default', () async {
        var sink = _IOSink(
            onAdd: expectAsync1((data) {
          expect(data, equals(utf8.encode('\n')));
        }, count: 1));
        sink.writeln();
      });

      test('writes the object followed by a newline', () async {
        var chunks = <List<int>>[];
        var sink = _IOSink(
            onAdd: expectAsync1((data) {
          chunks.add(data);
        }, count: 2));
        sink.writeln(123);

        expect(chunks, equals(['123', '\n'].map(utf8.encode)));
      });

      test('throws if the sink is closed', () async {
        var sink = _IOSink(onAdd: expectAsync1((_) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.writeln(), throwsStateError);
      });
    });

    group('writeCharCode()', () {
      test('writes the character code', () async {
        var sink = _IOSink(onAdd: expectAsync1((data) {
          expect(data, equals(utf8.encode('A')));
        }));
        sink.writeCharCode(letterA);
      });

      test('respects the encoding', () async {
        var sink = _IOSink(
            onAdd: expectAsync1((data) {
              expect(data, equals(latin1.encode('Æ')));
            }),
            encoding: latin1);
        sink.writeCharCode('Æ'.runes.first);
      });

      test('throws if the sink is closed', () async {
        var sink = _IOSink(onAdd: expectAsync1((_) {}, count: 0));
        expect(sink.close(), completes);
        expect(() => sink.writeCharCode(letterA), throwsStateError);
      });
    });

    group('flush()', () {
      test('returns a future that completes when onFlush() is done', () async {
        var completer = Completer();
        var sink = _IOSink(onFlush: expectAsync0(() => completer.future));

        var flushDone = false;
        sink.flush().then((_) => flushDone = true);

        await pumpEventQueue();
        expect(flushDone, isFalse);

        completer.complete();
        await pumpEventQueue();
        expect(flushDone, isTrue);
      });

      test('does nothing after close() is called', () {
        var sink = _IOSink(onFlush: expectAsync0(Future.value, count: 0));
        expect(sink.close(), completes);
        expect(sink.flush(), completes);
      });

      test("can't be called during addStream()", () {
        var sink = _IOSink(onFlush: expectAsync0(Future.value, count: 0));
        sink.addStream(StreamController<List<int>>().stream);
        expect(() => sink.flush(), throwsStateError);
      });

      test('locks the sink as though a stream was being added', () {
        var sink = _IOSink(onFlush: expectAsync0(() => Completer().future));
        sink.flush();
        expect(() => sink.add([0]), throwsStateError);
        expect(() => sink.addError('oh no'), throwsStateError);
        expect(() => sink.addStream(Stream.empty()), throwsStateError);
        expect(() => sink.flush(), throwsStateError);
        expect(() => sink.close(), throwsStateError);
      });
    });
  });
}

/// A subclass of [StreamSinkBase] that takes all the overridable methods as
/// callbacks, for ease of testing.
class _StreamSink extends StreamSinkBase<int> {
  final void Function(int value) _onAdd;
  final void Function(Object error, [StackTrace? stackTrace]) _onError;
  final FutureOr<void> Function() _onClose;

  _StreamSink(
      {void Function(int value)? onAdd,
      void Function(Object error, [StackTrace? stackTrace])? onError,
      FutureOr<void> Function()? onClose})
      : _onAdd = onAdd ?? ((_) {}),
        _onError = onError ?? ((_, [__]) {}),
        _onClose = onClose ?? (() {});

  @override
  void onAdd(int value) {
    _onAdd(value);
  }

  @override
  void onError(Object error, [StackTrace? stackTrace]) {
    _onError(error, stackTrace);
  }

  @override
  FutureOr<void> onClose() => _onClose();
}

/// A subclass of [IOSinkBase] that takes all the overridable methods as
/// callbacks, for ease of testing.
class _IOSink extends IOSinkBase {
  final void Function(List<int> value) _onAdd;
  final void Function(Object error, [StackTrace? stackTrace]) _onError;
  final FutureOr<void> Function() _onClose;
  final Future<void> Function() _onFlush;

  _IOSink(
      {void Function(List<int> value)? onAdd,
      void Function(Object error, [StackTrace? stackTrace])? onError,
      FutureOr<void> Function()? onClose,
      Future<void> Function()? onFlush,
      Encoding encoding = utf8})
      : _onAdd = onAdd ?? ((_) {}),
        _onError = onError ?? ((_, [__]) {}),
        _onClose = onClose ?? (() {}),
        _onFlush = onFlush ?? (Future.value),
        super(encoding);

  @override
  void onAdd(List<int> value) {
    _onAdd(value);
  }

  @override
  void onError(Object error, [StackTrace? stackTrace]) {
    _onError(error, stackTrace);
  }

  @override
  FutureOr<void> onClose() => _onClose();

  @override
  Future<void> onFlush() => _onFlush();
}
