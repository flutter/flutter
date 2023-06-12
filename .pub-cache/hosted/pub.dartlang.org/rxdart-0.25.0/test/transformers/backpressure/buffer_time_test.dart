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
  test('Rx.bufferTime', () async {
    await expectLater(
        getStream(4).bufferTime(const Duration(milliseconds: 160)),
        emitsInOrder(<dynamic>[
          const [0, 1],
          const [2, 3],
          emitsDone
        ]));
  });

  test('Rx.bufferTime.shouldClose', () async {
    final controller = StreamController<int>()..add(0)..add(1)..add(2)..add(3);

    scheduleMicrotask(controller.close);

    await expectLater(
        controller.stream.bufferTime(const Duration(seconds: 3)).take(1),
        emitsInOrder(<dynamic>[
          const [0, 1, 2, 3], // done
          emitsDone
        ]));
  });

  test('Rx.bufferTime.reusable', () async {
    final transformer = BufferStreamTransformer<int>(
        (_) => Stream<void>.periodic(const Duration(milliseconds: 160)));

    await expectLater(
        getStream(4).transform(transformer),
        emitsInOrder(<dynamic>[
          const [0, 1], const [2, 3], // done
          emitsDone
        ]));

    await expectLater(
        getStream(4).transform(transformer),
        emitsInOrder(<dynamic>[
          const [0, 1], const [2, 3], // done
          emitsDone
        ]));
  });

  test('Rx.bufferTime.asBroadcastStream', () async {
    final stream = getStream(4)
        .asBroadcastStream()
        .bufferTime(const Duration(milliseconds: 160));

    // listen twice on same stream
    await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          const [0, 1],
          const [2, 3],
          emitsDone
        ]));

    await expectLater(stream, emitsInOrder(<dynamic>[emitsDone]));
  });

  test('Rx.bufferTime.error.shouldThrowA', () async {
    await expectLater(
        Stream<void>.error(Exception())
            .bufferTime(const Duration(milliseconds: 160)),
        emitsError(isException));
  });

  test('Rx.bufferTime.error.shouldThrowB', () {
    expect(() => Stream.fromIterable(const [1, 2, 3, 4]).bufferTime(null),
        throwsArgumentError);
  });
}
