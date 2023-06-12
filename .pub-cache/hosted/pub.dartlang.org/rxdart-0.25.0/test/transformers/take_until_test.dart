import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() {
  final controller = StreamController<int>();

  Timer(const Duration(milliseconds: 100), () => controller.add(1));
  Timer(const Duration(milliseconds: 200), () => controller.add(2));
  Timer(const Duration(milliseconds: 300), () => controller.add(3));
  Timer(const Duration(milliseconds: 400), () {
    controller.add(4);
    controller.close();
  });

  return controller.stream;
}

Stream<int> _getOtherStream() {
  final controller = StreamController<int>();

  Timer(const Duration(milliseconds: 250), () {
    controller.add(1);
    controller.close();
  });

  return controller.stream;
}

void main() {
  test('Rx.takeUntil', () async {
    const expectedOutput = [1, 2];
    var count = 0;

    _getStream().takeUntil(_getOtherStream()).listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.takeUntil.shouldClose', () async {
    _getStream()
        .takeUntil(Stream<void>.empty())
        .listen(null, onDone: expectAsync0(() => expect(true, isTrue)));
  });

  test('Rx.takeUntil.reusable', () async {
    final transformer = TakeUntilStreamTransformer<int, int>(
        _getOtherStream().asBroadcastStream());
    const expectedOutput = [1, 2];
    var countA = 0, countB = 0;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countA++], result);
        }, count: expectedOutput.length));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countB++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.takeUntil.asBroadcastStream', () async {
    final stream = _getStream()
        .asBroadcastStream()
        .takeUntil(_getOtherStream().asBroadcastStream());

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.takeUntil.error.shouldThrowA', () async {
    final streamWithError =
        Stream<void>.error(Exception()).takeUntil(_getOtherStream());

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.takeUntil.error.shouldThrowB', () {
    expect(() => Stream.value(1).takeUntil<void>(null), throwsArgumentError);
  });

  test('Rx.takeUntil.pause.resume', () async {
    StreamSubscription<int> subscription;
    const expectedOutput = [1, 2];
    var count = 0;

    subscription =
        _getStream().takeUntil(_getOtherStream()).listen(expectAsync1((result) {
              expect(result, expectedOutput[count++]);

              if (count == expectedOutput.length) {
                subscription.cancel();
              }
            }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.takeUntil accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.takeUntil(Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
