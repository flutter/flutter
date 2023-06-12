import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.bufferTest', () async {
    await expectLater(
        Rx.range(1, 4).bufferTest((i) => i % 2 == 0),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));
  });

  test('Rx.bufferTest.reusable', () async {
    final transformer = BufferTestStreamTransformer<int>((i) => i % 2 == 0);

    await expectLater(
        Stream.fromIterable(const [1, 2, 3, 4]).transform(transformer),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));

    await expectLater(
        Stream.fromIterable(const [1, 2, 3, 4]).transform(transformer),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));
  });

  test('Rx.bufferTest.asBroadcastStream', () async {
    final stream = Stream.fromIterable(const [1, 2, 3, 4])
        .asBroadcastStream()
        .bufferTest((i) => i % 2 == 0);

    // listen twice on same stream
    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));

    await expectLater(stream, emitsDone);
  });

  test('Rx.bufferTest.error.shouldThrowA', () async {
    await expectLater(
        Stream<int>.error(Exception()).bufferTest((i) => i % 2 == 0),
        emitsError(isException));
  });

  test('Rx.bufferTest.skip.shouldThrowB', () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).bufferTest(null),
        throwsArgumentError);
  });
}
