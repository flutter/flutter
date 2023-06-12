import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.windowCount.noStartBufferEvery', () async {
    await expectLater(
        Rx.range(1, 4).windowCount(2).asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          [1, 2],
          [3, 4],
          emitsDone
        ]));
  });

  test('Rx.windowCount.noStartBufferEvery.includesEventOnClose', () async {
    await expectLater(
        Rx.range(1, 5).windowCount(2).asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          const [5],
          emitsDone
        ]));
  });

  test('Rx.windowCount.startBufferEvery.count2startBufferEvery1', () async {
    await expectLater(
        Rx.range(1, 4).windowCount(2, 1).asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [2, 3],
          const [3, 4],
          const [4],
          emitsDone
        ]));
  });

  test('Rx.windowCount.startBufferEvery.count3startBufferEvery2', () async {
    await expectLater(
        Rx.range(1, 8).windowCount(3, 2).asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [1, 2, 3],
          const [3, 4, 5],
          const [5, 6, 7],
          const [7, 8],
          emitsDone
        ]));
  });

  test('Rx.windowCount.startBufferEvery.count3startBufferEvery4', () async {
    await expectLater(
        Rx.range(1, 8).windowCount(3, 4).asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [1, 2, 3],
          const [5, 6, 7],
          emitsDone
        ]));
  });

  test('Rx.windowCount.reusable', () async {
    final transformer = WindowCountStreamTransformer<int>(2);

    await expectLater(
        Stream.fromIterable(const [1, 2, 3, 4])
            .transform(transformer)
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));

    await expectLater(
        Stream.fromIterable(const [1, 2, 3, 4])
            .transform(transformer)
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [1, 2],
          const [3, 4],
          emitsDone
        ]));
  });

  test('Rx.windowCount.asBroadcastStream', () async {
    final future = Stream.fromIterable(const [1, 2, 3, 4])
        .asBroadcastStream()
        .windowCount(2)
        .drain<void>();

    // listen twice on same stream
    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.windowCount.error.shouldThrowA', () async {
    await expectLater(
      Stream<void>.error(Exception()).windowCount(2),
      emitsError(isException),
    );
  });

  test(
    'Rx.windowCount.shouldThrow.invalidCount.negative',
    () {
      expect(() => Stream.fromIterable(const [1, 2, 3, 4]).windowCount(-1),
          throwsArgumentError);
    },
  );

  test('Rx.windowCount.shouldThrow.invalidCount.isNull', () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).windowCount(null),
        throwsArgumentError);
  });

  test('Rx.windowCount.startBufferEvery.shouldThrow.invalidStartBufferEvery',
      () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).windowCount(2, -1),
        throwsArgumentError);
  });
}
