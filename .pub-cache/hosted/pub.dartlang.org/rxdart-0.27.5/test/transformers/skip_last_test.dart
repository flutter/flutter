import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('Rx.skipLast', () async {
    final stream = Stream.fromIterable([1, 2, 3, 4, 5]).skipLast(3);
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[1, 2, emitsDone]),
    );
  });

  test('Rx.skipLast.zero', () async {
    var count = 0;
    final values = [1, 2, 3, 4, 5];
    final stream =
        Stream.fromIterable(values).doOnData((_) => count++).skipLast(0);
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[1, 2, 3, 4, 5, emitsDone]),
    );
    expect(count, equals(values.length));
  });

  test('Rx.skipLast.skipMoreThanLength', () async {
    final stream = Stream.fromIterable([1, 2, 3, 4, 5]).skipLast(100);

    await expectLater(
      stream,
      emits(emitsDone),
    );
  });

  test('Rx.skipLast.emitsError', () async {
    final stream = Stream<int>.error(Exception()).skipLast(3);
    await expectLater(stream, emitsError(isException));
  });

  test('Rx.skipLast.countCantBeNegative', () async {
    Stream<int> stream() => Stream.fromIterable([1, 2, 3, 4, 5]).skipLast(-1);
    expect(stream, throwsA(isArgumentError));
  });

  test('Rx.skipLast.reusable', () async {
    final transformer = SkipLastStreamTransformer<int>(1);
    Stream<int> stream() => Stream.fromIterable([1, 2, 3, 4, 5]).skipLast(2);
    var valueA = 1, valueB = 1;

    stream().transform(transformer).listen(expectAsync1(
          (result) {
            expect(result, valueA++);
          },
          count: 2,
        ));

    stream().transform(transformer).listen(expectAsync1(
          (result) {
            expect(result, valueB++);
          },
          count: 2,
        ));
  });

  test('Rx.skipLast.asBroadcastStream', () async {
    final stream =
        Stream.fromIterable([1, 2, 3, 4, 5]).skipLast(3).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.skipLast.pause.resume', () async {
    late StreamSubscription<num> subscription;

    subscription = Stream.fromIterable([1, 2, 3, 4, 5])
        .skipLast(3)
        .listen(expectAsync1((data) {
      expect(data, 1);
      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.skipLast.singleSubscription', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.skipLast(3);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.skipLast.nullable', () {
    nullableTest<String?>(
      (s) => s.skipLast(1),
    );
  });
}
