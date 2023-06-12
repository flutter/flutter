import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3, 4]);

void main() {
  test('Rx.startWith', () async {
    const expectedOutput = [5, 1, 2, 3, 4];
    var count = 0;

    _getStream().startWith(5).listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.startWith.reusable', () async {
    final transformer = StartWithStreamTransformer<int>(5);
    const expectedOutput = [5, 1, 2, 3, 4];
    var countA = 0, countB = 0;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countA++], result);
        }, count: expectedOutput.length));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countB++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.startWith.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().startWith(5);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.startWith.error.shouldThrow', () async {
    final streamWithError = Stream<int>.error(Exception()).startWith(5);

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.startWith.pause.resume', () async {
    const expectedOutput = [5, 1, 2, 3, 4];
    var count = 0;

    StreamSubscription<int> subscription;
    subscription = _getStream().startWith(5).listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);

          if (count == expectedOutput.length) {
            subscription.cancel();
          }
        }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.startWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.startWith(1);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test(
      'Rx.startWith broadcast stream should not startWith on multiple subscribers',
      () async {
    final controller = StreamController<int>.broadcast();

    final stream = controller.stream.startWith(1);

    await controller.close();

    stream.listen(null);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    await expectLater(stream, emits(emitsDone));
  });
}
