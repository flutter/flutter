import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.scan', () async {
    const expectedOutput = [1, 3, 6, 10];
    var count = 0;

    Stream.fromIterable(const [1, 2, 3, 4])
        .scan((int acc, int value, int index) => (acc ?? 0) + value)
        .listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.scan.reusable', () async {
    final transformer = ScanStreamTransformer<int, int>(
        (int acc, int value, int index) => (acc ?? 0) + value);
    const expectedOutput = [1, 3, 6, 10];
    var countA = 0, countB = 0;

    Stream.fromIterable(const [1, 2, 3, 4])
        .transform(transformer)
        .listen(expectAsync1((result) {
          expect(expectedOutput[countA++], result);
        }, count: expectedOutput.length));

    Stream.fromIterable(const [1, 2, 3, 4])
        .transform(transformer)
        .listen(expectAsync1((result) {
          expect(expectedOutput[countB++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.scan.asBroadcastStream', () async {
    final stream = Stream.fromIterable(const [1, 2, 3, 4])
        .asBroadcastStream()
        .scan((int acc, int value, int index) => (acc ?? 0) + value, 0);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.scan.error.shouldThrow', () async {
    final streamWithError = Stream.fromIterable(const [1, 2, 3, 4])
        .scan((num acc, num value, int index) {
      throw StateError('oh noes!');
    });

    streamWithError.listen(null,
        onError: expectAsync2((StateError e, StackTrace s) {
          expect(e, isStateError);
        }, count: 4));
  });

  test('Rx.scan accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream
        .scan((int acc, int value, int index) => (acc ?? 0) + value);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
