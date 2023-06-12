import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.mapTo', () async {
    await expectLater(Rx.range(1, 4).mapTo(true),
        emitsInOrder(<dynamic>[true, true, true, true, emitsDone]));
  });

  test('Rx.mapTo.shouldThrow', () async {
    await expectLater(
        Rx.range(1, 4).concatWith([Stream<int>.error(Error())]).mapTo(true),
        emitsInOrder(<dynamic>[
          true,
          true,
          true,
          true,
          emitsError(TypeMatcher<Error>()),
          emitsDone
        ]));
  });

  test('Rx.mapTo.reusable', () async {
    final transformer = MapToStreamTransformer<int, bool>(true);
    final stream = Rx.range(1, 4).asBroadcastStream();

    stream.transform(transformer).listen(null);
    stream.transform(transformer).listen(null);

    await expectLater(true, true);
  });

  test('Rx.mapTo.pause.resume', () async {
    StreamSubscription<bool> subscription;
    final stream = Stream.value(1).mapTo(true);

    subscription = stream.listen(expectAsync1((value) {
      expect(value, isTrue);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.mapTo accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.mapTo(1);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
