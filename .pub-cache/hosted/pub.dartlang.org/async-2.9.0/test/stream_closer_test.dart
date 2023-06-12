// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late StreamCloser<int> closer;
  setUp(() {
    closer = StreamCloser();
  });

  group('when the closer is never closed', () {
    test('forwards data and done events', () {
      expect(
          createStream().transform(closer).toList(), completion([1, 2, 3, 4]));
    });

    test('forwards error events', () {
      expect(Stream<int>.error('oh no').transform(closer).toList(),
          throwsA('oh no'));
    });

    test('transforms a broadcast stream into a broadcast stream', () {
      expect(Stream<int>.empty().transform(closer).isBroadcast, isTrue);
    });

    test("doesn't eagerly listen", () {
      var controller = StreamController<int>();
      var transformed = controller.stream.transform(closer);
      expect(controller.hasListener, isFalse);

      transformed.listen(null);
      expect(controller.hasListener, isTrue);
    });

    test('forwards pause and resume', () {
      var controller = StreamController<int>();
      var transformed = controller.stream.transform(closer);

      var subscription = transformed.listen(null);
      expect(controller.isPaused, isFalse);
      subscription.pause();
      expect(controller.isPaused, isTrue);
      subscription.resume();
      expect(controller.isPaused, isFalse);
    });

    test('forwards cancel', () {
      var isCancelled = false;
      var controller =
          StreamController<int>(onCancel: () => isCancelled = true);
      var transformed = controller.stream.transform(closer);

      expect(isCancelled, isFalse);
      var subscription = transformed.listen(null);
      expect(isCancelled, isFalse);
      subscription.cancel();
      expect(isCancelled, isTrue);
    });

    test('forwards errors from cancel', () {
      var controller = StreamController<int>(onCancel: () => throw 'oh no');

      expect(controller.stream.transform(closer).listen(null).cancel(),
          throwsA('oh no'));
    });
  });

  group('when a stream is added before the closer is closed', () {
    test('the stream emits a close event once the closer is closed', () async {
      var queue = StreamQueue(createStream().transform(closer));
      await expectLater(queue, emits(1));
      await expectLater(queue, emits(2));
      expect(closer.close(), completes);
      expect(queue, emitsDone);
    });

    test('the inner subscription is canceled once the closer is closed', () {
      var isCancelled = false;
      var controller =
          StreamController<int>(onCancel: () => isCancelled = true);

      expect(controller.stream.transform(closer), emitsDone);
      expect(closer.close(), completes);
      expect(isCancelled, isTrue);
    });

    test('closer.close() forwards errors from StreamSubscription.cancel()', () {
      var controller = StreamController<int>(onCancel: () => throw 'oh no');

      expect(controller.stream.transform(closer), emitsDone);
      expect(closer.close(), throwsA('oh no'));
    });

    test('closer.close() works even if a stream has already completed',
        () async {
      expect(await createStream().transform(closer).toList(),
          equals([1, 2, 3, 4]));
      expect(closer.close(), completes);
    });

    test('closer.close() works even if a stream has already been canceled',
        () async {
      createStream().transform(closer).listen(null).cancel();
      expect(closer.close(), completes);
    });

    group('but listened afterwards', () {
      test('the output stream immediately emits done', () {
        var stream = createStream().transform(closer);
        expect(closer.close(), completes);
        expect(stream, emitsDone);
      });

      test(
          'the underlying subscription is never listened if the stream is '
          'never listened', () async {
        var controller =
            StreamController<int>(onListen: expectAsync0(() {}, count: 0));
        controller.stream.transform(closer);

        expect(closer.close(), completes);

        await pumpEventQueue();
      });

      test(
          'the underlying subscription is listened and then canceled once the '
          'stream is listened', () {
        var controller = StreamController<int>(
            onListen: expectAsync0(() {}), onCancel: expectAsync0(() {}));
        var stream = controller.stream.transform(closer);

        expect(closer.close(), completes);

        stream.listen(null);
      });

      test('Subscription.cancel() errors are silently ignored', () async {
        var controller =
            StreamController<int>(onCancel: expectAsync0(() => throw 'oh no'));
        var stream = controller.stream.transform(closer);

        expect(closer.close(), completes);

        stream.listen(null);
        await pumpEventQueue();
      });
    });
  });

  group('when a stream is added after the closer is closed', () {
    test('the output stream immediately emits done', () {
      expect(closer.close(), completes);
      expect(createStream().transform(closer), emitsDone);
    });

    test(
        'the underlying subscription is never listened if the stream is never '
        'listened', () async {
      expect(closer.close(), completes);

      var controller =
          StreamController<int>(onListen: expectAsync0(() {}, count: 0));
      controller.stream.transform(closer);

      await pumpEventQueue();
    });

    test(
        'the underlying subscription is listened and then canceled once the '
        'stream is listened', () {
      expect(closer.close(), completes);

      var controller = StreamController<int>(
          onListen: expectAsync0(() {}), onCancel: expectAsync0(() {}));

      controller.stream.transform(closer).listen(null);
    });

    test('Subscription.cancel() errors are silently ignored', () async {
      expect(closer.close(), completes);

      var controller =
          StreamController<int>(onCancel: expectAsync0(() => throw 'oh no'));

      controller.stream.transform(closer).listen(null);

      await pumpEventQueue();
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
