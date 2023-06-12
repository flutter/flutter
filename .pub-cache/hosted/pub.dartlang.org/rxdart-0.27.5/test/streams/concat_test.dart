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
  test('Rx.concat', () async {
    const expectedOutput = [0, 1, 2, 3, 4, 5];
    var count = 0;

    final stream = Rx.concat(_getStreams());

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result, expectedOutput[count++]);
    }, count: expectedOutput.length));
  });

  test('Rx.concatEager.single.subscription', () async {
    final stream = Rx.concat(_getStreams());

    stream.listen(null);
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('Rx.concat.withEmptyStream', () async {
    const expectedOutput = [0, 1, 2, 3, 4, 5];
    var count = 0;

    final stream = Rx.concat(_getStreamsIncludingEmpty());

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result, expectedOutput[count++]);
    }, count: expectedOutput.length));
  });

  test('Rx.concat.withBroadcastStreams', () async {
    const expectedOutput = [1, 2, 3, 4];
    final ctrlA = StreamController<int>.broadcast(),
        ctrlB = StreamController<int>.broadcast(),
        ctrlC = StreamController<int>.broadcast();
    var x = 0, y = 100, z = 1000, count = 0;

    Timer.periodic(const Duration(milliseconds: 1), (_) {
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

    final stream = Rx.concat([ctrlA.stream, ctrlB.stream, ctrlC.stream]);

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(result, expectedOutput[count++]);
    }, count: expectedOutput.length));
  });

  test('Rx.concat.asBroadcastStream', () async {
    final stream = Rx.concat(_getStreams()).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.concat.error.shouldThrowA', () async {
    final streamWithError =
        Rx.concat(_getStreams()..add(Stream<int>.error(Exception())));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.concat.empty', () {
    expect(Rx.concat<int>(const []), emitsDone);
  });

  test('Rx.concat.single', () {
    expect(
      Rx.concat<int>([Stream.value(1)]),
      emitsInOrder(<Object>[1, emitsDone]),
    );
  });

  test('Rx.concat.iterate.once', () async {
    var iterationCount = 0;

    final stream = Rx.concat<int>(() sync* {
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
