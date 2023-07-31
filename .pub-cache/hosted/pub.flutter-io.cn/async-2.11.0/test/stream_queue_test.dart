// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE filevents.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('source stream', () {
    test('is listened to on first request, paused between requests', () async {
      var controller = StreamController<int>();
      var events = StreamQueue<int>(controller.stream);
      await flushMicrotasks();
      expect(controller.hasListener, isFalse);

      var next = events.next;
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isFalse);

      controller.add(1);

      expect(await next, 1);
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isTrue);

      next = events.next;
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isFalse);

      controller.add(2);

      expect(await next, 2);
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isTrue);

      events.cancel();
      expect(controller.hasListener, isFalse);
    });
  });

  group('eventsDispatched', () {
    test('increments after a next future completes', () async {
      var events = StreamQueue<int>(createStream());

      expect(events.eventsDispatched, equals(0));
      await flushMicrotasks();
      expect(events.eventsDispatched, equals(0));

      var next = events.next;
      expect(events.eventsDispatched, equals(0));

      await next;
      expect(events.eventsDispatched, equals(1));

      await events.next;
      expect(events.eventsDispatched, equals(2));
    });

    test('increments multiple times for multi-value requests', () async {
      var events = StreamQueue<int>(createStream());
      await events.take(3);
      expect(events.eventsDispatched, equals(3));
    });

    test('increments multiple times for an accepted transaction', () async {
      var events = StreamQueue<int>(createStream());
      await events.withTransaction((queue) async {
        await queue.next;
        await queue.next;
        return true;
      });
      expect(events.eventsDispatched, equals(2));
    });

    test("doesn't increment for rest requests", () async {
      var events = StreamQueue<int>(createStream());
      await events.rest.toList();
      expect(events.eventsDispatched, equals(0));
    });
  });

  group('lookAhead operation', () {
    test('as simple list of events', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.lookAhead(4), [1, 2, 3, 4]);
      expect(await events.next, 1);
      expect(await events.lookAhead(2), [2, 3]);
      expect(await events.take(2), [2, 3]);
      expect(await events.next, 4);
      await events.cancel();
    });

    test('of 0 events', () async {
      var events = StreamQueue<int>(createStream());
      expect(events.lookAhead(0), completion([]));
      expect(events.next, completion(1));
      expect(events.lookAhead(0), completion([]));
      expect(events.next, completion(2));
      expect(events.lookAhead(0), completion([]));
      expect(events.next, completion(3));
      expect(events.lookAhead(0), completion([]));
      expect(events.next, completion(4));
      expect(events.lookAhead(0), completion([]));
      expect(events.lookAhead(5), completion([]));
      expect(events.next, throwsStateError);
      await events.cancel();
    });

    test('with bad arguments throws', () async {
      var events = StreamQueue<int>(createStream());
      expect(() => events.lookAhead(-1), throwsArgumentError);
      expect(await events.next, 1); // Did not consume event.
      expect(() => events.lookAhead(-1), throwsArgumentError);
      expect(await events.next, 2); // Did not consume event.
      await events.cancel();
    });

    test('of too many arguments', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.lookAhead(6), [1, 2, 3, 4]);
      await events.cancel();
    });

    test('too large later', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.lookAhead(6), [3, 4]);
      await events.cancel();
    });

    test('error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(events.lookAhead(4), throwsA('To err is divine!'));
      expect(events.take(4), throwsA('To err is divine!'));
      expect(await events.next, 4);
      await events.cancel();
    });
  });

  group('next operation', () {
    test('simple sequence of requests', () async {
      var events = StreamQueue<int>(createStream());
      for (var i = 1; i <= 4; i++) {
        expect(await events.next, i);
      }
      expect(events.next, throwsStateError);
    });

    test('multiple requests at the same time', () async {
      var events = StreamQueue<int>(createStream());
      var result = await Future.wait(
          [events.next, events.next, events.next, events.next]);
      expect(result, [1, 2, 3, 4]);
      await events.cancel();
    });

    test('sequence of requests with error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(events.next, throwsA('To err is divine!'));
      expect(await events.next, 4);
      await events.cancel();
    });
  });

  group('skip operation', () {
    test('of two elements in the middle of sequence', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.skip(2), 0);
      expect(await events.next, 4);
      await events.cancel();
    });

    test('with negative/bad arguments throws', () async {
      var events = StreamQueue<int>(createStream());
      expect(() => events.skip(-1), throwsArgumentError);
      // A non-int throws either a type error or an argument error,
      // depending on whether it's checked mode or not.
      expect(await events.next, 1); // Did not consume event.
      expect(() => events.skip(-1), throwsArgumentError);
      expect(await events.next, 2); // Did not consume event.
      await events.cancel();
    });

    test('of 0 elements works', () async {
      var events = StreamQueue<int>(createStream());
      expect(events.skip(0), completion(0));
      expect(events.next, completion(1));
      expect(events.skip(0), completion(0));
      expect(events.next, completion(2));
      expect(events.skip(0), completion(0));
      expect(events.next, completion(3));
      expect(events.skip(0), completion(0));
      expect(events.next, completion(4));
      expect(events.skip(0), completion(0));
      expect(events.skip(5), completion(5));
      expect(events.next, throwsStateError);
      await events.cancel();
    });

    test('of too many events ends at stream start', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.skip(6), 2);
      await events.cancel();
    });

    test('of too many events after some events', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.skip(6), 4);
      await events.cancel();
    });

    test('of too many events ends at stream end', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.next, 3);
      expect(await events.next, 4);
      expect(await events.skip(2), 2);
      await events.cancel();
    });

    test('of events with error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(events.skip(4), throwsA('To err is divine!'));
      expect(await events.next, 4);
      await events.cancel();
    });

    test('of events with error, and skip again after', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(events.skip(4), throwsA('To err is divine!'));
      expect(events.skip(2), completion(1));
      await events.cancel();
    });
    test('multiple skips at same time complete in order.', () async {
      var events = StreamQueue<int>(createStream());
      var skip1 = events.skip(1);
      var skip2 = events.skip(0);
      var skip3 = events.skip(4);
      var skip4 = events.skip(1);
      var index = 0;
      // Check that futures complete in order.
      Func1Required<int?> sequence(expectedValue, sequenceIndex) => (value) {
            expect(value, expectedValue);
            expect(index, sequenceIndex);
            index++;
            return null;
          };
      await Future.wait([
        skip1.then(sequence(0, 0)),
        skip2.then(sequence(0, 1)),
        skip3.then(sequence(1, 2)),
        skip4.then(sequence(1, 3))
      ]);
      await events.cancel();
    });
  });

  group('take operation', () {
    test('as simple take of events', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.take(2), [2, 3]);
      expect(await events.next, 4);
      await events.cancel();
    });

    test('of 0 events', () async {
      var events = StreamQueue<int>(createStream());
      expect(events.take(0), completion([]));
      expect(events.next, completion(1));
      expect(events.take(0), completion([]));
      expect(events.next, completion(2));
      expect(events.take(0), completion([]));
      expect(events.next, completion(3));
      expect(events.take(0), completion([]));
      expect(events.next, completion(4));
      expect(events.take(0), completion([]));
      expect(events.take(5), completion([]));
      expect(events.next, throwsStateError);
      await events.cancel();
    });

    test('with bad arguments throws', () async {
      var events = StreamQueue<int>(createStream());
      expect(() => events.take(-1), throwsArgumentError);
      expect(await events.next, 1); // Did not consume event.
      expect(() => events.take(-1), throwsArgumentError);
      expect(await events.next, 2); // Did not consume event.
      await events.cancel();
    });

    test('of too many arguments', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.take(6), [1, 2, 3, 4]);
      await events.cancel();
    });

    test('too large later', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.take(6), [3, 4]);
      await events.cancel();
    });

    test('error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(events.take(4), throwsA('To err is divine!'));
      expect(await events.next, 4);
      await events.cancel();
    });
  });

  group('rest operation', () {
    test('after single next', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.rest.toList(), [2, 3, 4]);
    });

    test('at start', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.rest.toList(), [1, 2, 3, 4]);
    });

    test('at end', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.next, 3);
      expect(await events.next, 4);
      expect(await events.rest.toList(), isEmpty);
    });

    test('after end', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.next, 3);
      expect(await events.next, 4);
      expect(events.next, throwsStateError);
      expect(await events.rest.toList(), isEmpty);
    });

    test('after receiving done requested before', () async {
      var events = StreamQueue<int>(createStream());
      var next1 = events.next;
      var next2 = events.next;
      var next3 = events.next;
      var rest = events.rest;
      for (var i = 0; i < 10; i++) {
        await flushMicrotasks();
      }
      expect(await next1, 1);
      expect(await next2, 2);
      expect(await next3, 3);
      expect(await rest.toList(), [4]);
    });

    test('with an error event error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(await events.next, 1);
      var rest = events.rest;
      var events2 = StreamQueue(rest);
      expect(await events2.next, 2);
      expect(events2.next, throwsA('To err is divine!'));
      expect(await events2.next, 4);
    });

    test('closes the events, prevents other operations', () async {
      var events = StreamQueue<int>(createStream());
      var stream = events.rest;
      expect(() => events.next, throwsStateError);
      expect(() => events.skip(1), throwsStateError);
      expect(() => events.take(1), throwsStateError);
      expect(() => events.rest, throwsStateError);
      expect(() => events.cancel(), throwsStateError);
      expect(stream.toList(), completion([1, 2, 3, 4]));
    });

    test('forwards to underlying stream', () async {
      var cancel = Completer();
      var controller = StreamController<int>(onCancel: () => cancel.future);
      var events = StreamQueue<int>(controller.stream);
      expect(controller.hasListener, isFalse);
      var next = events.next;
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isFalse);

      controller.add(1);
      expect(await next, 1);
      expect(controller.isPaused, isTrue);

      var rest = events.rest;
      var subscription = rest.listen(null);
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isFalse);

      dynamic lastEvent;
      subscription.onData((value) => lastEvent = value);

      controller.add(2);

      await flushMicrotasks();
      expect(lastEvent, 2);
      expect(controller.hasListener, isTrue);
      expect(controller.isPaused, isFalse);

      subscription.pause();
      expect(controller.isPaused, isTrue);

      controller.add(3);

      await flushMicrotasks();
      expect(lastEvent, 2);
      subscription.resume();

      await flushMicrotasks();
      expect(lastEvent, 3);

      var cancelFuture = subscription.cancel();
      expect(controller.hasListener, isFalse);
      cancel.complete(42);
      expect(cancelFuture, completion(42));
    });
  });

  group('peek operation', () {
    test('peeks one event', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.peek, 1);
      expect(await events.next, 1);
      expect(await events.peek, 2);
      expect(await events.take(2), [2, 3]);
      expect(await events.peek, 4);
      expect(await events.next, 4);
      // Throws at end.
      expect(events.peek, throwsA(anything));
      await events.cancel();
    });
    test('multiple requests at the same time', () async {
      var events = StreamQueue<int>(createStream());
      var result = await Future.wait(
          [events.peek, events.peek, events.next, events.peek, events.peek]);
      expect(result, [1, 1, 1, 2, 2]);
      await events.cancel();
    });
    test('sequence of requests with error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(events.peek, throwsA('To err is divine!'));
      // Error stays in queue.
      expect(events.peek, throwsA('To err is divine!'));
      expect(events.next, throwsA('To err is divine!'));
      expect(await events.next, 4);
      await events.cancel();
    });
  });

  group('cancel operation', () {
    test('closes the events, prevents any other operation', () async {
      var events = StreamQueue<int>(createStream());
      await events.cancel();
      expect(() => events.lookAhead(1), throwsStateError);
      expect(() => events.next, throwsStateError);
      expect(() => events.peek, throwsStateError);
      expect(() => events.skip(1), throwsStateError);
      expect(() => events.take(1), throwsStateError);
      expect(() => events.rest, throwsStateError);
      expect(() => events.cancel(), throwsStateError);
    });

    test('cancels underlying subscription when called before any event',
        () async {
      var cancelFuture = Future.value(42);
      var controller = StreamController<int>(onCancel: () => cancelFuture);
      var events = StreamQueue<int>(controller.stream);
      expect(await events.cancel(), 42);
    });

    test('cancels underlying subscription, returns result', () async {
      var cancelFuture = Future.value(42);
      var controller = StreamController<int>(onCancel: () => cancelFuture);
      var events = StreamQueue<int>(controller.stream);
      controller.add(1);
      expect(await events.next, 1);
      expect(await events.cancel(), 42);
    });

    group('with immediate: true', () {
      test('closes the events, prevents any other operation', () async {
        var events = StreamQueue<int>(createStream());
        await events.cancel(immediate: true);
        expect(() => events.next, throwsStateError);
        expect(() => events.skip(1), throwsStateError);
        expect(() => events.take(1), throwsStateError);
        expect(() => events.rest, throwsStateError);
        expect(() => events.cancel(), throwsStateError);
      });

      test('cancels the underlying subscription immediately', () async {
        var controller = StreamController<int>();
        controller.add(1);

        var events = StreamQueue<int>(controller.stream);
        expect(await events.next, 1);
        expect(controller.hasListener, isTrue);

        await events.cancel(immediate: true);
        expect(controller.hasListener, isFalse);
      });

      test('cancels the underlying subscription when called before any event',
          () async {
        var cancelFuture = Future.value(42);
        var controller = StreamController<int>(onCancel: () => cancelFuture);

        var events = StreamQueue<int>(controller.stream);
        expect(await events.cancel(immediate: true), 42);
      });

      test('closes pending requests', () async {
        var events = StreamQueue<int>(createStream());
        expect(await events.next, 1);
        expect(events.next, throwsStateError);
        expect(events.hasNext, completion(isFalse));

        await events.cancel(immediate: true);
      });

      test('returns the result of closing the underlying subscription',
          () async {
        var controller =
            StreamController<int>(onCancel: () => Future<int>.value(42));
        var events = StreamQueue<int>(controller.stream);
        expect(await events.cancel(immediate: true), 42);
      });

      test("listens and then cancels a stream that hasn't been listened to yet",
          () async {
        var wasListened = false;
        var controller =
            StreamController<int>(onListen: () => wasListened = true);
        var events = StreamQueue<int>(controller.stream);
        expect(wasListened, isFalse);
        expect(controller.hasListener, isFalse);

        await events.cancel(immediate: true);
        expect(wasListened, isTrue);
        expect(controller.hasListener, isFalse);
      });
    });
  });

  group('hasNext operation', () {
    test('true at start', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.hasNext, isTrue);
    });

    test('true after start', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, isTrue);
    });

    test('true at end', () async {
      var events = StreamQueue<int>(createStream());
      for (var i = 1; i <= 4; i++) {
        expect(await events.next, i);
      }
      expect(await events.hasNext, isFalse);
    });

    test('true when enqueued', () async {
      var events = StreamQueue<int>(createStream());
      var values = <int>[];
      for (var i = 1; i <= 3; i++) {
        events.next.then(values.add);
      }
      expect(values, isEmpty);
      expect(await events.hasNext, isTrue);
      expect(values, [1, 2, 3]);
    });

    test('false when enqueued', () async {
      var events = StreamQueue<int>(createStream());
      var values = <int>[];
      for (var i = 1; i <= 4; i++) {
        events.next.then(values.add);
      }
      expect(values, isEmpty);
      expect(await events.hasNext, isFalse);
      expect(values, [1, 2, 3, 4]);
    });

    test('true when data event', () async {
      var controller = StreamController<int>();
      var events = StreamQueue<int>(controller.stream);

      bool? hasNext;
      events.hasNext.then((result) {
        hasNext = result;
      });
      await flushMicrotasks();
      expect(hasNext, isNull);
      controller.add(42);
      expect(hasNext, isNull);
      await flushMicrotasks();
      expect(hasNext, isTrue);
    });

    test('true when error event', () async {
      var controller = StreamController<int>();
      var events = StreamQueue<int>(controller.stream);

      bool? hasNext;
      events.hasNext.then((result) {
        hasNext = result;
      });
      await flushMicrotasks();
      expect(hasNext, isNull);
      controller.addError('BAD');
      expect(hasNext, isNull);
      await flushMicrotasks();
      expect(hasNext, isTrue);
      expect(events.next, throwsA('BAD'));
    });

    test('- hasNext after hasNext', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.hasNext, true);
      expect(await events.hasNext, true);
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.hasNext, true);
      expect(await events.next, 2);
      expect(await events.hasNext, true);
      expect(await events.hasNext, true);
      expect(await events.next, 3);
      expect(await events.hasNext, true);
      expect(await events.hasNext, true);
      expect(await events.next, 4);
      expect(await events.hasNext, false);
      expect(await events.hasNext, false);
    });

    test('- next after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.next, 2);
      expect(await events.next, 3);
    });

    test('- next after true, enqueued', () async {
      var events = StreamQueue<int>(createStream());
      var responses = <Object>[];
      events.next.then(responses.add);
      events.hasNext.then(responses.add);
      events.next.then(responses.add);
      do {
        await flushMicrotasks();
      } while (responses.length < 3);
      expect(responses, [1, true, 2]);
    });

    test('- skip 0 after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.skip(0), 0);
      expect(await events.next, 2);
    });

    test('- skip 1 after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.skip(1), 0);
      expect(await events.next, 3);
    });

    test('- skip 2 after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.skip(2), 0);
      expect(await events.next, 4);
    });

    test('- take 0 after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.take(0), isEmpty);
      expect(await events.next, 2);
    });

    test('- take 1 after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.take(1), [2]);
      expect(await events.next, 3);
    });

    test('- take 2 after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      expect(await events.take(2), [2, 3]);
      expect(await events.next, 4);
    });

    test('- rest after true', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.hasNext, true);
      var stream = events.rest;
      expect(await stream.toList(), [2, 3, 4]);
    });

    test('- rest after true, at last', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.next, 3);
      expect(await events.hasNext, true);
      var stream = events.rest;
      expect(await stream.toList(), [4]);
    });

    test('- rest after false', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.next, 3);
      expect(await events.next, 4);
      expect(await events.hasNext, false);
      var stream = events.rest;
      expect(await stream.toList(), isEmpty);
    });

    test('- cancel after true on data', () async {
      var events = StreamQueue<int>(createStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.hasNext, true);
      expect(await events.cancel(), null);
    });

    test('- cancel after true on error', () async {
      var events = StreamQueue<int>(createErrorStream());
      expect(await events.next, 1);
      expect(await events.next, 2);
      expect(await events.hasNext, true);
      expect(await events.cancel(), null);
    });
  });

  group('startTransaction operation produces a transaction that', () {
    late StreamQueue<int> events;
    late StreamQueueTransaction<int> transaction;
    late StreamQueue<int> queue1;
    late StreamQueue<int> queue2;
    setUp(() async {
      events = StreamQueue(createStream());
      expect(await events.next, 1);
      transaction = events.startTransaction();
      queue1 = transaction.newQueue();
      queue2 = transaction.newQueue();
    });

    group('emits queues that', () {
      test('independently emit events', () async {
        expect(await queue1.next, 2);
        expect(await queue2.next, 2);
        expect(await queue2.next, 3);
        expect(await queue1.next, 3);
        expect(await queue1.next, 4);
        expect(await queue2.next, 4);
        expect(await queue1.hasNext, isFalse);
        expect(await queue2.hasNext, isFalse);
      });

      test('queue requests for events', () async {
        expect(queue1.next, completion(2));
        expect(queue2.next, completion(2));
        expect(queue2.next, completion(3));
        expect(queue1.next, completion(3));
        expect(queue1.next, completion(4));
        expect(queue2.next, completion(4));
        expect(queue1.hasNext, completion(isFalse));
        expect(queue2.hasNext, completion(isFalse));
      });

      test('independently emit errors', () async {
        events = StreamQueue(createErrorStream());
        expect(await events.next, 1);
        transaction = events.startTransaction();
        queue1 = transaction.newQueue();
        queue2 = transaction.newQueue();

        expect(queue1.next, completion(2));
        expect(queue2.next, completion(2));
        expect(queue2.next, throwsA('To err is divine!'));
        expect(queue1.next, throwsA('To err is divine!'));
        expect(queue1.next, completion(4));
        expect(queue2.next, completion(4));
        expect(queue1.hasNext, completion(isFalse));
        expect(queue2.hasNext, completion(isFalse));
      });
    });

    group('when rejected', () {
      test('further original requests use the previous state', () async {
        expect(await queue1.next, 2);
        expect(await queue2.next, 2);
        expect(await queue2.next, 3);

        await flushMicrotasks();
        transaction.reject();

        expect(await events.next, 2);
        expect(await events.next, 3);
        expect(await events.next, 4);
        expect(await events.hasNext, isFalse);
      });

      test('pending original requests use the previous state', () async {
        expect(await queue1.next, 2);
        expect(await queue2.next, 2);
        expect(await queue2.next, 3);
        expect(events.next, completion(2));
        expect(events.next, completion(3));
        expect(events.next, completion(4));
        expect(events.hasNext, completion(isFalse));

        await flushMicrotasks();
        transaction.reject();
      });

      test('further child requests act as though the stream was closed',
          () async {
        expect(await queue1.next, 2);
        transaction.reject();

        expect(await queue1.hasNext, isFalse);
        expect(queue1.next, throwsStateError);
      });

      test('pending child requests act as though the stream was closed',
          () async {
        expect(await queue1.next, 2);
        expect(queue1.hasNext, completion(isFalse));
        expect(queue1.next, throwsStateError);
        transaction.reject();
      });

      // Regression test.
      test('pending child rest requests emit no more events', () async {
        var controller = StreamController();
        var events = StreamQueue(controller.stream);
        var transaction = events.startTransaction();
        var queue = transaction.newQueue();

        // This should emit no more events after the transaction is rejected.
        queue.rest.listen(expectAsync1((_) {}, count: 3),
            onDone: expectAsync0(() {}, count: 0));

        controller.add(1);
        controller.add(2);
        controller.add(3);
        await flushMicrotasks();

        transaction.reject();
        await flushMicrotasks();

        // These shouldn't affect the result of `queue.rest.toList()`.
        controller.add(4);
        controller.add(5);
      });

      test("child requests' cancel() may still be called explicitly", () async {
        transaction.reject();
        await queue1.cancel();
      });

      test('calls to commit() or reject() fail', () async {
        transaction.reject();
        expect(transaction.reject, throwsStateError);
        expect(() => transaction.commit(queue1), throwsStateError);
      });

      test('before the transaction emits any events, does nothing', () async {
        var controller = StreamController();
        var events = StreamQueue(controller.stream);

        // Queue a request before the transaction, but don't let it complete
        // until we're done with the transaction.
        expect(events.next, completion(equals(1)));
        events.startTransaction().reject();
        expect(events.next, completion(equals(2)));

        await flushMicrotasks();
        controller.add(1);
        await flushMicrotasks();
        controller.add(2);
        await flushMicrotasks();
        controller.close();
      });
    });

    group('when committed', () {
      test('further original requests use the committed state', () async {
        expect(await queue1.next, 2);
        await flushMicrotasks();
        transaction.commit(queue1);
        expect(await events.next, 3);
      });

      test('pending original requests use the committed state', () async {
        expect(await queue1.next, 2);
        expect(events.next, completion(3));
        await flushMicrotasks();
        transaction.commit(queue1);
      });

      test('further child requests act as though the stream was closed',
          () async {
        expect(await queue2.next, 2);
        transaction.commit(queue2);

        expect(await queue1.hasNext, isFalse);
        expect(queue1.next, throwsStateError);
      });

      test('pending child requests act as though the stream was closed',
          () async {
        expect(await queue2.next, 2);
        expect(queue1.hasNext, completion(isFalse));
        expect(queue1.next, throwsStateError);
        transaction.commit(queue2);
      });

      test('further requests act as though the stream was closed', () async {
        expect(await queue1.next, 2);
        transaction.commit(queue1);

        expect(await queue1.hasNext, isFalse);
        expect(queue1.next, throwsStateError);
      });

      test('cancel() may still be called explicitly', () async {
        expect(await queue1.next, 2);
        transaction.commit(queue1);
        await queue1.cancel();
      });

      test('throws if there are pending requests', () async {
        expect(await queue1.next, 2);
        expect(queue1.hasNext, completion(isTrue));
        expect(() => transaction.commit(queue1), throwsStateError);
      });

      test('calls to commit() or reject() fail', () async {
        transaction.commit(queue1);
        expect(transaction.reject, throwsStateError);
        expect(() => transaction.commit(queue1), throwsStateError);
      });

      test('before the transaction emits any events, does nothing', () async {
        var controller = StreamController();
        var events = StreamQueue(controller.stream);

        // Queue a request before the transaction, but don't let it complete
        // until we're done with the transaction.
        expect(events.next, completion(equals(1)));
        var transaction = events.startTransaction();
        transaction.commit(transaction.newQueue());
        expect(events.next, completion(equals(2)));

        await flushMicrotasks();
        controller.add(1);
        await flushMicrotasks();
        controller.add(2);
        await flushMicrotasks();
        controller.close();
      });
    });
  });

  group('withTransaction operation', () {
    late StreamQueue<int> events;
    setUp(() async {
      events = StreamQueue(createStream());
      expect(await events.next, 1);
    });

    test('passes a copy of the parent queue', () async {
      await events.withTransaction(expectAsync1((queue) async {
        expect(await queue.next, 2);
        expect(await queue.next, 3);
        expect(await queue.next, 4);
        expect(await queue.hasNext, isFalse);
        return true;
      }));
    });

    test(
        'the parent queue continues from the child position if it returns '
        'true', () async {
      await events.withTransaction(expectAsync1((queue) async {
        expect(await queue.next, 2);
        return true;
      }));

      expect(await events.next, 3);
    });

    test(
        'the parent queue continues from its original position if it returns '
        'false', () async {
      await events.withTransaction(expectAsync1((queue) async {
        expect(await queue.next, 2);
        return false;
      }));

      expect(await events.next, 2);
    });

    test('the parent queue continues from the child position if it throws', () {
      expect(events.withTransaction(expectAsync1((queue) async {
        expect(await queue.next, 2);
        throw 'oh no';
      })), throwsA('oh no'));

      expect(events.next, completion(3));
    });

    test('returns whether the transaction succeeded', () {
      expect(events.withTransaction((_) async => true), completion(isTrue));
      expect(events.withTransaction((_) async => false), completion(isFalse));
    });
  });

  group('cancelable operation', () {
    late StreamQueue<int> events;
    setUp(() async {
      events = StreamQueue(createStream());
      expect(await events.next, 1);
    });

    test('passes a copy of the parent queue', () async {
      await events.cancelable(expectAsync1((queue) async {
        expect(await queue.next, 2);
        expect(await queue.next, 3);
        expect(await queue.next, 4);
        expect(await queue.hasNext, isFalse);
      })).value;
    });

    test('the parent queue continues from the child position by default',
        () async {
      await events.cancelable(expectAsync1((queue) async {
        expect(await queue.next, 2);
      })).value;

      expect(await events.next, 3);
    });

    test(
        'the parent queue continues from the child position if an error is '
        'thrown', () async {
      expect(
          events.cancelable(expectAsync1((queue) async {
            expect(await queue.next, 2);
            throw 'oh no';
          })).value,
          throwsA('oh no'));

      expect(events.next, completion(3));
    });

    test('the parent queue continues from the original position if canceled',
        () async {
      var operation = events.cancelable(expectAsync1((queue) async {
        expect(await queue.next, 2);
      }));
      operation.cancel();

      expect(await events.next, 2);
    });

    test('forwards the value from the callback', () async {
      expect(
          await events.cancelable(expectAsync1((queue) async {
            expect(await queue.next, 2);
            return 'value';
          })).value,
          'value');
    });
  });

  test('all combinations sequential skip/next/take operations', () async {
    // Takes all combinations of two of next, skip and take, then ends with
    // doing rest. Each of the first rounds do 10 events of each type,
    // the rest does 20 elements.
    var eventCount = 20 * (3 * 3 + 1);
    var events = StreamQueue<int>(createLongStream(eventCount));

    // Test expecting [startIndex .. startIndex + 9] as events using
    // `next`.
    void nextTest(int startIndex) {
      for (var i = 0; i < 10; i++) {
        expect(events.next, completion(startIndex + i));
      }
    }

    // Test expecting 10 events to be skipped.
    void skipTest(startIndex) {
      expect(events.skip(10), completion(0));
    }

    // Test expecting [startIndex .. startIndex + 9] as events using
    // `take(10)`.
    void takeTest(int startIndex) {
      expect(events.take(10),
          completion(List.generate(10, (i) => startIndex + i)));
    }

    var tests = [nextTest, skipTest, takeTest];

    var counter = 0;
    // Run through all pairs of two tests and run them.
    for (var i = 0; i < tests.length; i++) {
      for (var j = 0; j < tests.length; j++) {
        tests[i](counter);
        tests[j](counter + 10);
        counter += 20;
      }
    }
    // Then expect 20 more events as a `rest` call.
    expect(events.rest.toList(),
        completion(List.generate(20, (i) => counter + i)));
  });
}

typedef Func1Required<T> = T Function(T value);

Stream<int> createStream() async* {
  yield 1;
  await flushMicrotasks();
  yield 2;
  await flushMicrotasks();
  yield 3;
  await flushMicrotasks();
  yield 4;
}

Stream<int> createErrorStream() {
  var controller = StreamController<int>();
  () async {
    controller.add(1);
    await flushMicrotasks();
    controller.add(2);
    await flushMicrotasks();
    controller.addError('To err is divine!');
    await flushMicrotasks();
    controller.add(4);
    await flushMicrotasks();
    controller.close();
  }();
  return controller.stream;
}

Stream<int> createLongStream(int eventCount) async* {
  for (var i = 0; i < eventCount; i++) {
    yield i;
  }
}
