import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  const num expected = 0;

  test('Rx.onErrorReturnWith', () async {
    Stream<num>.error(Exception())
        .onErrorReturnWith((e, _) => e is StateError ? 1 : 0)
        .listen(expectAsync1((num result) {
      expect(result, expected);
    }));
  });

  test('Rx.onErrorReturnWith.asBroadcastStream', () async {
    final stream = Stream<num>.error(Exception())
        .onErrorReturnWith((_, __) => 0)
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
    late StreamSubscription<num> subscription;

    subscription = Stream<num>.error(Exception())
        .onErrorReturnWith((_, __) => 0)
        .listen(expectAsync1((num result) {
      expect(result, expected);

      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.onErrorReturnWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.onErrorReturnWith((_, __) => 1);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test(
      'Rx.onErrorReturnWith still adds data when Stream emits an error: issue/616',
      () {
    final stream = Rx.concat<int>([
      Stream.value(1),
      Stream.error(Exception()),
      Stream.fromIterable([2, 3]),
      Stream.error(Exception()),
      Stream.value(4),
    ]).onErrorReturnWith((e, s) => -1);
    expect(
      stream,
      emitsInOrder(<Object>[1, -1, 2, 3, -1, 4, emitsDone]),
    );
  });

  test('Rx.onErrorReturnWith.nullable', () {
    nullableTest<String?>(
      (s) => s.onErrorReturnWith((e, s) => 'String'),
    );
  });
}
