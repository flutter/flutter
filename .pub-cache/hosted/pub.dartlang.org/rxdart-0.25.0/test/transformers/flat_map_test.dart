import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

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
    StreamSubscription<int> subscription;
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
}

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3]);

Stream<int> _getOtherStream(int value) {
  final controller = StreamController<int>();

  Timer(
      // Reverses the order of 1, 2, 3 to 3, 2, 1 by delaying 1, and 2 longer
      // than they delay 3
      Duration(milliseconds: value == 1 ? 15 : value == 2 ? 10 : 5), () {
    controller.add(value);
    controller.close();
  });

  return controller.stream;
}
