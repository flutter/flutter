import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

List<Stream<int>> _getStreams() {
  var a = Stream.fromIterable(const [0, 1, 2]),
      b = Stream.fromIterable(const [3, 4, 5]);

  return [a, b];
}

List<Stream<int>> _getStreamsIncludingEmpty() {
  var a = Stream.fromIterable(const [0, 1, 2]),
      b = Stream.fromIterable(const [3, 4, 5]),
      c = Stream<int>.empty();

  return [c, a, b];
}

void main() {
  test('Rx.concatEager', () async {
    const expectedOutput = [0, 1, 2, 3, 4, 5];
    var count = 0;

    final stream = Rx.concatEager(_getStreams());

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result, expectedOutput[count++]);
    }, count: expectedOutput.length));
  });

  test('Rx.concatEager.single', () async {
    final stream = Rx.concatEager([
      Stream.fromIterable([1, 2, 3, 4, 5])
    ]);

    await expectLater(stream, emitsInOrder(<Object>[1, 2, 3, 4, 5, emitsDone]));
  });

  test('Rx.concatEager.eagerlySubscription', () async {
    var subscribed2 = false;
    var subscribed3 = false;

    final stream = Rx.concatEager<int>([
      Rx.timer(1, Duration(milliseconds: 100)).doOnDone(
          expectAsync0(() => expect(subscribed2 && subscribed3, true))),
      Rx.timer([2, 3, 4], Duration(milliseconds: 100))
          .exhaustMap((v) => Stream.fromIterable(v))
          .doOnListen(() => subscribed2 = true)
          .doOnDone(expectAsync0(() => expect(subscribed3, true))),
      Rx.timer(5, Duration(milliseconds: 100))
          .doOnListen(() => subscribed3 = true),
    ]);

    await expectLater(
      stream,
      emitsInOrder(<Object>[
        1,
        2,
        3,
        4,
        5,
        emitsDone,
      ]),
    );
  });

  test('Rx.concatEager.single.subscription', () async {
    final stream = Rx.concatEager(_getStreams());

    stream.listen(null);
    await expectLater(() => stream.listen((_) {}), throwsA(isStateError));
  });

  test('Rx.concatEager.withEmptyStream', () async {
    const expectedOutput = [0, 1, 2, 3, 4, 5];
    var count = 0;

    final stream = Rx.concatEager(_getStreamsIncludingEmpty());

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result, expectedOutput[count++]);
    }, count: expectedOutput.length));
  });

  test('Rx.concatEager.withBroadcastStreams', () async {
    const expectedOutput = [1, 2, 3, 4, 99, 98, 97, 96, 999, 998, 997];
    final ctrlA = StreamController<int>.broadcast(),
        ctrlB = StreamController<int>.broadcast(),
        ctrlC = StreamController<int>.broadcast();
    var x = 0, y = 100, z = 1000, count = 0;

    Timer.periodic(const Duration(milliseconds: 10), (_) {
      ctrlA.add(++x);
      ctrlB.add(--y);

      if (x <= 3) ctrlC.add(--z);

      if (x == 3) ctrlC.close();

      if (x == 4) {
        _.cancel();

        ctrlA.close();
        ctrlB.close();
      }
    });

    final stream = Rx.concatEager([ctrlA.stream, ctrlB.stream, ctrlC.stream]);

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result, expectedOutput[count++]);
    }, count: expectedOutput.length));
  });

  test('Rx.concatEager.asBroadcastStream', () async {
    final stream = Rx.concatEager(_getStreams()).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.concatEager.error.shouldThrowA', () async {
    final streamWithError =
        Rx.concatEager(_getStreams()..add(Stream<int>.error(Exception())));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.concatEager.pause.resume', () async {
    final first = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [1, 2, 3, 4][index]),
        second = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [5, 6, 7, 8][index]),
        last = Stream.periodic(const Duration(milliseconds: 10),
            (index) => const [9, 10, 11, 12][index]);

    late StreamSubscription<num> subscription;
    // ignore: deprecated_member_use
    subscription =
        Rx.concatEager([first, second, last]).listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 80)));
  });

  test('Rx.concatEager.empty', () {
    expect(Rx.concatEager<int>(const []), emitsDone);
  });

  test('Rx.concatEager.iterate.once', () async {
    var iterationCount = 0;

    final stream = Rx.concatEager<int>(() sync* {
      ++iterationCount;
      yield Stream.value(1);
      yield Stream.value(2);
      yield Stream.value(3);
    }());

    await expectLater(
      stream,
      emitsInOrder(<dynamic>[
        1,
        2,
        3,
        emitsDone,
      ]),
    );
    expect(iterationCount, 1);
  });
}
