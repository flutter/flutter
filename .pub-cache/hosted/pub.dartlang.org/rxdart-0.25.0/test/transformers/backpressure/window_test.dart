import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> getStream(int n) async* {
  var k = 0;

  while (k < n) {
    await Future<Null>.delayed(const Duration(milliseconds: 100));

    yield k++;
  }
}

void main() {
  test('Rx.window', () async {
    await expectLater(
        getStream(4)
            .window(Stream<Null>.periodic(const Duration(milliseconds: 160))
                .take(3))
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [0, 1],
          const [2, 3],
          emitsDone
        ]));
  });

  test('Rx.window.sampleBeforeEvent.shouldEmit', () async {
    await expectLater(
        Stream.fromFuture(
                Future<Null>.delayed(const Duration(milliseconds: 200))
                    .then((_) => 'end'))
            .startWith('start')
            .window(Stream<Null>.periodic(const Duration(milliseconds: 40))
                .take(10))
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const ['start'], // after 40ms
          const <String>[], // 80ms
          const <String>[], // 120ms
          const <String>[], // 160ms
          const ['end'], // done
          emitsDone
        ]));
  });

  test('Rx.window.shouldClose', () async {
    final controller = StreamController<int>()..add(0)..add(1)..add(2)..add(3);

    scheduleMicrotask(controller.close);

    await expectLater(
        controller.stream
            .window(Stream<Null>.periodic(const Duration(seconds: 3)))
            .asyncMap((stream) => stream.toList())
            .take(1),
        emitsInOrder(<dynamic>[
          const [0, 1, 2, 3], // done
          emitsDone
        ]));
  });

  test('Rx.window.reusable', () async {
    final transformer = WindowStreamTransformer<int>((_) =>
        Stream<Null>.periodic(const Duration(milliseconds: 160))
            .take(3)
            .asBroadcastStream());

    await expectLater(
        getStream(4)
            .transform(transformer)
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [0, 1],
          const [2, 3],
          emitsDone
        ]));

    await expectLater(
        getStream(4)
            .transform(transformer)
            .asyncMap((stream) => stream.toList()),
        emitsInOrder(<dynamic>[
          const [0, 1],
          const [2, 3],
          emitsDone
        ]));
  });

  test('Rx.window.asBroadcastStream', () async {
    final future = getStream(4)
        .asBroadcastStream()
        .window(Stream<Null>.periodic(const Duration(milliseconds: 160))
            .take(10)
            .asBroadcastStream())
        .drain<void>();

    // listen twice on same stream
    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.window.error.shouldThrowA', () async {
    await expectLater(
        Stream<Null>.error(Exception())
            .window(Stream<Null>.periodic(const Duration(milliseconds: 160))),
        emitsError(isException));
  });

  test('Rx.window.error.shouldThrowB', () async {
    await expectLater(Stream.fromIterable(const [1, 2, 3, 4]).window(null),
        emitsError(isArgumentError));
  });
}
