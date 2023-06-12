import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.switchIfEmpty.whenEmpty', () async {
    expect(
      Stream<int>.empty().switchIfEmpty(Stream.value(1)),
      emitsInOrder(<dynamic>[1, emitsDone]),
    );
  });

  test('Rx.initial.completes', () async {
    expect(
      Stream.value(99).switchIfEmpty(Stream.value(1)),
      emitsInOrder(<dynamic>[99, emitsDone]),
    );
  });

  test('Rx.switchIfEmpty.reusable', () async {
    final transformer = SwitchIfEmptyStreamTransformer<bool>(
        Stream.value(true).asBroadcastStream());

    Stream<bool>.empty().transform(transformer).listen(expectAsync1((result) {
          expect(result, true);
        }, count: 1));

    Stream<bool>.empty().transform(transformer).listen(expectAsync1((result) {
          expect(result, true);
        }, count: 1));
  });

  test('Rx.switchIfEmpty.whenNotEmpty', () async {
    Stream.value(false)
        .switchIfEmpty(Stream.value(true))
        .listen(expectAsync1((result) {
          expect(result, false);
        }, count: 1));
  });

  test('Rx.switchIfEmpty.asBroadcastStream', () async {
    final stream =
        Stream<int>.empty().switchIfEmpty(Stream.value(1)).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.switchIfEmpty.error.shouldThrowA', () async {
    final streamWithError =
        Stream<int>.error(Exception()).switchIfEmpty(Stream.value(1));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.switchIfEmpty.error.shouldThrowB', () {
    expect(() => Stream<void>.empty().switchIfEmpty(null), throwsArgumentError);
  });

  test('Rx.switchIfEmpty.pause.resume', () async {
    StreamSubscription<int> subscription;
    final stream = Stream<int>.empty().switchIfEmpty(Stream.value(1));

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.switchIfEmpty accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.switchIfEmpty(Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
