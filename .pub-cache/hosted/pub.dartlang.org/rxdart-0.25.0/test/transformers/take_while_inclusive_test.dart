import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.takeWhileInclusive', () async {
    final stream = Stream.fromIterable([2, 3, 4, 5, 6, 1, 2, 3])
        .takeWhileInclusive((i) => i < 4);
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[2, 3, 4, emitsDone]),
    );
  });

  test('Rx.takeWhileInclusive.shouldClose', () async {
    final stream =
        Stream.fromIterable([2, 3, 4, 5, 6, 1, 2, 3]).takeWhileInclusive((i) {
      if (i == 4) {
        throw Exception();
      } else {
        return true;
      }
    });
    await expectLater(
      stream,
      emitsInOrder(
        <dynamic>[
          2,
          3,
          emitsError(isA<Exception>()),
          emitsDone,
        ],
      ),
    );
  });

  test('Rx.takeWhileInclusive.asBroadcastStream', () async {
    final stream = Stream.fromIterable([2, 3, 4, 5, 6])
        .takeWhileInclusive((i) => i < 4)
        .asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.takeWhileInclusive.shouldThrowA', () async {
    expect(
      () => Stream.value(42).takeWhileInclusive(null),
      throwsArgumentError,
    );
  });

  test('Rx.takeWhileInclusive.shouldThrowB', () async {
    final stream =
        Stream<void>.error(Exception()).takeWhileInclusive((_) => true);
    await expectLater(
      stream,
      emitsError(isA<Exception>()),
    );
  });

  test('Rx.takeWhileInclusive.pause.resume', () async {
    StreamSubscription<num> subscription;

    subscription = Stream.fromIterable([2, 3, 4, 5, 6])
        .takeWhileInclusive((i) => i < 4)
        .listen(expectAsync1((data) {
      expect(data, 2);
      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.takeWhileInclusive accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.takeWhileInclusive((_) => true);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
