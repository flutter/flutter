import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  const num expected = 0;

  test('Rx.onErrorReturnWith', () async {
    Stream<num>.error(Exception())
        .onErrorReturnWith((dynamic e) => e is StateError ? 1 : 0)
        .listen(expectAsync1((num result) {
      expect(result, expected);
    }));
  });

  test('Rx.onErrorReturnWith.asBroadcastStream', () async {
    final stream = Stream<num>.error(Exception())
        .onErrorReturnWith((dynamic e) => 0)
        .asBroadcastStream();

    await expectLater(stream.isBroadcast, isTrue);

    stream.listen(expectAsync1((num result) {
      expect(result, expected);
    }));

    stream.listen(expectAsync1((num result) {
      expect(result, expected);
    }));
  });

  test('Rx.onErrorReturnWith.pause.resume', () async {
    StreamSubscription<num> subscription;

    subscription = Stream<num>.error(Exception())
        .onErrorReturnWith((dynamic e) => 0)
        .listen(expectAsync1((num result) {
      expect(result, expected);

      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.onErrorReturnWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.onErrorReturnWith((Object _) => 1);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
