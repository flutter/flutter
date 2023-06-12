import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:test/test.dart';

import '../utils.dart';

typedef AsyncVoidCallBack = Future<void> Function();

void main() {
  group('PublishSubject', () {
    test('emits items to every subscriber', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      scheduleMicrotask(() {
        subject.add(1);
        subject.add(2);
        subject.add(3);
        subject.close();
      });

      await expectLater(
          subject.stream, emitsInOrder(<dynamic>[1, 2, 3, emitsDone]));
    });

    test(
        'emits items to every subscriber that subscribe directly to the Subject',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      scheduleMicrotask(() {
        subject.add(1);
        subject.add(2);
        subject.add(3);
        subject.close();
      });

      await expectLater(subject, emitsInOrder(<dynamic>[1, 2, 3, emitsDone]));
    });

    test('emits done event to listeners when the subject is closed', () async {
      final subject = PublishSubject<int>();

      await expectLater(subject.isClosed, isFalse);

      scheduleMicrotask(() => subject.add(1));
      scheduleMicrotask(() => subject.close());

      await expectLater(subject.stream, emitsInOrder(<dynamic>[1, emitsDone]));
      await expectLater(subject.isClosed, isTrue);
    });

    test(
        'emits done event to listeners when the subject is closed (listen directly on Subject)',
        () async {
      final subject = PublishSubject<int>();

      await expectLater(subject.isClosed, isFalse);

      scheduleMicrotask(() => subject.add(1));
      scheduleMicrotask(() => subject.close());

      await expectLater(subject, emitsInOrder(<dynamic>[1, emitsDone]));
      await expectLater(subject.isClosed, isTrue);
    });

    test('emits error events to subscribers', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      scheduleMicrotask(() => subject.addError(Exception()));

      await expectLater(subject.stream, emitsError(isException));
    });

    test('emits error events to subscribers (listen directly on Subject)',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      scheduleMicrotask(() => subject.addError(Exception()));

      await expectLater(subject, emitsError(isException));
    });

    test('emits the items from addStream', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      scheduleMicrotask(
          () => subject.addStream(Stream.fromIterable(const [1, 2, 3])));

      await expectLater(subject.stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('allows items to be added once addStream is complete', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      await subject.addStream(Stream.fromIterable(const [1, 2]));
      scheduleMicrotask(() => subject.add(3));

      await expectLater(subject.stream, emits(3));
    });

    test('allows items to be added once addStream completes with an error',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      unawaited(subject
          .addStream(Stream<int>.error(Exception()), cancelOnError: true)
          .whenComplete(() => subject.add(1)));

      await expectLater(subject.stream,
          emitsInOrder(<StreamMatcher>[emitsError(isException), emits(1)]));
    });

    test('does not allow events to be added when addStream is active',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.add(1), throwsStateError);
    });

    test('does not allow errors to be added when addStream is active',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.addError(Error()), throwsStateError);
    });

    test('does not allow subject to be closed when addStream is active',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.close(), throwsStateError);
    });

    test(
        'does not allow addStream to add items when previous addStream is active',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.addStream(Stream.fromIterable(const [1])),
          throwsStateError);
    });

    test('returns onListen callback set in constructor', () async {
      void testOnListen() {}
      // ignore: close_sinks
      final subject = PublishSubject<int>(onListen: testOnListen);

      await expectLater(subject.onListen, testOnListen);
    });

    test('sets onListen callback', () async {
      void testOnListen() {}
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      await expectLater(subject.onListen, isNull);

      subject.onListen = testOnListen;

      await expectLater(subject.onListen, testOnListen);
    });

    test('returns onCancel callback set in constructor', () async {
      Future<void> onCancel() => Future<void>.value(null);
      // ignore: close_sinks
      final subject = PublishSubject<int>(onCancel: onCancel);

      await expectLater(subject.onCancel, onCancel);
    });

    test('sets onCancel callback', () async {
      void testOnCancel() {}
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      await expectLater(subject.onCancel, isNull);

      subject.onCancel = testOnCancel;

      await expectLater(subject.onCancel, testOnCancel);
    });

    test('reports if a listener is present', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      await expectLater(subject.hasListener, isFalse);

      subject.stream.listen(null);

      await expectLater(subject.hasListener, isTrue);
    });

    test('onPause unsupported', () {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      expect(subject.isPaused, isFalse);
      expect(() => subject.onPause, throwsUnsupportedError);
      expect(() => subject.onPause = () {}, throwsUnsupportedError);
    });

    test('onResume unsupported', () {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      expect(() => subject.onResume, throwsUnsupportedError);
      expect(() => subject.onResume = () {}, throwsUnsupportedError);
    });

    test('returns controller sink', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      await expectLater(subject.sink, TypeMatcher<EventSink<int>>());
    });

    test('correctly closes done Future', () async {
      final subject = PublishSubject<int>();

      scheduleMicrotask(() => subject.close());

      await expectLater(subject.done, completes);
    });

    test('can be listened to multiple times', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();
      final stream = subject.stream;

      scheduleMicrotask(() => subject.add(1));
      await expectLater(stream, emits(1));

      scheduleMicrotask(() => subject.add(2));
      await expectLater(stream, emits(2));
    });

    test('always returns the same stream', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      await expectLater(subject.stream, equals(subject.stream));
    });

    test('adding to sink has same behavior as adding to Subject itself',
        () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();

      scheduleMicrotask(() {
        subject.sink.add(1);
        subject.sink.add(2);
        subject.sink.add(3);
        subject.sink.close();
      });

      await expectLater(
          subject.stream, emitsInOrder(<dynamic>[1, 2, 3, emitsDone]));
    });

    test('is always treated as a broadcast Stream', () async {
      // ignore: close_sinks
      final subject = PublishSubject<int>();
      final stream = subject.asyncMap((event) => Future.value(event));

      expect(subject.isBroadcast, isTrue);
      expect(stream.isBroadcast, isTrue);
    });
  });
}
