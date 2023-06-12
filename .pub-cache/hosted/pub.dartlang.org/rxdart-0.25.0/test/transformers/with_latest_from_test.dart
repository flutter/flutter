import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/rx.dart';
import 'package:test/test.dart';

/// creates 5 Streams, deferred from a source Stream, so that they all emit
/// under the same Timer interval.
/// before, tests could fail, since we created 5 separate Streams with each
/// using their own Timer.
List<Stream<int>> _createTestStreams() {
  /// creates streams that emit after a certain amount of milliseconds,
  /// the List of intervals (in ms)
  const intervals = [22, 50, 30, 40, 60];
  final ticker =
      Stream<int>.periodic(const Duration(milliseconds: 1), (index) => index)
          .skip(1)
          .take(300)
          .asBroadcastStream();

  return [
    ticker
        .where((index) => index % intervals[0] == 0)
        .map((index) => index ~/ intervals[0] - 1),
    ticker
        .where((index) => index % intervals[1] == 0)
        .map((index) => index ~/ intervals[1] - 1),
    ticker
        .where((index) => index % intervals[2] == 0)
        .map((index) => index ~/ intervals[2] - 1),
    ticker
        .where((index) => index % intervals[3] == 0)
        .map((index) => index ~/ intervals[3] - 1),
    ticker
        .where((index) => index % intervals[4] == 0)
        .map((index) => index ~/ intervals[4] - 1)
  ];
}

void main() {
  test('Rx.withLatestFrom', () async {
    const expectedOutput = [
      Pair(2, 0),
      Pair(3, 0),
      Pair(4, 1),
      Pair(5, 1),
      Pair(6, 2)
    ];
    final streams = _createTestStreams();

    await expectLater(
        streams.first
            .withLatestFrom(
                streams[1], (first, int second) => Pair(first, second))
            .take(5),
        emitsInOrder(expectedOutput));
  });

  test('Rx.withLatestFrom.reusable', () async {
    final streams = _createTestStreams();
    final transformer = WithLatestFromStreamTransformer.with1<int, int, Pair>(
        streams[1], (first, second) => Pair(first, second));
    const expectedOutput = [
      Pair(2, 0),
      Pair(3, 0),
      Pair(4, 1),
      Pair(5, 1),
      Pair(6, 2)
    ];
    var countA = 0, countB = 0;

    streams.first.transform(transformer).take(5).listen(expectAsync1((result) {
          expect(result, expectedOutput[countA++]);
        }, count: expectedOutput.length));

    streams.first.transform(transformer).take(5).listen(expectAsync1((result) {
          expect(result, expectedOutput[countB++]);
        }, count: expectedOutput.length));
  });

  test('Rx.withLatestFrom.asBroadcastStream', () async {
    final streams = _createTestStreams();
    final stream =
        streams.first.withLatestFrom(streams[1], (first, int second) => 0);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    await expectLater(true, true);
  });

  test('Rx.withLatestFrom.error.shouldThrowA', () async {
    final streams = _createTestStreams();
    final streamWithError = Stream<int>.error(Exception())
        .withLatestFrom(streams[1], (first, int second) => 'Hello');

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.withLatestFrom.error.shouldThrowB', () {
    expect(
        () => Stream.value(1)
            .withLatestFrom(null, (first, int second) => 'Hello'),
        throwsArgumentError);
  });

  test('Rx.withLatestFrom.error.shouldThrowC', () {
    final streams = _createTestStreams();
    expect(() => streams.first.withLatestFrom<int, void>(streams[1], null),
        throwsArgumentError);
  });

  test('Rx.withLatestFrom.pause.resume', () async {
    StreamSubscription<Pair> subscription;
    const expectedOutput = [Pair(2, 0)];
    final streams = _createTestStreams();
    var count = 0;

    subscription = streams.first
        .withLatestFrom(streams[1], (first, int second) => Pair(first, second))
        .take(1)
        .listen(expectAsync1((result) {
          expect(result, expectedOutput[count++]);

          if (count == expectedOutput.length) {
            subscription.cancel();
          }
        }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.withLatestFrom.otherEmitsNull', () async {
    const expected = Pair(1, null);
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom(
      Stream<int>.value(null),
      (a, int b) => Pair(a, b),
    );

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFrom.otherNotEmit', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom(
      Stream<int>.empty(),
      (a, int b) => Pair(a, b),
    );

    await expectLater(
      stream,
      emitsDone,
    );
  });

  test('Rx.withLatestFrom2', () async {
    const expectedOutput = [
      _Tuple(2, 0, 1),
      _Tuple(3, 0, 1),
      _Tuple(4, 1, 2),
      _Tuple(5, 1, 3),
      _Tuple(6, 2, 4),
    ];
    final streams = _createTestStreams();
    var count = 0;

    streams.first
        .withLatestFrom2(
          streams[1],
          streams[2],
          (item1, int item2, int item3) => _Tuple(item1, item2, item3),
        )
        .take(5)
        .listen(
          expectAsync1(
            (result) => expect(result, expectedOutput[count++]),
            count: expectedOutput.length,
          ),
        );
  });

  test('Rx.withLatestFrom3', () async {
    const expectedOutput = [
      _Tuple(2, 0, 1, 0),
      _Tuple(3, 0, 1, 1),
      _Tuple(4, 1, 2, 1),
      _Tuple(5, 1, 3, 2),
      _Tuple(6, 2, 4, 2),
    ];
    final streams = _createTestStreams();
    var count = 0;

    streams.first
        .withLatestFrom3(
          streams[1],
          streams[2],
          streams[3],
          (item1, int item2, int item3, int item4) =>
              _Tuple(item1, item2, item3, item4),
        )
        .take(5)
        .listen(
          expectAsync1(
            (result) => expect(result, expectedOutput[count++]),
            count: expectedOutput.length,
          ),
        );
  });

  test('Rx.withLatestFrom4', () async {
    const expectedOutput = [
      _Tuple(2, 0, 1, 0, 0),
      _Tuple(3, 0, 1, 1, 0),
      _Tuple(4, 1, 2, 1, 0),
      _Tuple(5, 1, 3, 2, 1),
      _Tuple(6, 2, 4, 2, 1),
    ];
    final streams = _createTestStreams();
    var count = 0;

    streams.first
        .withLatestFrom4(
          streams[1],
          streams[2],
          streams[3],
          streams[4],
          (item1, int item2, int item3, int item4, int item5) =>
              _Tuple(item1, item2, item3, item4, item5),
        )
        .take(5)
        .listen(
          expectAsync1(
            (result) => expect(result, expectedOutput[count++]),
            count: expectedOutput.length,
          ),
        );
  });

  test('Rx.withLatestFrom5', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom5(
      Stream.value(2),
      Stream.value(3),
      Stream.value(4),
      Stream.value(5),
      Stream.value(6),
      (a, int b, int c, int d, int e, int f) => _Tuple(a, b, c, d, e, f),
    );
    const expected = _Tuple(1, 2, 3, 4, 5, 6);

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFrom6', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom6(
      Stream.value(2),
      Stream.value(3),
      Stream.value(4),
      Stream.value(5),
      Stream.value(6),
      Stream.value(7),
      (a, int b, int c, int d, int e, int f, int g) =>
          _Tuple(a, b, c, d, e, f, g),
    );
    const expected = _Tuple(1, 2, 3, 4, 5, 6, 7);

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFrom7', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom7(
      Stream.value(2),
      Stream.value(3),
      Stream.value(4),
      Stream.value(5),
      Stream.value(6),
      Stream.value(7),
      Stream.value(8),
      (a, int b, int c, int d, int e, int f, int g, int h) =>
          _Tuple(a, b, c, d, e, f, g, h),
    );
    const expected = _Tuple(1, 2, 3, 4, 5, 6, 7, 8);

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFrom8', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom8(
      Stream.value(2),
      Stream.value(3),
      Stream.value(4),
      Stream.value(5),
      Stream.value(6),
      Stream.value(7),
      Stream.value(8),
      Stream.value(9),
      (a, int b, int c, int d, int e, int f, int g, int h, int i) =>
          _Tuple(a, b, c, d, e, f, g, h, i),
    );
    const expected = _Tuple(1, 2, 3, 4, 5, 6, 7, 8, 9);

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFrom9', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFrom9(
      Stream.value(2),
      Stream.value(3),
      Stream.value(4),
      Stream.value(5),
      Stream.value(6),
      Stream.value(7),
      Stream.value(8),
      Stream.value(9),
      Stream.value(10),
      (a, int b, int c, int d, int e, int f, int g, int h, int i, int j) =>
          _Tuple(a, b, c, d, e, f, g, h, i, j),
    );
    const expected = _Tuple(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFromList', () async {
    final stream = Rx.timer(
      1,
      const Duration(microseconds: 100),
    ).withLatestFromList(
      [
        Stream.value(2),
        Stream.value(3),
        Stream.value(4),
        Stream.value(5),
        Stream.value(6),
        Stream.value(7),
        Stream.value(8),
        Stream.value(9),
        Stream.value(10),
      ],
    );
    const expected = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    await expectLater(
      stream,
      emits(expected),
    );
  });

  test('Rx.withLatestFromList.emptyList', () async {
    final stream = Stream.fromIterable([1, 2, 3]).withLatestFromList([]);

    await expectLater(
      stream,
      emitsInOrder(
        <List<int>>[
          [1],
          [2],
          [3],
        ],
      ),
    );
  });
  test('Rx.withLatestFrom accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream
        .withLatestFrom(Stream<int>.empty(), (_, dynamic __) => true);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}

class Pair {
  final int first;
  final int second;

  const Pair(this.first, this.second);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Pair && first == other.first && second == other.second;
  }

  @override
  int get hashCode {
    return first.hashCode ^ second.hashCode;
  }

  @override
  String toString() {
    return 'Pair{first: $first, second: $second}';
  }
}

class _Tuple {
  final int item1;
  final int item2;
  final int item3;
  final int item4;
  final int item5;
  final int item6;
  final int item7;
  final int item8;
  final int item9;
  final int item10;

  const _Tuple([
    this.item1,
    this.item2,
    this.item3,
    this.item4,
    this.item5,
    this.item6,
    this.item7,
    this.item8,
    this.item9,
    this.item10,
  ]);

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        other is _Tuple &&
            item1 == other.item1 &&
            item2 == other.item2 &&
            item3 == other.item3 &&
            item4 == other.item4 &&
            item5 == other.item5 &&
            item6 == other.item6 &&
            item7 == other.item7 &&
            item8 == other.item8 &&
            item9 == other.item9 &&
            item10 == other.item10;
  }

  @override
  int get hashCode {
    return item1.hashCode ^
        item2.hashCode ^
        item3.hashCode ^
        item4.hashCode ^
        item5.hashCode ^
        item6.hashCode ^
        item7.hashCode ^
        item8.hashCode ^
        item9.hashCode ^
        item10.hashCode;
  }

  @override
  String toString() {
    final values = [
      item1,
      item2,
      item3,
      item4,
      item5,
      item6,
      item7,
      item8,
      item9,
      item10,
    ];
    final s = values.join(', ');
    return 'Tuple { $s }';
  }
}
