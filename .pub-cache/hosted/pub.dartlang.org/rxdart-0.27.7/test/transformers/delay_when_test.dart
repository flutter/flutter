import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

Stream<int> _getStream() => Stream<int>.fromIterable(const <int>[1, 2, 3, 4]);

extension on Duration {
  Stream<void> asTimerStream() => Rx.timer(null, this);
}

void main() {
  test('Rx.delayWhen', () {
    expect(
      _getStream().delayWhen((_) => Stream.value(null)),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );

    expect(
      _getStream()
          .delayWhen((_) => const Duration(milliseconds: 200).asTimerStream()),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );

    expect(
      _getStream()
          .delayWhen((i) => Duration(milliseconds: 100 * i).asTimerStream()),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );

    expect(
      _getStream().delayWhen(
        (i) => Duration(milliseconds: 100 * i).asTimerStream(),
        listenDelay: Rx.timer(null, Duration(milliseconds: 100)),
      ),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );
  });

  test('Rx.delayWhen.zero', () {
    expect(
      _getStream().delayWhen((_) => Duration.zero.asTimerStream()),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );
  });

  test('Rx.delayWhen.shouldBeDelayed', () async {
    {
      var value = 1;
      await _getStream()
          .delayWhen((_) => const Duration(milliseconds: 500).asTimerStream())
          .timeInterval()
          .forEach(expectAsync1((result) {
            expect(result.value, value++);

            if (result.value == 1) {
              expect(
                result.interval.inMilliseconds,
                greaterThanOrEqualTo(500),
              ); // should be delayed
            } else {
              expect(
                result.interval.inMilliseconds,
                lessThanOrEqualTo(20),
              ); // should be near instantaneous
            }
          }, count: 4));
    }

    {
      var value = 1;
      await _getStream()
          .delayWhen((i) => Duration(milliseconds: 500 * i).asTimerStream())
          .timeInterval()
          .forEach(expectAsync1((result) {
            expect(result.value, value++);

            expect(
              (result.interval.inMilliseconds - 500).abs(),
              lessThanOrEqualTo(20),
            ); // should be near instantaneous
          }, count: 4));
    }
  });

  test('Rx.delayWhen.shouldBeDelayed.listenDelay', () {
    var value = 1;

    void onData(TimeInterval<int> result) {
      expect(result.value, value++);

      if (result.value == 1) {
        expect(
          result.interval.inMilliseconds,
          greaterThanOrEqualTo(500 + 300),
        ); // should be delayed
      } else {
        expect(
          (result.interval.inMilliseconds - 500).abs(),
          lessThanOrEqualTo(20),
        ); // should be near instantaneous
      }
    }

    _getStream()
        .delayWhen(
          (i) => Duration(milliseconds: 500 * i).asTimerStream(),
          listenDelay: Rx.timer(null, const Duration(milliseconds: 300)),
        )
        .timeInterval()
        .listen(expectAsync1(onData, count: 4));
  });

  test('Rx.delayWhen.reusable', () {
    final transformer = DelayWhenStreamTransformer<int>(
        (_) => const Duration(milliseconds: 200).asTimerStream());

    expect(
      _getStream().transform(transformer),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );

    expect(
      _getStream().transform(transformer),
      emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]),
    );
  });

  test('Rx.delayWhen.asBroadcastStream', () {
    {
      final stream = _getStream()
          .asBroadcastStream()
          .delayWhen((_) => const Duration(milliseconds: 200).asTimerStream());

      // listen twice on same stream
      stream.listen(null);
      stream.listen(null);

      // code should reach here
      expect(true, true);
    }

    {
      final stream = _getStream()
          .delayWhen((_) => const Duration(milliseconds: 200).asTimerStream())
          .asBroadcastStream();

      // listen twice on same stream
      stream.listen(null);
      stream.listen(null);

      // code should reach here
      expect(true, true);
    }

    {
      final stream = _getStream()
          .delayWhen(
            (_) => const Duration(milliseconds: 200).asTimerStream(),
            listenDelay: Stream.value(null),
          )
          .asBroadcastStream();

      // listen twice on same stream
      stream.listen(null);
      stream.listen(null);

      // code should reach here
      expect(true, true);
    }
  });

  test('Rx.delayWhen.error.shouldThrowA', () {
    expect(
      Stream<void>.error(Exception())
          .delayWhen((_) => const Duration(milliseconds: 200).asTimerStream()),
      emitsInOrder(<Object>[
        emitsError(isA<Exception>()),
        emitsDone,
      ]),
    );
  });

  test('Rx.delayWhen.error.shouldThrowB', () {
    expect(
      Stream.value(0).delayWhen(
        (_) => const Duration(milliseconds: 200).asTimerStream(),
        listenDelay: Stream.error(Exception('listenDelay')),
      ),
      emitsInOrder(<Object>[
        emitsError(isA<Exception>()),
        emitsDone,
      ]),
    );
  });

  test('Rx.delayWhen.pause.resume', () async {
    late StreamSubscription<int> subscription;
    final stream = Stream.fromIterable(const [1, 2, 3])
        .delayWhen((_) => Duration(milliseconds: 1).asTimerStream());

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.delayWhen.pause.resume.listenDelay', () {
    late StreamSubscription<int> subscription;
    final stream = Stream.fromIterable(const [1, 2, 3]).delayWhen(
      (_) => Duration(milliseconds: 1).asTimerStream(),
      listenDelay: Rx.timer(null, const Duration(milliseconds: 200)),
    );

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test(
    'Rx.delayWhen.cancel.emits.nothing',
    () {
      late StreamSubscription<int> subscription;
      final stream = _getStream()
          .doOnDone(() => subscription.cancel())
          .delayWhen((_) => Duration(seconds: 10).asTimerStream());

      // We expect the onData callback to be called 0 times because the
      // subscription is cancelled when the base stream ends.
      subscription = stream.listen(expectAsync1((_) {}, count: 0));
    },
    timeout: Timeout(Duration(seconds: 3)),
  );

  test(
    'Rx.delayWhen.cancel.emits.nothing.listenDelay',
    () {
      late StreamSubscription<int> subscription;
      final stream =
          _getStream().doOnDone(() => subscription.cancel()).delayWhen(
                (_) => Duration(seconds: 10).asTimerStream(),
                listenDelay: Stream.periodic(const Duration(seconds: 1)),
              );

      // We expect the onData callback to be called 0 times because the
      // subscription is cancelled when the base stream ends.
      subscription = stream.listen(expectAsync1((_) {}, count: 0));
    },
    timeout: Timeout(Duration(seconds: 3)),
  );

  test('Rx.delayWhen.singleSubscription', () async {
    final controller = StreamController<int>();

    final stream = controller.stream
        .delayWhen((_) => Duration(seconds: 10).asTimerStream());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.delayWhen.nullable', () {
    nullableTest<String?>(
      (s) => s.delayWhen((_) => Duration.zero.asTimerStream()),
    );
  });
}
