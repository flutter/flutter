import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('Rx.scan', () async {
    const expectedOutput = [1, 3, 6, 10];
    var count = 0;

    Stream.fromIterable(const [1, 2, 3, 4])
        .scan<int>((acc, value, index) => acc + value, 0)
        .listen(expectAsync1((result) {
          expect(expectedOutput[count++], result);
        }, count: expectedOutput.length));
  });

  test('Rx.scan.nullable', () {
    nullableTest<String?>(
      (s) => s.scan((acc, value, index) => acc, null),
    );

    expect(
      Stream.fromIterable(const [1, 2, 3, 4])
          .scan<int?>((acc, value, index) => (acc ?? 0) + value, null)
          .cast<int>(),
      emitsInOrder(<int>[1, 3, 6, 10]),
    );
  });

  test('Rx.scan.reusable', () async {
    final transformer =
        ScanStreamTransformer<int, int>((acc, value, index) => acc + value, 0);
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
        .scan<int>((acc, value, index) => acc + value, 0);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.scan.error.shouldThrow', () async {
    final streamWithError = Stream.fromIterable(const [1, 2, 3, 4])
        .scan((acc, value, index) => throw StateError('oh noes!'), 0);

    streamWithError.listen(null,
        onError: expectAsync2((StateError e, StackTrace s) {
          expect(e, isStateError);
        }, count: 4));
  });

  test('Rx.scan accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream =
        controller.stream.scan<int>((acc, value, index) => acc + value, 0);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
