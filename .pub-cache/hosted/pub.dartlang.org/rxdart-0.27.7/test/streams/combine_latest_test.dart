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
  test('Rx.combineLatestList', () async {
    final combined = Rx.combineLatestList<int>([
      Stream.fromIterable([1, 2, 3]),
      Stream.value(2),
      Stream.value(3),
    ]);

    expect(
      combined,
      emitsInOrder(<dynamic>[
        [1, 2, 3],
        [2, 2, 3],
        [3, 2, 3],
      ]),
    );
  });

  test('Rx.combineLatestList.iterate.once', () async {
    var iterationCount = 0;

    final combined = Rx.combineLatestList<int>(() sync* {
      ++iterationCount;
      yield Stream.value(1);
      yield Stream.value(2);
      yield Stream.value(3);
    }());

    await expectLater(
      combined,
      emitsInOrder(<dynamic>[
        [1, 2, 3],
        emitsDone,
      ]),
    );
    expect(iterationCount, 1);
  });

  test('Rx.combineLatestList.empty', () async {
    final combined = Rx.combineLatestList<int>([]);
    expect(combined, emitsDone);
  });

  test('Rx.combineLatest', () async {
    final combined = Rx.combineLatest<int, int>(
      [
        Stream.fromIterable([1, 2, 3]),
        Stream.value(2),
        Stream.value(3),
      ],
      (values) => values.fold(0, (acc, val) => acc + val),
    );

    expect(
      combined,
      emitsInOrder(<dynamic>[6, 7, 8]),
    );
  });

  test('Rx.combineLatest3', () async {
    const expectedOutput = ['0 4 true', '1 4 true', '2 4 true'];
    var count = 0;

    final stream = Rx.combineLatest3(streamA, streamB, streamC,
        (int aValue, int bValue, bool cValue) {
      return '$aValue $bValue $cValue';
    });

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result.compareTo(expectedOutput[count++]), 0);
    }, count: 3));
  });

  test('Rx.combineLatest3.single.subscription', () async {
    final stream = Rx.combineLatest3(streamA, streamB, streamC,
        (int aValue, int bValue, bool cValue) {
      return '$aValue $bValue $cValue';
    });

    stream.listen(null);
    await expectLater(() => stream.listen((_) {}), throwsA(isStateError));
  });

  test('Rx.combineLatest2', () async {
    const expected = [
      [1, 2],
      [2, 2]
    ];
    var count = 0;

    var a = Stream.fromIterable(const [1, 2]), b = Stream.value(2);

    final stream =
        Rx.combineLatest2(a, b, (int first, int second) => [first, second]);

    stream.listen(expectAsync1((result) {
      expect(result, expected[count++]);
    }, count: expected.length));
  });

  test('Rx.combineLatest2.throws', () async {
    var a = Stream.value(1), b = Stream.value(2);

    final stream = Rx.combineLatest2(a, b, (int first, int second) {
      throw Exception();
    });

    stream.listen(null, onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.combineLatest3', () async {
    const expected = [1, '2', 3.0];

    var a = Stream<int>.value(1),
        b = Stream<String>.value('2'),
        c = Stream<double>.value(3.0);

    final stream = Rx.combineLatest3(a, b, c,
        (int first, String second, double third) => [first, second, third]);

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest4', () async {
    const expected = [1, 2, 3, 4];

    var a = Stream.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4);

    final stream = Rx.combineLatest4(
        a,
        b,
        c,
        d,
        (int first, int second, int third, int fourth) =>
            [first, second, third, fourth]);

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest5', () async {
    const expected = [1, 2, 3, 4, 5];

    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5);

    final stream = Rx.combineLatest5(
        a,
        b,
        c,
        d,
        e,
        (int first, int second, int third, int fourth, int fifth) =>
            <int>[first, second, third, fourth, fifth]);

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest6', () async {
    const expected = [1, 2, 3, 4, 5, 6];

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

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest7', () async {
    const expected = [1, 2, 3, 4, 5, 6, 7];

    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6),
        g = Stream<int>.value(7);

    final stream = Rx.combineLatest7(
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

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest8', () async {
    const expected = [1, 2, 3, 4, 5, 6, 7, 8];

    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6),
        g = Stream<int>.value(7),
        h = Stream<int>.value(8);

    final stream = Rx.combineLatest8(
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

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest9', () async {
    const expected = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    var a = Stream<int>.value(1),
        b = Stream<int>.value(2),
        c = Stream<int>.value(3),
        d = Stream<int>.value(4),
        e = Stream<int>.value(5),
        f = Stream<int>.value(6),
        g = Stream<int>.value(7),
        h = Stream<int>.value(8),
        i = Stream<int>.value(9);

    final stream = Rx.combineLatest9(
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

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.combineLatest.asBroadcastStream', () async {
    final stream = Rx.combineLatest3(streamA, streamB, streamC,
        (int aValue, int bValue, bool cValue) {
      return '$aValue $bValue $cValue';
    }).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.combineLatest.error.shouldThrowA', () async {
    final streamWithError = Rx.combineLatest4(Stream.value(1), Stream.value(1),
        Stream.value(1), Stream<int>.error(Exception()),
        (int aValue, int bValue, int cValue, dynamic _) {
      return '$aValue $bValue $cValue $_';
    });

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.combineLatest.error.shouldThrowB', () async {
    final streamWithError =
        Rx.combineLatest3(Stream.value(1), Stream.value(1), Stream.value(1),
            (int aValue, int bValue, int cValue) {
      throw Exception('oh noes!');
    });

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  /*test('Rx.combineLatest.error.shouldThrowC', () {
    expect(
        () => Rx.combineLatest3(Stream<num>.value(1),
            Stream<num>.just(1), Stream<num>.value(1), null),
        throwsArgumentError);
  });

  test('Rx.combineLatest.error.shouldThrowD', () {
    expect(() => CombineLatestStream<num>(null, null), throwsArgumentError);
  });

  test('Rx.combineLatest.error.shouldThrowE', () {
    expect(() => CombineLatestStream<num>(<Stream<num>>[], null),
        throwsArgumentError);
  });*/

  test('Rx.combineLatest.pause.resume', () async {
    final first = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [1, 2, 3, 4][index]),
        second = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [5, 6, 7, 8][index]),
        last = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [9, 10, 11, 12][index]);

    late StreamSubscription<Iterable<num>> subscription;
    // ignore: deprecated_member_use
    subscription = Rx.combineLatest3(
            first, second, last, (int a, int b, int c) => [a, b, c])
        .listen(expectAsync1((value) {
      expect(value.elementAt(0), 1);
      expect(value.elementAt(1), 5);
      expect(value.elementAt(2), 9);

      subscription.cancel();
    }, count: 1));

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 80)));
  });
}
