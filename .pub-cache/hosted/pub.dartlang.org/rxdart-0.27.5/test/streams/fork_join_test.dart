import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> get streamA =>
    Stream<int>.periodic(const Duration(milliseconds: 1), (int count) => count)
        .take(3);

Stream<int> get streamB => Stream<int>.fromIterable(const <int>[1, 2, 3, 4]);

Stream<bool> get streamC {
  final controller = StreamController<bool>()
    ..add(true)
    ..close();

  return controller.stream;
}

void main() {
  test('Rx.forkJoinList', () async {
    final combined = Rx.forkJoinList<int>([
      Stream.fromIterable([1, 2, 3]),
      Stream.value(2),
      Stream.value(3),
    ]);

    await expectLater(
      combined,
      emitsInOrder(<dynamic>[
        [3, 2, 3],
        emitsDone
      ]),
    );
  });

  test('Rx.forkJoin.nullable', () {
    expect(
      ForkJoinStream.combine2(
        Stream.value(null),
        Stream.value(1),
        (a, b) => '$a $b',
      ),
      emitsInOrder(<Object>[
        'null 1',
        emitsDone,
      ]),
    );
  });

  test('Rx.forkJoin.iterate.once', () async {
    var iterationCount = 0;

    final stream = Rx.forkJoinList<int>(() sync* {
      ++iterationCount;
      yield Stream.value(1);
      yield Stream.value(2);
      yield Stream.value(3);
    }());

    await expectLater(
      stream,
      emitsInOrder(<dynamic>[
        [1, 2, 3],
        emitsDone,
      ]),
    );
    expect(iterationCount, 1);
  });

  test('Rx.forkJoin.empty', () {
    expect(Rx.forkJoinList<int>([]), emitsDone);
  });

  test('Rx.forkJoinList.singleStream', () async {
    final combined = Rx.forkJoinList<int>([
      Stream.fromIterable([1, 2, 3])
    ]);

    await expectLater(
      combined,
      emitsInOrder(<dynamic>[
        [3],
        emitsDone
      ]),
    );
  });

  test('Rx.forkJoin', () async {
    final combined = Rx.forkJoin<int, int>(
      [
        Stream.fromIterable([1, 2, 3]),
        Stream.value(2),
        Stream.value(3),
      ],
      (values) => values.fold(0, (acc, val) => acc + val),
    );

    await expectLater(
      combined,
      emitsInOrder(<dynamic>[8, emitsDone]),
    );
  });

  test('Rx.forkJoin3', () async {
    final stream = Rx.forkJoin3(streamA, streamB, streamC,
        (int aValue, int bValue, bool cValue) => '$aValue $bValue $cValue');

    await expectLater(stream, emitsInOrder(<dynamic>['2 4 true', emitsDone]));
  });

  test('Rx.forkJoin3.single.subscription', () async {
    final stream = Rx.forkJoin3(streamA, streamB, streamC,
        (int aValue, int bValue, bool cValue) => '$aValue $bValue $cValue');

    await expectLater(
      stream,
      emitsInOrder(<dynamic>['2 4 true', emitsDone]),
    );
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('Rx.forkJoin2', () async {
    var a = Stream.fromIterable(const [1, 2]), b = Stream.value(2);

    final stream =
        Rx.forkJoin2(a, b, (int first, int second) => [first, second]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          [2, 2],
          emitsDone
        ]));
  });

  test('Rx.forkJoin2.throws', () async {
    var a = Stream.value(1), b = Stream.value(2);

    final stream = Rx.forkJoin2(a, b, (int first, int second) {
      throw Exception();
    });

    stream.listen(null, onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.forkJoin3', () async {
    var a = Stream<int>.value(1),
        b = Stream<String>.value('2'),
        c = Stream<double>.value(3.0);

    final stream = Rx.forkJoin3(a, b, c,
        (int first, String second, double third) => [first, second, third]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, '2', 3.0],
          emitsDone
        ]));
  });

  test('Rx.forkJoin4', () async {
    var a = Stream.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4);

    final stream = Rx.forkJoin4(
        a,
        b,
        c,
        d,
        (int first, int second, int third, int fourth) =>
            [first, second, third, fourth]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2, 3, 4],
          emitsDone
        ]));
  });

  test('Rx.forkJoin5', () async {
    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5);

    final stream = Rx.forkJoin5(
        a,
        b,
        c,
        d,
        e,
        (int first, int second, int third, int fourth, int fifth) =>
            <int>[first, second, third, fourth, fifth]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2, 3, 4, 5],
          emitsDone
        ]));
  });

  test('Rx.forkJoin6', () async {
    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6);

    final stream = Rx.combineLatest6(
        a,
        b,
        c,
        d,
        e,
        f,
        (int first, int second, int third, int fourth, int fifth, int sixth) =>
            [first, second, third, fourth, fifth, sixth]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2, 3, 4, 5, 6],
          emitsDone
        ]));
  });

  test('Rx.forkJoin7', () async {
    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6),
        g = Stream<int>.value(7);

    final stream = Rx.forkJoin7(
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        (int first, int second, int third, int fourth, int fifth, int sixth,
                int seventh) =>
            [first, second, third, fourth, fifth, sixth, seventh]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2, 3, 4, 5, 6, 7],
          emitsDone
        ]));
  });

  test('Rx.forkJoin8', () async {
    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6),
        g = Stream<int>.value(7),
        h = Stream<int>.value(8);

    final stream = Rx.forkJoin8(
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
        (int first, int second, int third, int fourth, int fifth, int sixth,
                int seventh, int eighth) =>
            [first, second, third, fourth, fifth, sixth, seventh, eighth]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2, 3, 4, 5, 6, 7, 8],
          emitsDone
        ]));
  });

  test('Rx.forkJoin9', () async {
    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6),
        g = Stream<int>.value(7),
        h = Stream<int>.value(8),
        i = Stream<int>.value(9);

    final stream = Rx.forkJoin9(
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
        i,
        (int first, int second, int third, int fourth, int fifth, int sixth,
                int seventh, int eighth, int ninth) =>
            [
              first,
              second,
              third,
              fourth,
              fifth,
              sixth,
              seventh,
              eighth,
              ninth
            ]);

    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2, 3, 4, 5, 6, 7, 8, 9],
          emitsDone
        ]));
  });

  test('Rx.forkJoin.asBroadcastStream', () async {
    final stream = Rx.forkJoin3(streamA, streamB, streamC,
            (int aValue, int bValue, bool cValue) => '$aValue $bValue $cValue')
        .asBroadcastStream();

// listen twice on same stream
    stream.listen(null);
    stream.listen(null);
// code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.forkJoin.error.shouldThrowA', () async {
    final streamWithError = Rx.forkJoin4(
        Stream.value(1),
        Stream.value(1),
        Stream.value(1),
        Stream<int>.error(Exception()),
        (int aValue, int bValue, int cValue, dynamic _) =>
            '$aValue $bValue $cValue $_');

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }), cancelOnError: true);
  });

  test('Rx.forkJoin.error.shouldThrowB', () async {
    final streamWithError =
        Rx.forkJoin3(Stream.value(1), Stream.value(1), Stream.value(1),
            (int aValue, int bValue, int cValue) {
      throw Exception('oh noes!');
    });

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.forkJoin.pause.resume', () async {
    final first = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [1, 2, 3, 4][index]).take(4),
        second = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [5, 6, 7, 8][index]).take(4),
        last = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [9, 10, 11, 12][index]).take(4);

    late StreamSubscription<Iterable<num>> subscription;
    subscription =
        Rx.forkJoin3(first, second, last, (int a, int b, int c) => [a, b, c])
            .listen(expectAsync1((value) {
      expect(value.elementAt(0), 4);
      expect(value.elementAt(1), 8);
      expect(value.elementAt(2), 12);

      subscription.cancel();
    }, count: 1));

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 80)));
  });

  test('Rx.forkJoin.completed', () async {
    final stream = Rx.forkJoin2(
      Stream<int>.empty(),
      Stream.value(1),
      (int a, int b) => a + b,
    );
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[emitsError(isStateError), emitsDone]),
    );
  });

  test('Rx.forkJoin.error.shouldThrowC', () async {
    final stream = Rx.forkJoin2(
      Stream.value(1),
      Stream<int>.error(Exception()).concatWith([
        Rx.timer(
          2,
          const Duration(milliseconds: 100),
        )
      ]),
      (int a, int b) => a + b,
    );
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[emitsError(isException), 3, emitsDone]),
    );
  });

  test('Rx.forkJoin.error.shouldThrowD', () async {
    final stream = Rx.forkJoin2(
      Stream.value(1),
      Stream<int>.error(Exception()).concatWith([
        Rx.timer(
          2,
          const Duration(milliseconds: 100),
        )
      ]),
      (int a, int b) => a + b,
    );

    stream.listen(
      expectAsync1((value) {}, count: 0),
      onError: expectAsync2(
        (Object e, StackTrace s) => expect(e, isException),
        count: 1,
      ),
      cancelOnError: true,
    );
  });
}
