import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.bufferCount.noStartBufferEvery', () async {
    await expectLater(
        Rx.range(1, 4).bufferCount(2),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));
  });

  test('Rx.bufferCount.noStartBufferEvery.includesEventOnClose', () async {
    await expectLater(
        Rx.range(1, 5).bufferCount(2),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          const [5],
          emitsDone
        ]));
  });

  test('Rx.bufferCount.startBufferEvery.count2startBufferEvery1', () async {
    await expectLater(
        Rx.range(1, 4).bufferCount(2, 1),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [2, 3],
          const [3, 4],
          const [4],
          emitsDone
        ]));
  });

  test('Rx.bufferCount.startBufferEvery.count3startBufferEvery2', () async {
    await expectLater(
        Rx.range(1, 8).bufferCount(3, 2),
        emitsInOrder(<dynamic>[
          const [1, 2, 3],
          const [3, 4, 5],
          const [5, 6, 7],
          const [7, 8],
          emitsDone
        ]));
  });

  test('Rx.bufferCount.startBufferEvery.count3startBufferEvery4', () async {
    await expectLater(
        Rx.range(1, 8).bufferCount(3, 4),
        emitsInOrder(<dynamic>[
          const [1, 2, 3],
          const [5, 6, 7],
          emitsDone
        ]));
  });

  test('Rx.bufferCount.reusable', () async {
    final transformer = BufferCountStreamTransformer<int>(2);

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

  test('Rx.bufferCount.asBroadcastStream', () async {
    final stream = Stream.fromIterable(const [1, 2, 3, 4])
        .asBroadcastStream()
        .bufferCount(2);

    // listen twice on same stream
    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));

    await expectLater(stream, emitsInOrder(<dynamic>[emitsDone]));
  });

  test('Rx.bufferCount.error.shouldThrowA', () async {
    await expectLater(Stream<void>.error(Exception()).bufferCount(2),
        emitsError(isException));
  });

  test(
    'Rx.bufferCount.shouldThrow.invalidCount.negative',
    () {
      expect(() => Stream.fromIterable(const [1, 2, 3, 4]).bufferCount(-1),
          throwsArgumentError);
    },
  );

  test('Rx.bufferCount.shouldThrow.invalidCount.isNull', () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).bufferCount(null),
        throwsArgumentError);
  });

  test('Rx.bufferCount.startBufferEvery.shouldThrow.invalidStartBufferEvery',
      () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).bufferCount(2, -1),
        throwsArgumentError);
  });
}
