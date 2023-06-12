import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream<int>.fromIterable(<int>[0, 1, 2]);

void main() {
  test('Rx.timeInterval', () async {
    const expectedOutput = [0, 1, 2];
    var count = 0;

    _getStream()
        .interval(const Duration(milliseconds: 1))
        .timeInterval()
        .listen(expectAsync1((result) {
          expect(expectedOutput[count++], result.value);

          expect(
              result.interval.inMicroseconds >= 1000 /* microseconds! */, true);
        }, count: expectedOutput.length));
  });

  test('Rx.timeInterval.reusable', () async {
    final transformer = TimeIntervalStreamTransformer<int>();
    const expectedOutput = [0, 1, 2];
    var countA = 0, countB = 0;

    _getStream()
        .interval(const Duration(milliseconds: 1))
        .transform(transformer)
        .listen(expectAsync1((result) {
          expect(expectedOutput[countA++], result.value);

          expect(
              result.interval.inMicroseconds >= 1000 /* microseconds! */, true);
        }, count: expectedOutput.length));

    _getStream()
        .interval(const Duration(milliseconds: 1))
        .transform(transformer)
        .listen(expectAsync1((result) {
          expect(expectedOutput[countB++], result.value);

          expect(
              result.interval.inMicroseconds >= 1000 /* microseconds! */, true);
        }, count: expectedOutput.length));
  });

  test('Rx.timeInterval.asBroadcastStream', () async {
    final stream = _getStream()
        .asBroadcastStream()
        .interval(const Duration(milliseconds: 1))
        .timeInterval();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.timeInterval.error.shouldThrow', () async {
    final streamWithError = Stream<void>.error(Exception())
        .interval(const Duration(milliseconds: 1))
        .timeInterval();

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.timeInterval.pause.resume', () async {
    StreamSubscription<TimeInterval<int>> subscription;
    const expectedOutput = [0, 1, 2];
    var count = 0;

    subscription = _getStream()
        .interval(const Duration(milliseconds: 1))
        .timeInterval()
        .listen(expectAsync1((result) {
          expect(result.value, expectedOutput[count++]);

          if (count == expectedOutput.length) {
            subscription.cancel();
          }
        }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.timeInterval accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.timeInterval();

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
