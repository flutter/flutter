import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3, 4]);

void main() {
  test('Rx.endWithMany', () async {
    const expectedOutput = [1, 2, 3, 4, 5, 6];

    await expectLater(
        _getStream().endWithMany(const [5, 6]), emitsInOrder(expectedOutput));
  });

  test('Rx.endWithMany.reusable', () async {
    final transformer = EndWithManyStreamTransformer<int>(const [5, 6]);
    const expectedOutput = [1, 2, 3, 4, 5, 6];

    await expectLater(
        _getStream().transform(transformer), emitsInOrder(expectedOutput));
    await expectLater(
        _getStream().transform(transformer), emitsInOrder(expectedOutput));
  });

  test('Rx.endWithMany.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().endWithMany(const [5, 6]);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.endWithMany.error.shouldThrowA', () async {
    final streamWithError =
        Stream<int>.error(Exception()).endWithMany(const [5, 6]);

    await expectLater(streamWithError, emitsError(isException));
  });

  test('Rx.endWithMany.error.shouldThrowA', () {
    expect(() => Stream.value(1).endWithMany(null), throwsArgumentError);
  });

  test('Rx.endWithMany.pause.resume', () async {
    const expectedOutput = [1, 2, 3, 4, 5, 6];
    var count = 0;

    StreamSubscription<int> subscription;
    subscription =
        _getStream().endWithMany(const [5, 6]).listen(expectAsync1((result) {
      expect(expectedOutput[count++], result);

      if (count == expectedOutput.length) {
        subscription.cancel();
      }
    }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });
  test('Rx.endWithMany accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.endWithMany(const [1, 2, 3]);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
