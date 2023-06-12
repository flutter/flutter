import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.zip', () async {
    expect(
      Rx.zip<String, String>([
        Stream.fromIterable(['A1', 'B1']),
        Stream.fromIterable(['A2', 'B2', 'C2']),
      ], (values) => values.first + values.last),
      emitsInOrder(<dynamic>['A1A2', 'B1B2', emitsDone]),
    );
  });

  test('Rx.zip.empty', () {
    expect(Rx.zipList<int>([]), emitsDone);
  });

  test('Rx.zip.single', () {
    expect(
      Rx.zipList<int>([Stream.value(1)]),
      emitsInOrder(<Object>[
        [1],
        emitsDone
      ]),
    );
  });

  test('Rx.zip.iterate.once', () async {
    var iterationCount = 0;

    final stream = Rx.zipList<int>(() sync* {
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

  test('Rx.zipList', () async {
    expect(
      Rx.zipList([
        Stream.fromIterable(['A1', 'B1']),
        Stream.fromIterable(['A2', 'B2', 'C2']),
        Stream.fromIterable(['A3', 'B3', 'C3']),
      ]),
      emitsInOrder(<dynamic>[
        ['A1', 'A2', 'A3'],
        ['B1', 'B2', 'B3'],
        emitsDone
      ]),
    );
  });

  test('Rx.zipBasics', () async {
    const expectedOutput = [
      [0, 1, true],
      [1, 2, false],
      [2, 3, true],
      [3, 4, false]
    ];
    var count = 0;

    final testStream = StreamController<bool>()
      ..add(true)
      ..add(false)
      ..add(true)
      ..add(false)
      ..add(true)
      ..close(); // ignore: unawaited_futures

    final stream = Rx.zip3(
        Stream.periodic(const Duration(milliseconds: 1), (count) => count)
            .take(4),
        Stream.fromIterable(const [1, 2, 3, 4, 5, 6, 7, 8, 9]),
        testStream.stream,
        (int a, int b, bool c) => [a, b, c]);

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      for (var i = 0, len = result.length; i < len; i++) {
        expect(result[i], expectedOutput[count][i]);
      }

      count++;
    }, count: expectedOutput.length));
  });

  test('Rx.zipTwo', () async {
    const expected = [1, 2];

    // A purposely emits 2 items, b only 1
    final a = Stream.fromIterable(const [1, 2]), b = Stream.value(2);

    final stream = Rx.zip2(a, b, (int first, int second) => [first, second]);

    // Explicitly adding count: 1. It's important here, and tests the difference
    // between zip and combineLatest. If this was combineLatest, the count would
    // be two, and a second List<int> would be emitted.
    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }, count: 1));
  });

  test('Rx.zip3', () async {
    // Verify the ability to pass through various types with safety
    const expected = [1, '2', 3.0];

    final a = Stream.value(1), b = Stream.value('2'), c = Stream.value(3.0);

    final stream = Rx.zip3(a, b, c,
        (int first, String second, double third) => [first, second, third]);

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.zip4', () async {
    const expected = [1, 2, 3, 4];

    final a = Stream.value(1),
        b = Stream.value(2),
        c = Stream.value(3),
        d = Stream.value(4);

    final stream = Rx.zip4(
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

  test('Rx.zip5', () async {
    const expected = [1, 2, 3, 4, 5];

    final a = Stream.value(1),
        b = Stream.value(2),
        c = Stream.value(3),
        d = Stream.value(4),
        e = Stream.value(5);

    final stream = Rx.zip5(
        a,
        b,
        c,
        d,
        e,
        (int first, int second, int third, int fourth, int fifth) =>
            [first, second, third, fourth, fifth]);

    stream.listen(expectAsync1((result) {
      expect(result, expected);
    }));
  });

  test('Rx.zip6', () async {
    const expected = [1, 2, 3, 4, 5, 6];

    final a = Stream.value(1),
        b = Stream.value(2),
        c = Stream.value(3),
        d = Stream.value(4),
        e = Stream.value(5),
        f = Stream.value(6);

    final stream = Rx.zip6(
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

  test('Rx.zip7', () async {
    const expected = [1, 2, 3, 4, 5, 6, 7];

    final a = Stream.value(1),
        b = Stream.value(2),
        c = Stream.value(3),
        d = Stream.value(4),
        e = Stream.value(5),
        f = Stream.value(6),
        g = Stream.value(7);

    final stream = Rx.zip7(
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

  test('Rx.zip8', () async {
    const expected = [1, 2, 3, 4, 5, 6, 7, 8];

    final a = Stream.value(1),
        b = Stream.value(2),
        c = Stream.value(3),
        d = Stream.value(4),
        e = Stream.value(5),
        f = Stream.value(6),
        g = Stream.value(7),
        h = Stream.value(8);

    final stream = Rx.zip8(
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

  test('Rx.zip9', () async {
    const expected = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final a = Stream.value(1),
        b = Stream.value(2),
        c = Stream.value(3),
        d = Stream.value(4),
        e = Stream.value(5),
        f = Stream.value(6),
        g = Stream.value(7),
        h = Stream.value(8),
        i = Stream.value(9);

    final stream = Rx.zip9(
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

  test('Rx.zip.single.subscription', () async {
    final stream =
        Rx.zip2(Stream.value(1), Stream.value(1), (int a, int b) => a + b);

    stream.listen(null);
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('Rx.zip.asBroadcastStream', () async {
    final testStream = StreamController<bool>()
      ..add(true)
      ..add(false)
      ..add(true)
      ..add(false)
      ..add(true)
      ..close(); // ignore: unawaited_futures

    final stream = Rx.zip3(
        Stream.periodic(const Duration(milliseconds: 1), (count) => count)
            .take(4),
        Stream.fromIterable(const [1, 2, 3, 4, 5, 6, 7, 8, 9]),
        testStream.stream,
        (int a, int b, bool c) => [a, b, c]).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.zip.error.shouldThrowA', () async {
    final streamWithError = Rx.zip2(
      Stream.value(1),
      Stream.value(2),
      (int a, int b) => throw Exception(),
    );

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  /*test('Rx.zip.error.shouldThrowB', () {
    expect(
        () => Rx.zip2(
             Stream.value(1), null, (int a, _) => null),
        throwsArgumentError);
  });

  test('Rx.zip.error.shouldThrowC', () {
    expect(() => ZipStream<num>(null, () {}), throwsArgumentError);
  });

  test('Rx.zip.error.shouldThrowD', () {
    expect(() => ZipStream<num>(<Stream<dynamic>>[], () {}),
        throwsArgumentError);
  });*/

  test('Rx.zip.pause.resume.A', () async {
    late StreamSubscription<int> subscription;
    final stream =
        Rx.zip2(Stream.value(1), Stream.value(2), (int a, int b) => a + b);

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 3);

      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.zip.pause.resume.B', () async {
    final first = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [1, 2, 3, 4][index]),
        second = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [5, 6, 7, 8][index]),
        last = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [9, 10, 11, 12][index]);

    late StreamSubscription<Iterable<num>> subscription;
    subscription =
        Rx.zip3(first, second, last, (num a, num b, num c) => [a, b, c])
            .listen(expectAsync1((value) {
      expect(value.elementAt(0), 1);
      expect(value.elementAt(1), 5);
      expect(value.elementAt(2), 9);

      subscription.cancel();
    }, count: 1));

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 80)));
  });
}
