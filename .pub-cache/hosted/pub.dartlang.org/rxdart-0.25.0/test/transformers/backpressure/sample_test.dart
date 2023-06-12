import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() =>
    Stream<int>.periodic(const Duration(milliseconds: 20), (count) => count)
        .take(5);

Stream<int> _getSampleStream() =>
    Stream<int>.periodic(const Duration(milliseconds: 35), (count) => count)
        .take(10);

void main() {
  test('Rx.sample', () async {
    final stream = _getStream().sample(_getSampleStream());

    await expectLater(stream, emitsInOrder(<dynamic>[1, 3, 4, emitsDone]));
  });

  test('Rx.sample.reusable', () async {
    final transformer = SampleStreamTransformer<int>(
        (_) => _getSampleStream().asBroadcastStream());
    final streamA = _getStream().transform(transformer);
    final streamB = _getStream().transform(transformer);

    await expectLater(streamA, emitsInOrder(<dynamic>[1, 3, 4, emitsDone]));
    await expectLater(streamB, emitsInOrder(<dynamic>[1, 3, 4, emitsDone]));
  });

  test('Rx.sample.onDone', () async {
    final stream = Stream.value(1).sample(Stream<void>.empty());

    await expectLater(stream, emits(1));
  });

  test('Rx.sample.shouldClose', () async {
    final controller = StreamController<int>();

    controller.stream
        .sample(Stream<void>.empty()) // should trigger onDone
        .listen(null, onDone: expectAsync0(() => expect(true, isTrue)));

    controller.add(0);
    controller.add(1);
    controller.add(2);
    controller.add(3);

    scheduleMicrotask(controller.close);
  });

  test('Rx.sample.asBroadcastStream', () async {
    final stream = _getStream()
        .asBroadcastStream()
        .sample(_getSampleStream().asBroadcastStream());

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.sample.error.shouldThrowA', () async {
    final streamWithError =
        Stream<void>.error(Exception()).sample(_getSampleStream());

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.sample.error.shouldThrowB', () async {
    final streamWithError = Stream.value(1)
        .sample(Stream<void>.error(Exception('Catch me if you can!')));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.sample.pause.resume', () async {
    final controller = StreamController<int>();
    StreamSubscription<int> subscription;

    subscription = _getStream()
        .sample(_getSampleStream())
        .listen(controller.add, onDone: () {
      controller.close();
      subscription.cancel();
    });

    await expectLater(
        controller.stream, emitsInOrder(<dynamic>[1, 3, 4, emitsDone]));

    subscription.pause();
    subscription.resume();
  });
}
