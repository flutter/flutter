import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.defaultIfEmpty.whenEmpty', () async {
    Stream<bool>.empty()
        .defaultIfEmpty(true)
        .listen(expectAsync1((bool result) {
          expect(result, true);
        }, count: 1));
  });

  test('Rx.defaultIfEmpty.reusable', () async {
    final transformer = DefaultIfEmptyStreamTransformer<bool>(true);

    Stream<bool>.empty().transform(transformer).listen(expectAsync1((result) {
          expect(result, true);
        }, count: 1));

    Stream<bool>.empty().transform(transformer).listen(expectAsync1((result) {
          expect(result, true);
        }, count: 1));
  });

  test('Rx.defaultIfEmpty.whenNotEmpty', () async {
    Stream.fromIterable(const [false, false, false])
        .defaultIfEmpty(true)
        .listen(expectAsync1((result) {
          expect(result, false);
        }, count: 3));
  });

  test('Rx.defaultIfEmpty.asBroadcastStream', () async {
    final stream = Stream.fromIterable(const <int>[])
        .defaultIfEmpty(-1)
        .asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.defaultIfEmpty.error.shouldThrow', () async {
    final streamWithError = Stream<int>.error(Exception()).defaultIfEmpty(-1);

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.defaultIfEmpty.pause.resume', () async {
    StreamSubscription<int> subscription;
    final stream = Stream.fromIterable(const <int>[]).defaultIfEmpty(1);

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });
  test('Rx.defaultIfEmpty accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.defaultIfEmpty(1);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
