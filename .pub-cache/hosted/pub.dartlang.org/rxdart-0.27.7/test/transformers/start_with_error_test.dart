import 'dart:async';

import 'package:rxdart/src/transformers/start_with_error.dart';
import 'package:test/test.dart';

Stream<int> _getStream() => Stream.fromIterable(const [1, 2, 3, 4]);

void main() {
  test('Rx.startWithError', () async {
    final transformer = StartWithErrorStreamTransformer<int>(
        Exception(), StackTrace.fromString('oh noes!'));
    const expectedOutput = [1, 2, 3, 4];

    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[emitsError(isException), ...expectedOutput]));
  });

  test('Rx.startWithError.reusable', () async {
    final transformer = StartWithErrorStreamTransformer<int>(
        Exception(), StackTrace.fromString('oh noes!'));
    const expectedOutput = [1, 2, 3, 4];

    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[emitsError(isException), ...expectedOutput]));
    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[emitsError(isException), ...expectedOutput]));
  });

  test('Rx.startWithError.asBroadcastStream', () async {
    final transformer = StartWithErrorStreamTransformer<int>(
        Exception(), StackTrace.fromString('oh noes!'));
    final stream = _getStream().asBroadcastStream().transform(transformer);
    const expectedOutput = [1, 2, 3, 4];

    // listen twice on same stream
    await expectLater(
        stream,
        emitsInOrder(
            <dynamic>[emitsError(isException), ...expectedOutput, emitsDone]));
    await expectLater(stream, emitsDone);
  });

  test('Rx.startWithError.error.shouldThrow', () async {
    final transformer = StartWithErrorStreamTransformer<int>(
        Exception(), StackTrace.fromString('oh noes!'));
    final streamWithError =
        Stream<int>.error(Exception()).transform(transformer);

    await expectLater(streamWithError, emitsError(isException));
  });

  test('Rx.startWithError.pause.resume', () async {
    final transformer = StartWithErrorStreamTransformer<int>(
        Exception(), StackTrace.fromString('oh noes!'));
    const expectedOutput = [1, 2, 3, 4];
    var count = 0;

    late StreamSubscription<int> subscription;
    subscription = _getStream().transform(transformer).listen(
        expectAsync1((result) {
          expect(expectedOutput[count++], result);

          if (count == expectedOutput.length) {
            subscription.cancel();
          }
        }, count: expectedOutput.length),
        onError: (Object e, StackTrace s) => expect(e, isException));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.startWithError accidental broadcast', () async {
    final transformer = StartWithErrorStreamTransformer<int>(
        Exception(), StackTrace.fromString('oh noes!'));
    final controller = StreamController<int>();

    final stream = controller.stream.transform(transformer);

    stream.listen(null, onError: (Object e, StackTrace s) {});
    expect(() => stream.listen(null, onError: (Object e, StackTrace s) {}),
        throwsStateError);

    controller.add(1);
  });
}
