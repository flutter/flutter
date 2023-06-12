import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream<int>.fromIterable(const <int>[1, 2, 3, 4]);

void main() {
  test('Rx.delay', () async {
    var value = 1;
    _getStream()
        .delay(const Duration(milliseconds: 200))
        .listen(expectAsync1((result) {
          expect(result, value++);
        }, count: 4));
  });

  test('Rx.delay.shouldBeDelayed', () async {
    var value = 1;
    _getStream()
        .delay(const Duration(milliseconds: 500))
        .timeInterval()
        .listen(expectAsync1((result) {
          expect(result.value, value++);

          if (result.value == 1) {
            expect(result.interval.inMilliseconds,
                greaterThanOrEqualTo(500)); // should be delayed
          } else {
            expect(result.interval.inMilliseconds,
                lessThanOrEqualTo(20)); // should be near instantaneous
          }
        }, count: 4));
  });

  test('Rx.delay.reusable', () async {
    final transformer =
        DelayStreamTransformer<int>(const Duration(milliseconds: 200));
    var valueA = 1, valueB = 1;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(result, valueA++);
        }, count: 4));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(result, valueB++);
        }, count: 4));
  });

  test('Rx.delay.asBroadcastStream', () async {
    final stream = _getStream()
        .asBroadcastStream()
        .delay(const Duration(milliseconds: 200));

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.delay.error.shouldThrowA', () async {
    final streamWithError = Stream<void>.error(Exception())
        .delay(const Duration(milliseconds: 200));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  /// Should also throw if the current [Zone] is unable to install a [Timer]
  test('Rx.delay.error.shouldThrowB', () async {
    runZoned(() {
      final streamWithError =
          Stream.value(1).delay(const Duration(milliseconds: 200));

      streamWithError.listen(null,
          onError: expectAsync2(
              (Exception e, StackTrace s) => expect(e, isException)));
    },
        zoneSpecification: ZoneSpecification(
            createTimer: (self, parent, zone, duration, void Function() f) =>
                throw Exception('Zone createTimer error')));
  });

  test('Rx.delay.pause.resume', () async {
    StreamSubscription<int> subscription;
    final stream =
        Stream.fromIterable(const [1, 2, 3]).delay(Duration(milliseconds: 1));

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test(
    'Rx.delay.cancel.emits.nothing',
    () async {
      StreamSubscription<int> subscription;
      final stream = Stream.fromIterable(const [1, 2, 3]).doOnDone(() {
        subscription.cancel();
      }).delay(Duration(seconds: 10));

      // We expect the onData callback to be called 0 times because the
      // subscription is cancelled when the base stream ends.
      subscription = stream.listen(expectAsync1((_) {}, count: 0));
    },
    timeout: Timeout(Duration(seconds: 3)),
  );

  test('Rx.delay accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.delay(Duration(seconds: 10));

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
