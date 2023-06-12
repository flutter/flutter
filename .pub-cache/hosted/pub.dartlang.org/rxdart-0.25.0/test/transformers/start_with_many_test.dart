import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3, 4]);

void main() {
  test('Rx.startWithMany', () async {
    const expectedOutput = [5, 6, 1, 2, 3, 4];
    var count = 0;

    _getStream().startWithMany(const [5, 6]).listen(expectAsync1((result) {
      expect(expectedOutput[count++], result);
    }, count: expectedOutput.length));
  });

  test('Rx.startWithMany.reusable', () async {
    final transformer = StartWithManyStreamTransformer<int>(const [5, 6]);
    const expectedOutput = [5, 6, 1, 2, 3, 4];
    var countA = 0, countB = 0;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countA++], result);
        }, count: expectedOutput.length));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(expectedOutput[countB++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.startWithMany.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().startWithMany(const [5, 6]);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.startWithMany.error.shouldThrowA', () async {
    final streamWithError =
        Stream<int>.error(Exception()).startWithMany(const [5, 6]);

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.startWithMany.error.shouldThrowA', () {
    expect(() => Stream.value(1).startWithMany(null), throwsArgumentError);
  });

  test('Rx.startWithMany.pause.resume', () async {
    const expectedOutput = [5, 6, 1, 2, 3, 4];
    var count = 0;

    StreamSubscription<int> subscription;
    subscription =
        _getStream().startWithMany(const [5, 6]).listen(expectAsync1((result) {
      expect(expectedOutput[count++], result);

      if (count == expectedOutput.length) {
        subscription.cancel();
      }
    }, count: expectedOutput.length));

    subscription.pause();
    subscription.resume();
  });
  test('Rx.startWithMany accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.startWithMany(const [1, 2, 3]);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
