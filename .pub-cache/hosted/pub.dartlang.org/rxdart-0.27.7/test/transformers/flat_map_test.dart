import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('Rx.flatMap', () async {
    const expectedOutput = [3, 2, 1];
    var count = 0;

    _getStream().flatMap(_getOtherStream).listen(expectAsync1((result) {
          expect(result, expectedOutput[count++]);
        }, count: expectedOutput.length));
  });

  test('Rx.flatMap.reusable', () async {
    final transformer = FlatMapStreamTransformer<int, int>(_getOtherStream);
    const expectedOutput = [3, 2, 1];
    var countA = 0, countB = 0;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(result, expectedOutput[countA++]);
        }, count: expectedOutput.length));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(result, expectedOutput[countB++]);
        }, count: expectedOutput.length));
  });

  test('Rx.flatMap.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().flatMap(_getOtherStream);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.flatMap.error.shouldThrowA', () async {
    final streamWithError =
        Stream<int>.error(Exception()).flatMap(_getOtherStream);

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.flatMap.error.shouldThrowB', () async {
    final streamWithError = Stream.value(1)
        .flatMap((_) => Stream<void>.error(Exception('Catch me if you can!')));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.flatMap.error.shouldThrowC', () async {
    final streamWithError =
        Stream.value(1).flatMap<void>((_) => throw Exception('oh noes!'));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.flatMap.pause.resume', () async {
    late StreamSubscription<int> subscription;
    final stream = Stream.value(0).flatMap((_) => Stream.value(1));

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.flatMap.chains', () {
    expect(
      Stream.value(1)
          .flatMap((_) => Stream.value(2))
          .flatMap((_) => Stream.value(3)),
      emitsInOrder(<dynamic>[3, emitsDone]),
    );
  });

  test('Rx.flatMap accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.flatMap((_) => Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.flatMap(maxConcurrent: 1)', () {
    {
      // asyncExpand / concatMap
      final stream = Stream.fromIterable([1, 2, 3, 4]).flatMap(
        (value) => Rx.timer(
          value,
          Duration(milliseconds: (5 - value) * 100),
        ),
        maxConcurrent: 1,
      );
      expect(stream, emitsInOrder(<Object>[1, 2, 3, 4, emitsDone]));
    }

    {
      // emits error
      final stream = Stream.fromIterable([1, 2, 3, 4]).flatMap(
        (value) => value == 1
            ? throw Exception()
            : Rx.timer(
                value,
                Duration(milliseconds: (5 - value) * 100),
              ),
        maxConcurrent: 1,
      );
      expect(stream,
          emitsInOrder(<Object>[emitsError(isException), 2, 3, 4, emitsDone]));
    }

    {
      // emits error
      final stream = Stream.fromIterable([1, 2, 3, 4]).flatMap(
        (value) => value == 1
            ? Stream<int>.error(Exception())
            : Rx.timer(
                value,
                Duration(milliseconds: (5 - value) * 100),
              ),
        maxConcurrent: 1,
      );
      expect(stream,
          emitsInOrder(<Object>[emitsError(isException), 2, 3, 4, emitsDone]));
    }
  });

  test('Rx.flatMap(maxConcurrent: 2)', () async {
    const maxConcurrent = 2;
    var activeCount = 0;

    // 1 -> 500
    // 2 -> 400
    // 3 -> 500
    // 4 -> 200
    // -----1--4
    // ----2-----3
    // ----21--4-3
    final stream = Stream.fromIterable([1, 2, 3, 4]).flatMap(
      (value) {
        return Rx.defer(() {
          expect(++activeCount, lessThanOrEqualTo(maxConcurrent));

          final ms = (value.isOdd ? 5 : 6 - value) * 100;
          return Rx.timer(value, Duration(milliseconds: ms));
        }).doOnDone(() => --activeCount);
      },
      maxConcurrent: maxConcurrent,
    );

    await expectLater(stream, emitsInOrder(<Object>[2, 1, 4, 3, emitsDone]));
  });

  test('Rx.flatMap(maxConcurrent: 3)', () async {
    const maxConcurrent = 3;
    var activeCount = 0;

    // 1 -> 400
    // 2 -> 300
    // 3 -> 200
    // 4 -> 200
    // 5 -> 300
    // 6 -> 400
    // ----1----6
    // ---2---5
    // --3--4
    // --3214-5-6
    final stream = Stream.fromIterable([1, 2, 3, 4, 5, 6]).flatMap(
      (value) {
        return Rx.defer(() {
          expect(++activeCount, lessThanOrEqualTo(maxConcurrent));

          final ms = (value <= 3 ? 5 - value : value - 2) * 100;
          return Rx.timer(value, Duration(milliseconds: ms));
        }).doOnDone(() => --activeCount);
      },
      maxConcurrent: maxConcurrent,
    );

    await expectLater(
        stream, emitsInOrder(<Object>[3, 2, 1, 4, 5, 6, emitsDone]));
  });

  test('Rx.flatMap.cancel', () {
    _getStream()
        .flatMap(_getOtherStream)
        .listen(expectAsync1((data) {}, count: 0))
        .cancel();
  }, timeout: const Timeout(Duration(milliseconds: 200)));

  test('Rx.flatMap(maxConcurrent: 1).cancel', () {
    _getStream()
        .flatMap(_getOtherStream, maxConcurrent: 1)
        .listen(expectAsync1((data) {}, count: 0))
        .cancel();
  }, timeout: const Timeout(Duration(milliseconds: 200)));

  test('Rx.flatMap.take.cancel', () {
    _getStream()
        .flatMap(_getOtherStream)
        .take(1)
        .listen(expectAsync1((data) => expect(data, 3), count: 1));
  }, timeout: const Timeout(Duration(milliseconds: 200)));

  test('Rx.flatMap(maxConcurrent: 1).take.cancel', () {
    _getStream()
        .flatMap(_getOtherStream, maxConcurrent: 1)
        .take(1)
        .listen(expectAsync1((data) => expect(data, 1), count: 1));
  }, timeout: const Timeout(Duration(milliseconds: 200)));

  test('Rx.flatMap(maxConcurrent: 2).take.cancel', () {
    _getStream()
        .flatMap(_getOtherStream, maxConcurrent: 2)
        .take(1)
        .listen(expectAsync1((data) => expect(data, 2), count: 1));
  }, timeout: const Timeout(Duration(milliseconds: 200)));

  test('Rx.flatMap.nullable', () {
    nullableTest<String?>(
      (s) => s.flatMap((v) => Stream.value(v)),
    );
  });
}

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3]);

Stream<int> _getOtherStream(int value) {
  final controller = StreamController<int>();

  Timer(
      // Reverses the order of 1, 2, 3 to 3, 2, 1 by delaying 1, and 2 longer
      // than they delay 3
      Duration(
          milliseconds: value == 1
              ? 15
              : value == 2
                  ? 10
                  : 5), () {
    controller.add(value);
    controller.close();
  });

  return controller.stream;
}
