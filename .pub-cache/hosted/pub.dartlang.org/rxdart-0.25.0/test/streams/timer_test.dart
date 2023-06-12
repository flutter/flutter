import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('TimerStream', () async {
    const value = 1;

    final stream = TimerStream(value, Duration(milliseconds: 1));

    await expectLater(stream, emitsInOrder(<dynamic>[value, emitsDone]));
  });

  test('TimerStream.single.subscription', () async {
    final stream = TimerStream(1, Duration(milliseconds: 1));

    stream.listen(null);
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('TimerStream.pause.resume.A', () async {
    const value = 1;
    StreamSubscription<int> subscription;

    final stream = TimerStream(value, Duration(milliseconds: 1));

    subscription = stream.listen(expectAsync1((actual) {
      expect(actual, value);

      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('TimerStream.pause.resume.B', () async {
    const seconds = 2;
    const delay = 1;

    var stream = Rx.timer(99, const Duration(seconds: seconds));
    var stopwatch = Stopwatch()..start();
    var subscription = stream.listen(expectAsync1((_) {
      stopwatch.stop();
      expect(stopwatch.elapsed.inSeconds, seconds + delay);
    }));

    await Future<void>.delayed(const Duration(milliseconds: 100));
    subscription.pause();
    subscription.pause();

    await Future<void>.delayed(const Duration(seconds: delay));

    subscription.resume();
    subscription.resume();
    subscription.resume();
  });

  test('TimerStream.pause.resume.C', () async {
    const value = 1;
    StreamSubscription<int> subscription;

    final stream = TimerStream(value, const Duration(seconds: 1));

    var firstElapses = Duration.zero;
    final watch = Stopwatch()..start();

    subscription = stream.listen(expectAsync1((actual) {
      expect(actual, value);

      final duration = (watch..stop()).elapsed + firstElapses;
      expect(duration.inSeconds, 1);
    }));

    await Future<void>.delayed(const Duration(milliseconds: 200));

    firstElapses = firstElapses + (watch..stop()).elapsed;
    watch
      ..reset()
      ..start();

    subscription.pause(
      Future<void>.delayed(const Duration(milliseconds: 200)).whenComplete(() {
        watch
          ..reset()
          ..start();
      }),
    );

    firstElapses = firstElapses + (watch..stop()).elapsed;
    watch
      ..reset()
      ..start();
    subscription.pause();

    await Future<void>.delayed(const Duration(milliseconds: 200));

    subscription.resume();
    watch
      ..reset()
      ..start();
  });

  test('TimerStream.single.subscription', () async {
    final stream = TimerStream(null, Duration(milliseconds: 1));

    try {
      stream.listen(null);
      stream.listen(null);
    } catch (e) {
      await expectLater(e, isStateError);
    }
  });

  test('TimerStream.cancel', () async {
    const value = 1;
    StreamSubscription<int> subscription;

    final stream = TimerStream(value, Duration(milliseconds: 1));

    subscription = stream.listen(
        expectAsync1((_) {
          expect(true, isFalse);
        }, count: 0),
        onError: expectAsync2((Exception e, StackTrace s) {
          expect(true, isFalse);
        }, count: 0),
        onDone: expectAsync0(() {
          expect(true, isFalse);
        }, count: 0));

    await subscription.cancel();
  });

  test('Rx.timer', () async {
    const value = 1;

    final stream = Rx.timer(value, Duration(milliseconds: 5));

    stream.listen(expectAsync1((actual) {
      expect(actual, value);
    }), onDone: expectAsync0(() {
      expect(true, isTrue);
    }));
  });
}
