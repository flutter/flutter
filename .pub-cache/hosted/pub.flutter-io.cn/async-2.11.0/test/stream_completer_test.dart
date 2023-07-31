// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart' show StreamCompleter;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('a stream is linked before listening', () async {
    var completer = StreamCompleter();
    completer.setSourceStream(createStream());
    expect(completer.stream.toList(), completion([1, 2, 3, 4]));
  });

  test('listened to before a stream is linked', () async {
    var completer = StreamCompleter();
    var done = completer.stream.toList();
    await flushMicrotasks();
    completer.setSourceStream(createStream());
    expect(done, completion([1, 2, 3, 4]));
  });

  test("cancel before linking a stream doesn't listen on stream", () async {
    var completer = StreamCompleter();
    var subscription = completer.stream.listen(null);
    subscription.pause(); // Should be ignored.
    subscription.cancel();
    completer.setSourceStream(UnusableStream()); // Doesn't throw.
  });

  test('listen and pause before linking stream', () async {
    var controller = StreamCompleter();
    var events = [];
    var subscription = controller.stream.listen(events.add);
    var done = subscription.asFuture();
    subscription.pause();
    var sourceController = StreamController();
    sourceController
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(4);
    controller.setSourceStream(sourceController.stream);
    await flushMicrotasks();
    expect(sourceController.hasListener, isTrue);
    expect(sourceController.isPaused, isTrue);
    expect(events, []);
    subscription.resume();
    await flushMicrotasks();
    expect(sourceController.hasListener, isTrue);
    expect(sourceController.isPaused, isFalse);
    expect(events, [1, 2, 3, 4]);
    sourceController.close();
    await done;
    expect(events, [1, 2, 3, 4]);
  });

  test('pause more than once', () async {
    var completer = StreamCompleter();
    var events = [];
    var subscription = completer.stream.listen(events.add);
    var done = subscription.asFuture();
    subscription.pause();
    subscription.pause();
    subscription.pause();
    completer.setSourceStream(createStream());
    for (var i = 0; i < 3; i++) {
      await flushMicrotasks();
      expect(events, []);
      subscription.resume();
    }
    await done;
    expect(events, [1, 2, 3, 4]);
  });

  test('cancel new stream before source is done', () async {
    var completer = StreamCompleter<int>();
    var lastEvent = -1;
    var controller = StreamController<int>();
    late StreamSubscription subscription;
    subscription = completer.stream.listen((value) {
      expect(value, lessThan(3));
      lastEvent = value;
      if (value == 2) {
        subscription.cancel();
      }
    },
        onError: unreachable('error'),
        onDone: unreachable('done'),
        cancelOnError: true);
    completer.setSourceStream(controller.stream);
    expect(controller.hasListener, isTrue);

    await flushMicrotasks();
    expect(controller.hasListener, isTrue);
    controller.add(1);

    await flushMicrotasks();
    expect(lastEvent, 1);
    expect(controller.hasListener, isTrue);
    controller.add(2);

    await flushMicrotasks();
    expect(lastEvent, 2);
    expect(controller.hasListener, isFalse);
  });

  test('complete with setEmpty before listening', () async {
    var completer = StreamCompleter();
    completer.setEmpty();
    var done = Completer();
    completer.stream.listen(unreachable('data'),
        onError: unreachable('error'), onDone: done.complete);
    await done.future;
  });

  test('complete with setEmpty after listening', () async {
    var completer = StreamCompleter();
    var done = Completer();
    completer.stream.listen(unreachable('data'),
        onError: unreachable('error'), onDone: done.complete);
    completer.setEmpty();
    await done.future;
  });

  test("source stream isn't listened to until completer stream is", () async {
    var completer = StreamCompleter();
    late StreamController controller;
    controller = StreamController(onListen: () {
      scheduleMicrotask(controller.close);
    });

    completer.setSourceStream(controller.stream);
    await flushMicrotasks();
    expect(controller.hasListener, isFalse);
    var subscription = completer.stream.listen(null);
    expect(controller.hasListener, isTrue);
    await subscription.asFuture();
  });

  test('cancelOnError true when listening before linking stream', () async {
    var completer = StreamCompleter<Object>();
    Object lastEvent = -1;
    var controller = StreamController<Object>();
    completer.stream.listen((value) {
      expect(value, lessThan(3));
      lastEvent = value;
    }, onError: (Object value) {
      expect(value, '3');
      lastEvent = value;
    }, onDone: unreachable('done'), cancelOnError: true);
    completer.setSourceStream(controller.stream);
    expect(controller.hasListener, isTrue);

    await flushMicrotasks();
    expect(controller.hasListener, isTrue);
    controller.add(1);

    await flushMicrotasks();
    expect(lastEvent, 1);
    expect(controller.hasListener, isTrue);
    controller.add(2);

    await flushMicrotasks();
    expect(lastEvent, 2);
    expect(controller.hasListener, isTrue);
    controller.addError('3');

    await flushMicrotasks();
    expect(lastEvent, '3');
    expect(controller.hasListener, isFalse);
  });

  test('cancelOnError true when listening after linking stream', () async {
    var completer = StreamCompleter<Object>();
    Object lastEvent = -1;
    var controller = StreamController<Object>();
    completer.setSourceStream(controller.stream);
    controller.add(1);
    expect(controller.hasListener, isFalse);

    completer.stream.listen((value) {
      expect(value, lessThan(3));
      lastEvent = value;
    }, onError: (Object value) {
      expect(value, '3');
      lastEvent = value;
    }, onDone: unreachable('done'), cancelOnError: true);

    expect(controller.hasListener, isTrue);

    await flushMicrotasks();
    expect(lastEvent, 1);
    expect(controller.hasListener, isTrue);
    controller.add(2);

    await flushMicrotasks();
    expect(lastEvent, 2);
    expect(controller.hasListener, isTrue);
    controller.addError('3');

    await flushMicrotasks();
    expect(controller.hasListener, isFalse);
  });

  test('linking a stream after setSourceStream before listen', () async {
    var completer = StreamCompleter();
    completer.setSourceStream(createStream());
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
    await completer.stream.toList();
    // Still fails after source is done
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
  });

  test('linking a stream after setSourceStream after listen', () async {
    var completer = StreamCompleter();
    var list = completer.stream.toList();
    completer.setSourceStream(createStream());
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
    await list;
    // Still fails after source is done.
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
  });

  test('linking a stream after setEmpty before listen', () async {
    var completer = StreamCompleter();
    completer.setEmpty();
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
    await completer.stream.toList();
    // Still fails after source is done
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
  });

  test('linking a stream after setEmpty() after listen', () async {
    var completer = StreamCompleter();
    var list = completer.stream.toList();
    completer.setEmpty();
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
    await list;
    // Still fails after source is done.
    expect(() => completer.setSourceStream(createStream()), throwsStateError);
    expect(() => completer.setEmpty(), throwsStateError);
  });

  test('listening more than once after setting stream', () async {
    var completer = StreamCompleter();
    completer.setSourceStream(createStream());
    var list = completer.stream.toList();
    expect(() => completer.stream.toList(), throwsStateError);
    await list;
    expect(() => completer.stream.toList(), throwsStateError);
  });

  test('listening more than once before setting stream', () async {
    var completer = StreamCompleter();
    completer.stream.toList();
    expect(() => completer.stream.toList(), throwsStateError);
  });

  test('setting onData etc. before and after setting stream', () async {
    var completer = StreamCompleter<int>();
    var controller = StreamController<int>();
    var subscription = completer.stream.listen(null);
    Object lastEvent = 0;
    subscription.onData((value) => lastEvent = value);
    subscription.onError((value) => lastEvent = '$value');
    subscription.onDone(() => lastEvent = -1);
    completer.setSourceStream(controller.stream);
    await flushMicrotasks();
    controller.add(1);
    await flushMicrotasks();
    expect(lastEvent, 1);
    controller.addError(2);
    await flushMicrotasks();
    expect(lastEvent, '2');
    subscription.onData((value) => lastEvent = -value);
    subscription.onError((value) => lastEvent = '${-(value as int)}');
    controller.add(1);
    await flushMicrotasks();
    expect(lastEvent, -1);
    controller.addError(2);
    await flushMicrotasks();
    expect(lastEvent, '-2');
    controller.close();
    await flushMicrotasks();
    expect(lastEvent, -1);
  });

  test('pause w/ resume future accross setting stream', () async {
    var completer = StreamCompleter();
    var resume = Completer();
    var subscription = completer.stream.listen(unreachable('data'));
    subscription.pause(resume.future);
    await flushMicrotasks();
    completer.setSourceStream(createStream());
    await flushMicrotasks();
    resume.complete();
    var events = [];
    subscription.onData(events.add);
    await subscription.asFuture();
    expect(events, [1, 2, 3, 4]);
  });

  test('asFuture with error accross setting stream', () async {
    var completer = StreamCompleter();
    var controller = StreamController();
    var subscription =
        completer.stream.listen(unreachable('data'), cancelOnError: false);
    var done = subscription.asFuture();
    expect(controller.hasListener, isFalse);
    completer.setSourceStream(controller.stream);
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);
    controller.addError(42);
    await done.then(unreachable('data'), onError: (error) {
      expect(error, 42);
    });
    expect(controller.hasListener, isFalse);
  });

  group('setError()', () {
    test('produces a stream that emits a single error', () {
      var completer = StreamCompleter();
      completer.stream.listen(unreachable('data'),
          onError: expectAsync2((error, stackTrace) {
        expect(error, equals('oh no'));
      }), onDone: expectAsync0(() {}));

      completer.setError('oh no');
    });

    test('produces a stream that emits a single error on a later listen',
        () async {
      var completer = StreamCompleter();
      completer.setError('oh no');
      await flushMicrotasks();

      completer.stream.listen(unreachable('data'),
          onError: expectAsync2((error, stackTrace) {
        expect(error, equals('oh no'));
      }), onDone: expectAsync0(() {}));
    });
  });
}

Stream<int> createStream() async* {
  yield 1;
  await flushMicrotasks();
  yield 2;
  await flushMicrotasks();
  yield 3;
  await flushMicrotasks();
  yield 4;
}
