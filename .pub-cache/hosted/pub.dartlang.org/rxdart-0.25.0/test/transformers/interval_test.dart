import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream.fromIterable(const [0, 1, 2, 3, 4]);

void main() {
  test('Rx.interval', () async {
    const expectedOutput = [0, 1, 2, 3, 4];
    var count = 0, lastInterval = -1;
    final stopwatch = Stopwatch()..start();

    _getStream().interval(const Duration(milliseconds: 1)).listen(
        expectAsync1((result) {
          expect(expectedOutput[count++], result);

          if (lastInterval != -1) {
            expect(stopwatch.elapsedMilliseconds - lastInterval >= 1, true);
          }

          lastInterval = stopwatch.elapsedMilliseconds;
        }, count: expectedOutput.length),
        onDone: stopwatch.stop);
  });

  test('Rx.interval.reusable', () async {
    final transformer =
        IntervalStreamTransformer<int>(const Duration(milliseconds: 1));
    const expectedOutput = [0, 1, 2, 3, 4];
    var countA = 0, countB = 0;
    final stopwatch = Stopwatch()..start();

    _getStream().transform(transformer).listen(
        expectAsync1((result) {
          expect(expectedOutput[countA++], result);
        }, count: expectedOutput.length),
        onDone: stopwatch.stop);

    _getStream().transform(transformer).listen(
        expectAsync1((result) {
          expect(expectedOutput[countB++], result);
        }, count: expectedOutput.length),
        onDone: stopwatch.stop);
  });

  test('Rx.interval.asBroadcastStream', () async {
    final stream = _getStream()
        .asBroadcastStream()
        .interval(const Duration(milliseconds: 20));

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.interval.error.shouldThrowA', () async {
    final streamWithError = Stream<void>.error(Exception())
        .interval(const Duration(milliseconds: 20));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.interval.error.shouldThrowB', () async {
    runZoned(() {
      final streamWithError =
          Stream.value(1).interval(const Duration(milliseconds: 20));

      streamWithError.listen(null,
          onError: expectAsync2(
              (Exception e, StackTrace s) => expect(e, isException)));
    },
        zoneSpecification: ZoneSpecification(
            createTimer: (self, parent, zone, duration, void Function() f) =>
                throw Exception('Zone createTimer error')));
  });

  test('Rx.interval accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.interval(const Duration(milliseconds: 10));

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
