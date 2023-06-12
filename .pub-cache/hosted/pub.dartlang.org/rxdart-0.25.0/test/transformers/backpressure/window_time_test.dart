import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

/// yield immediately, then every 100ms
Stream<int> getStream(int n) async* {
  var k = 1;

  yield 0;

  while (k < n) {
    yield await Future<Null>.delayed(const Duration(milliseconds: 100))
        .then((_) => k++);
  }
}

void main() {
  test('Rx.windowTime', () async {
    await expectLater(
        getStream(4)
            .windowTime(const Duration(milliseconds: 160))
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [0, 1],
          const [2, 3],
          emitsDone
        ]));
  });

  test('Rx.windowTime.shouldClose', () async {
    final controller = StreamController<int>()..add(0)..add(1)..add(2)..add(3);

    scheduleMicrotask(controller.close);

    await expectLater(
        controller.stream
            .windowTime(const Duration(seconds: 3))
            .asyncMap((stream) => stream.toList())
            .take(1),
        emitsInOrder(<dynamic>[
          const [0, 1, 2, 3], // done
          emitsDone
        ]));
  });

  test('Rx.windowTime.reusable', () async {
    final transformer = WindowStreamTransformer<int>(
        (_) => Stream<void>.periodic(const Duration(milliseconds: 160)));

    await expectLater(
        getStream(4)
            .transform(transformer)
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [0, 1], const [2, 3], // done
          emitsDone
        ]));

    await expectLater(
        getStream(4)
            .transform(transformer)
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [0, 1], const [2, 3], // done
          emitsDone
        ]));
  });

  test('Rx.windowTime.asBroadcastStream', () async {
    final future = getStream(4)
        .asBroadcastStream()
        .windowTime(const Duration(milliseconds: 160))
        .drain<void>();

    // listen twice on same stream
    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.windowTime.error.shouldThrowA', () async {
    await expectLater(
        Stream<void>.error(Exception())
            .windowTime(const Duration(milliseconds: 160)),
        emitsError(isException));
  });

  test('Rx.windowTime.error.shouldThrowB', () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).windowTime(null),
        throwsArgumentError);
  });
}
