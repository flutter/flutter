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
  test('Rx.skipUntil', () async {
    const expectedOutput = [3, 4];
    var count = 0;

    _getStream().skipUntil(_getOtherStream()).listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.skipUntil.shouldClose', () async {
    _getStream()
        .skipUntil(Stream<void>.empty())
        .listen(null, onDone: expectAsync0(() => expect(true, isTrue)));
  });

  test('Rx.skipUntil.reusable', () async {
    final transformer = SkipUntilStreamTransformer<int, int>(
        _getOtherStream().asBroadcastStream());
    const expectedOutput = [3, 4];
    var countA = 0, countB = 0;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countA++], result);
        }, count: expectedOutput.length));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countB++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.skipUntil.asBroadcastStream', () async {
    final stream = _getStream()
        .asBroadcastStream()
        .skipUntil(_getOtherStream().asBroadcastStream());

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.skipUntil.error.shouldThrowA', () async {
    final streamWithError =
        Stream<int>.error(Exception()).skipUntil(_getOtherStream());

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.skipUntil.error.shouldThrowB', () async {
    final streamWithError =
        Stream.value(1).skipUntil(Stream<void>.error(Exception('Oh noes!')));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.skipUntil.error.shouldThrowC', () {
    expect(() => Stream.value(1).skipUntil<void>(null), throwsArgumentError);
  });

  test('Rx.skipUntil.pause.resume', () async {
    StreamSubscription<int> subscription;
    const expectedOutput = [3, 4];
    var count = 0;

    subscription =
        _getStream().skipUntil(_getOtherStream()).listen(expectAsync1((result) {
              expect(result, expectedOutput[count++]);

              if (count == expectedOutput.length) {
                subscription.cancel();
              }
            }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.skipUntil accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.skipUntil(Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
