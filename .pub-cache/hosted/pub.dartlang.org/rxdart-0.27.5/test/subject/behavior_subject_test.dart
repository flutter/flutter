import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  final throwsValueStreamError = throwsA(isA<ValueStreamError>());

  group('BehaviorSubject', () {
    test('emits the most recently emitted item to every subscriber', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);

      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));

      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
    });

    test('emits the most recently emitted null item to every subscriber',
        () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int?>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int?>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(null);

      seeded.add(1);
      seeded.add(2);
      seeded.add(null);

      await expectLater(unseeded.stream, emits(isNull));
      await expectLater(unseeded.stream, emits(isNull));
      await expectLater(unseeded.stream, emits(isNull));

      await expectLater(seeded.stream, emits(isNull));
      await expectLater(seeded.stream, emits(isNull));
      await expectLater(seeded.stream, emits(isNull));
    });

    test(
        'emits the most recently emitted item to every subscriber that subscribe to the subject directly',
        () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);

      await expectLater(unseeded, emits(3));
      await expectLater(unseeded, emits(3));
      await expectLater(unseeded, emits(3));

      await expectLater(seeded, emits(3));
      await expectLater(seeded, emits(3));
      await expectLater(seeded, emits(3));
    });

    test('emits errors to every subscriber', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);
      unseeded.addError(Exception('oh noes!'));

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);
      seeded.addError(Exception('oh noes!'));

      await expectLater(unseeded.stream, emitsError(isException));
      await expectLater(unseeded.stream, emitsError(isException));
      await expectLater(unseeded.stream, emitsError(isException));

      await expectLater(seeded.stream, emitsError(isException));
      await expectLater(seeded.stream, emitsError(isException));
      await expectLater(seeded.stream, emitsError(isException));
    });

    test('emits event after error to every subscriber', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.addError(Exception('oh noes!'));
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.addError(Exception('oh noes!'));
      seeded.add(3);

      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));

      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
    });

    test('emits errors to every subscriber', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int?>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int?>.seeded(0);
      final exception = Exception('oh noes!');

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);
      unseeded.addError(exception);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);
      seeded.addError(exception);

      expect(unseeded.value, 3);
      expect(unseeded.valueOrNull, 3);
      expect(unseeded.hasValue, true);

      expect(unseeded.error, exception);
      expect(unseeded.errorOrNull, exception);
      expect(unseeded.hasError, true);

      await expectLater(unseeded, emitsError(exception));
      await expectLater(unseeded, emitsError(exception));
      await expectLater(unseeded, emitsError(exception));

      expect(seeded.value, 3);
      expect(seeded.valueOrNull, 3);
      expect(seeded.hasValue, true);

      expect(seeded.error, exception);
      expect(seeded.errorOrNull, exception);
      expect(seeded.hasError, true);

      await expectLater(seeded, emitsError(exception));
      await expectLater(seeded, emitsError(exception));
      await expectLater(seeded, emitsError(exception));
    });

    test('can synchronously get the latest value', () {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);

      expect(unseeded.value, 3);
      expect(unseeded.valueOrNull, 3);
      expect(unseeded.hasValue, true);

      expect(seeded.value, 3);
      expect(seeded.valueOrNull, 3);
      expect(seeded.hasValue, true);
    });

    test('can synchronously get the latest null value', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int?>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int?>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(null);

      seeded.add(1);
      seeded.add(2);
      seeded.add(null);

      expect(unseeded.value, isNull);
      expect(unseeded.valueOrNull, isNull);
      expect(unseeded.hasValue, true);

      expect(seeded.value, isNull);
      expect(seeded.valueOrNull, isNull);
      expect(seeded.hasValue, true);
    });

    test('emits the seed item if no new items have been emitted', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>.seeded(1);

      await expectLater(subject.stream, emits(1));
      await expectLater(subject.stream, emits(1));
      await expectLater(subject.stream, emits(1));
    });

    test('emits the null seed item if no new items have been emitted',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int?>.seeded(null);

      await expectLater(subject.stream, emits(isNull));
      await expectLater(subject.stream, emits(isNull));
      await expectLater(subject.stream, emits(isNull));
    });

    test('can synchronously get the initial value', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>.seeded(1);

      expect(subject.value, 1);
      expect(subject.valueOrNull, 1);
      expect(subject.hasValue, true);
    });

    test('can synchronously get the initial null value', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int?>.seeded(null);

      expect(subject.value, null);
      expect(subject.valueOrNull, null);
      expect(subject.hasValue, true);
    });

    test('initial value is null when no value has been emitted', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      expect(() => subject.value, throwsValueStreamError);
      expect(subject.valueOrNull, null);
      expect(subject.hasValue, false);
    });

    test('emits done event to listeners when the subject is closed', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      await expectLater(unseeded.isClosed, isFalse);
      await expectLater(seeded.isClosed, isFalse);

      unseeded.add(1);
      scheduleMicrotask(() => unseeded.close());

      seeded.add(1);
      scheduleMicrotask(() => seeded.close());

      await expectLater(unseeded.stream, emitsInOrder(<dynamic>[1, emitsDone]));
      await expectLater(unseeded.isClosed, isTrue);

      await expectLater(seeded.stream, emitsInOrder(<dynamic>[1, emitsDone]));
      await expectLater(seeded.isClosed, isTrue);
    });

    test('emits error events to subscribers', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      scheduleMicrotask(() => unseeded.addError(Exception()));
      scheduleMicrotask(() => seeded.addError(Exception()));

      await expectLater(unseeded.stream, emitsError(isException));
      await expectLater(seeded.stream, emitsError(isException));
    });

    test('replays the previously emitted items from addStream', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      await unseeded.addStream(Stream.fromIterable(const [1, 2, 3]));
      await seeded.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));

      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
    });

    test('replays the previously emitted errors from addStream', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      await unseeded.addStream(Stream<int>.error('error'),
          cancelOnError: false);
      await seeded.addStream(Stream<int>.error('error'), cancelOnError: false);

      await expectLater(unseeded.stream, emitsError('error'));
      await expectLater(unseeded.stream, emitsError('error'));
    });

    test('allows items to be added once addStream is complete', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      await subject.addStream(Stream.fromIterable(const [1, 2]));
      subject.add(3);

      await expectLater(subject.stream, emits(3));
    });

    test('allows items to be added once addStream completes with an error',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      unawaited(subject
          .addStream(Stream<int>.error(Exception()), cancelOnError: true)
          .whenComplete(() => subject.add(1)));

      await expectLater(subject.stream,
          emitsInOrder(<StreamMatcher>[emitsError(isException), emits(1)]));
    });

    test('does not allow events to be added when addStream is active',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.add(1), throwsStateError);
    });

    test('does not allow errors to be added when addStream is active',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.addError(Error()), throwsStateError);
    });

    test('does not allow subject to be closed when addStream is active',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.close(), throwsStateError);
    });

    test(
        'does not allow addStream to add items when previous addStream is active',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      // Purposely don't wait for the future to complete, then try to add items
      // ignore: unawaited_futures
      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.addStream(Stream.fromIterable(const [1])),
          throwsStateError);
    });

    test('returns onListen callback set in constructor', () async {
      void testOnListen() {}
      // ignore: close_sinks
      final subject = BehaviorSubject<void>(onListen: testOnListen);

      await expectLater(subject.onListen, testOnListen);
    });

    test('sets onListen callback', () async {
      void testOnListen() {}
      // ignore: close_sinks
      final subject = BehaviorSubject<void>();

      await expectLater(subject.onListen, isNull);

      subject.onListen = testOnListen;

      await expectLater(subject.onListen, testOnListen);
    });

    test('returns onCancel callback set in constructor', () async {
      Future<void> onCancel() => Future<void>.value(null);
      // ignore: close_sinks
      final subject = BehaviorSubject<void>(onCancel: onCancel);

      await expectLater(subject.onCancel, onCancel);
    });

    test('sets onCancel callback', () async {
      void testOnCancel() {}
      // ignore: close_sinks
      final subject = BehaviorSubject<void>();

      await expectLater(subject.onCancel, isNull);

      subject.onCancel = testOnCancel;

      await expectLater(subject.onCancel, testOnCancel);
    });

    test('reports if a listener is present', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      await expectLater(subject.hasListener, isFalse);

      subject.stream.listen(null);

      await expectLater(subject.hasListener, isTrue);
    });

    test('onPause unsupported', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      expect(subject.isPaused, isFalse);
      expect(() => subject.onPause, throwsUnsupportedError);
      expect(() => subject.onPause = () {}, throwsUnsupportedError);
    });

    test('onResume unsupported', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      expect(() => subject.onResume, throwsUnsupportedError);
      expect(() => subject.onResume = () {}, throwsUnsupportedError);
    });

    test('returns controller sink', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      await expectLater(subject.sink, TypeMatcher<EventSink<int>>());
    });

    test('correctly closes done Future', () async {
      final subject = BehaviorSubject<void>();

      scheduleMicrotask(() => subject.close());

      await expectLater(subject.done, completes);
    });

    test('can be listened to multiple times', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject.seeded(1);
      final stream = subject.stream;

      await expectLater(stream, emits(1));
      await expectLater(stream, emits(1));
    });

    test('always returns the same stream', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      await expectLater(subject.stream, equals(subject.stream));
    });

    test('adding to sink has same behavior as adding to Subject itself',
        () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      subject.sink.add(1);

      expect(subject.value, 1);

      subject.sink.add(2);
      subject.sink.add(3);

      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
    });

    test('setter `value=` has same behavior as adding to Subject', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      subject.value = 1;

      expect(subject.value, 1);

      subject.value = 2;
      subject.value = 3;

      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
    });

    test('is always treated as a broadcast Stream', () async {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();
      final stream = subject.asyncMap((event) => Future.value(event));

      expect(subject.isBroadcast, isTrue);
      expect(stream.isBroadcast, isTrue);
    });

    test('hasValue returns false for an empty subject', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      expect(subject.hasValue, isFalse);
    });

    test('hasValue returns true for a seeded subject with non-null seed', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>.seeded(1);

      expect(subject.hasValue, isTrue);
    });

    test('hasValue returns true for a seeded subject with null seed', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int?>.seeded(null);

      expect(subject.hasValue, isTrue);
    });

    test('hasValue returns true for an unseeded subject after an emission', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      subject.add(1);

      expect(subject.hasValue, isTrue);
    });

    test('hasError returns false for an empty subject', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      expect(subject.hasError, isFalse);
    });

    test('hasError returns false for a seeded subject with non-null seed', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>.seeded(1);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns false for a seeded subject with null seed', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int?>.seeded(null);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns false for an unseeded subject after an emission',
        () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      subject.add(1);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns true for an unseeded subject after addError', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      subject.add(1);
      subject.addError('error');

      expect(subject.hasError, isTrue);
    });

    test('hasError returns true for a seeded subject after addError', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>.seeded(1);

      subject.addError('error');

      expect(subject.hasError, isTrue);
    });

    test('error returns null for an empty subject', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>();

      expect(subject.hasError, isFalse);
      expect(subject.errorOrNull, isNull);
      expect(() => subject.error, throwsValueStreamError);
    });

    test('error returns null for a seeded subject with non-null seed', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int>.seeded(1);

      expect(subject.hasError, isFalse);
      expect(subject.errorOrNull, isNull);
      expect(() => subject.error, throwsValueStreamError);
    });

    test('error returns null for a seeded subject with null seed', () {
      // ignore: close_sinks
      final subject = BehaviorSubject<int?>.seeded(null);

      expect(subject.hasError, isFalse);
      expect(subject.errorOrNull, isNull);
      expect(() => subject.error, throwsValueStreamError);
    });

    test('can synchronously get the latest error', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);
      expect(unseeded.hasError, isFalse);
      expect(unseeded.errorOrNull, isNull);
      expect(() => unseeded.error, throwsValueStreamError);

      unseeded.addError(Exception('oh noes!'));
      expect(unseeded.hasError, isTrue);
      expect(unseeded.errorOrNull, isException);
      expect(unseeded.error, isException);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);
      expect(seeded.hasError, isFalse);
      expect(seeded.errorOrNull, isNull);
      expect(() => seeded.error, throwsValueStreamError);

      seeded.addError(Exception('oh noes!'));
      expect(seeded.hasError, isTrue);
      expect(seeded.errorOrNull, isException);
      expect(seeded.error, isException);
    });

    test('emits event after error to every subscriber', () async {
      // ignore: close_sinks
      final unseeded = BehaviorSubject<int>(),
          // ignore: close_sinks
          seeded = BehaviorSubject<int>.seeded(0);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.addError(Exception('oh noes!'));
      expect(unseeded.hasError, isTrue);
      expect(unseeded.errorOrNull, isException);
      expect(unseeded.error, isException);
      unseeded.add(3);
      expect(unseeded.hasError, isTrue);
      expect(unseeded.errorOrNull, isException);
      expect(unseeded.error, isException);

      seeded.add(1);
      seeded.add(2);
      seeded.addError(Exception('oh noes!'));
      expect(seeded.hasError, isTrue);
      expect(seeded.errorOrNull, isException);
      expect(seeded.error, isException);
      seeded.add(3);
      expect(seeded.hasError, isTrue);
      expect(seeded.errorOrNull, isException);
      expect(seeded.error, isException);
    });

    test(
        'issue/350: emits duplicate values when listening multiple times and starting with an Error',
        () async {
      final subject = BehaviorSubject<dynamic>();

      subject.addError('error');

      await subject.close();

      await expectLater(subject,
          emitsInOrder(<StreamMatcher>[emitsError('error'), emitsDone]));
      await expectLater(subject,
          emitsInOrder(<StreamMatcher>[emitsError('error'), emitsDone]));
      await expectLater(subject,
          emitsInOrder(<StreamMatcher>[emitsError('error'), emitsDone]));
    });

    test('issue/419: sync behavior', () async {
      final subject = BehaviorSubject.seeded(1, sync: true);
      final mappedStream = subject.map((event) => event).shareValue();

      mappedStream.listen(null);

      expect(mappedStream.value, equals(1));

      await subject.close();
    }, skip: true);

    test('issue/419: sync throughput', () async {
      final subject = BehaviorSubject.seeded(1, sync: true);
      final mappedStream = subject.map((event) => event).shareValue();

      mappedStream.listen(null);

      subject.add(2);

      expect(mappedStream.value, equals(2));

      await subject.close();
    }, skip: true);

    test('issue/419: async behavior', () async {
      final subject = BehaviorSubject.seeded(1);
      final mappedStream = subject.map((event) => event).shareValue();

      mappedStream.listen(null,
          onDone: () => expect(mappedStream.value, equals(1)));

      expect(() => mappedStream.value, throwsValueStreamError);
      expect(mappedStream.valueOrNull, isNull);
      expect(mappedStream.hasValue, false);

      await subject.close();
    });

    test('issue/419: async throughput', () async {
      final subject = BehaviorSubject.seeded(1);
      final mappedStream = subject.map((event) => event).shareValue();

      mappedStream.listen(null,
          onDone: () => expect(mappedStream.value, equals(2)));

      subject.add(2);

      expect(() => mappedStream.value, throwsValueStreamError);
      expect(mappedStream.valueOrNull, isNull);
      expect(mappedStream.hasValue, false);

      await subject.close();
    });

    test('issue/477: get first after cancelled', () async {
      final a = BehaviorSubject.seeded('a');
      final bug = a.switchMap((v) => BehaviorSubject.seeded('b'));
      await bug.listen(null).cancel();
      expect(await bug.first, 'b');
    });

    test('issue/477: get first multiple times', () async {
      final a = BehaviorSubject.seeded('a');
      final bug = a.switchMap((_) => BehaviorSubject.seeded('b'));
      bug.listen(null);
      expect(await bug.first, 'b');
      expect(await bug.first, 'b');
    });

    test('issue/478: get first multiple times', () async {
      final a = BehaviorSubject.seeded('a');
      final b = BehaviorSubject.seeded('b');
      final bug =
          Rx.combineLatest2(a, b, (String _a, String _b) => 'ab').shareValue();
      expect(await bug.first, 'ab');
      expect(await bug.first, 'ab');
    });

    test('rxdart #477/#500 - a', () async {
      final a = BehaviorSubject.seeded('a')
          .switchMap((_) => BehaviorSubject.seeded('a'))
        ..listen(print);
      await pumpEventQueue();
      expect(await a.first, 'a');
    });

    test('rxdart #477/#500 - b', () async {
      final b = BehaviorSubject.seeded('b')
          .map((_) => 'b')
          .switchMap((_) => BehaviorSubject.seeded('b'))
        ..listen(print);
      await pumpEventQueue();
      expect(await b.first, 'b');
    });

    test('issue/587', () async {
      final source = BehaviorSubject.seeded('source');
      final switched =
          source.switchMap((value) => BehaviorSubject.seeded('switched'));
      var i = 0;
      switched.listen((_) => i++);
      expect(await switched.first, 'switched');
      expect(i, 1);
      expect(await switched.first, 'switched');
      expect(i, 1);
    });

    group('override built-in', () {
      test('where', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.where((event) => event.isOdd);
          expect(stream, emitsInOrder(<int>[1, 3]));

          behaviorSubject.add(2);
          behaviorSubject.add(3);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.where((event) => event.isOdd);
          expect(stream, emitsInOrder(<int>[1, 3]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(3);
        }
      });

      test('map', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var mapped = behaviorSubject.map((event) => event + 1);
          expect(mapped, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var mapped = behaviorSubject.map((event) => event + 1);
          expect(mapped, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
        }
      });

      test('asyncMap', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var mapped =
              behaviorSubject.asyncMap((event) => Future.value(event + 1));
          expect(mapped, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var mapped =
              behaviorSubject.asyncMap((event) => Future.value(event + 1));
          expect(mapped, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
        }
      });

      test('asyncExpand', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream =
              behaviorSubject.asyncExpand((event) => Stream.value(event + 1));
          expect(stream, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream =
              behaviorSubject.asyncExpand((event) => Stream.value(event + 1));
          expect(stream, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
        }
      });

      test('handleError', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.handleError(
            expectAsync1<void, dynamic>(
              (dynamic e) => expect(e, isException),
              count: 1,
            ),
          );

          expect(
            stream,
            emitsInOrder(<int>[1, 2]),
          );

          behaviorSubject.addError(Exception());
          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.handleError(
            expectAsync1<void, dynamic>(
              (dynamic e) => expect(e, isException),
              count: 1,
            ),
          );

          expect(
            stream,
            emitsInOrder(<int>[1, 2]),
          );

          behaviorSubject.add(1);
          behaviorSubject.addError(Exception());
          behaviorSubject.add(2);
        }
      });

      test('expand', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.expand((event) => [event + 1]);
          expect(stream, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.expand((event) => [event + 1]);
          expect(stream, emitsInOrder(<int>[2, 3]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
        }
      });

      test('transform', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.transform(
              IntervalStreamTransformer(const Duration(milliseconds: 100)));
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.transform(
              IntervalStreamTransformer(const Duration(milliseconds: 100)));
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
        }
      });

      test('cast', () {
        {
          var behaviorSubject = BehaviorSubject<Object>.seeded(1);

          var stream = behaviorSubject.cast<int>();
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<Object>();

          var stream = behaviorSubject.cast<int>();
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
        }
      });

      test('take', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.take(2);
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(2);
          behaviorSubject.add(3);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.take(2);
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(3);
        }
      });

      test('takeWhile', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.takeWhile((element) => element <= 2);
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(2);
          behaviorSubject.add(3);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.takeWhile((element) => element <= 2);
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(3);
        }
      });

      test('skip', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.skip(2);
          expect(stream, emitsInOrder(<int>[3, 4]));

          behaviorSubject.add(2);
          behaviorSubject.add(3);
          behaviorSubject.add(4);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.skip(2);
          expect(stream, emitsInOrder(<int>[3, 4]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(3);
          behaviorSubject.add(4);
        }
      });

      test('skipWhile', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.skipWhile((element) => element < 3);
          expect(stream, emitsInOrder(<int>[3, 4]));

          behaviorSubject.add(2);
          behaviorSubject.add(3);
          behaviorSubject.add(4);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.skipWhile((element) => element < 3);
          expect(stream, emitsInOrder(<int>[3, 4]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(3);
          behaviorSubject.add(4);
        }
      });

      test('distinct', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject.distinct();
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(2);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject.distinct();
          expect(stream, emitsInOrder(<int>[1, 2]));

          behaviorSubject.add(1);
          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(2);
        }
      });

      test('timeout', () {
        {
          var behaviorSubject = BehaviorSubject.seeded(1);

          var stream = behaviorSubject
              .interval(const Duration(milliseconds: 100))
              .timeout(
                const Duration(milliseconds: 70),
                onTimeout: expectAsync1(
                  (EventSink<int> sink) {},
                  count: 4,
                ),
              );

          expect(stream, emitsInOrder(<int>[1, 2, 3, 4]));

          behaviorSubject.add(2);
          behaviorSubject.add(3);
          behaviorSubject.add(4);
        }

        {
          var behaviorSubject = BehaviorSubject<int>();

          var stream = behaviorSubject
              .interval(const Duration(milliseconds: 100))
              .timeout(
                const Duration(milliseconds: 70),
                onTimeout: expectAsync1(
                  (EventSink<int> sink) {},
                  count: 4,
                ),
              );

          expect(stream, emitsInOrder(<int>[1, 2, 3, 4]));

          behaviorSubject.add(1);
          behaviorSubject.add(2);
          behaviorSubject.add(3);
          behaviorSubject.add(4);
        }
      });
    });
  });
}
