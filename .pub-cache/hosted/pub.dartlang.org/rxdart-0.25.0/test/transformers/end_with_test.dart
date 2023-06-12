import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3, 4]);

void main() {
  test('Rx.endWith', () async {
    const expectedOutput = [1, 2, 3, 4, 5];

    await expectLater(_getStream().endWith(5), emitsInOrder(expectedOutput));
  });

  test('Rx.endWith.reusable', () async {
    final transformer = EndWithStreamTransformer<int>(5);
    const expectedOutput = [1, 2, 3, 4, 5];

    await expectLater(
        _getStream().transform(transformer), emitsInOrder(expectedOutput));
    await expectLater(
        _getStream().transform(transformer), emitsInOrder(expectedOutput));
  });

  test('Rx.endWith.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().endWith(5);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.endWith.error.shouldThrow', () async {
    final streamWithError = Stream<int>.error(Exception()).endWith(5);

    await expectLater(streamWithError, emitsError(isException));
  });

  test('Rx.endWith.pause.resume', () async {
    const expectedOutput = [1, 2, 3, 4, 5];
    var count = 0;

    StreamSubscription<int> subscription;
    subscription = _getStream().endWith(5).listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);

          if (count == expectedOutput.length) {
            subscription.cancel();
          }
        }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.endWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.endWith(1);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
