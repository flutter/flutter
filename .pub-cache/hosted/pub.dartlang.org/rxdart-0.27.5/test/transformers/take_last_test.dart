import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('Rx.takeLast', () async {
    final stream = Stream.fromIterable([1, 2, 3, 4, 5]).takeLast(3);
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[3, 4, 5, emitsDone]),
    );
  });

  test('Rx.takeLast.zero', () async {
    var count = 0;
    final values = [1, 2, 3, 4, 5];
    final stream =
        Stream.fromIterable(values).doOnData((_) => count++).takeLast(0);
    await expectLater(
      stream,
      emitsInOrder(<Object>[emitsDone]),
    );
    expect(count, equals(values.length));
  });

  test('Rx.takeLast.emitsError', () async {
    final stream = Stream<int>.error(Exception()).takeLast(3);
    await expectLater(stream, emitsError(isException));
  });

  test('Rx.takeLast.countCantBeNegative', () async {
    Stream<int> stream() => Stream.fromIterable([1, 2, 3, 4, 5]).takeLast(-1);
    expect(stream, throwsA(isArgumentError));
  });

  test('Rx.takeLast.reusable', () async {
    final transformer = TakeLastStreamTransformer<int>(3);
    Stream<int> stream() => Stream.fromIterable([1, 2, 3, 4, 5]).takeLast(3);
    var valueA = 3, valueB = 3;

    stream().transform(transformer).listen(expectAsync1((result) {
          expect(result, valueA++);
        }, count: 3));

    stream().transform(transformer).listen(expectAsync1((result) {
          expect(result, valueB++);
        }, count: 3));
  });

  test('Rx.takeLast.asBroadcastStream', () async {
    final stream =
        Stream.fromIterable([1, 2, 3, 4, 5]).takeLast(3).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.takeLast.pause.resume', () async {
    late StreamSubscription<num> subscription;

    subscription = Stream.fromIterable([1, 2, 3, 4, 5])
        .takeLast(3)
        .listen(expectAsync1((data) {
      expect(data, 3);
      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.takeLast.singleSubscription', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.takeLast(3);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.takeLast.cancel', () {
    final subscription =
        Stream.fromIterable([1, 2, 3, 4, 5]).takeLast(3).listen(null);
    subscription.onData(
      expectAsync1(
        (event) {
          subscription.cancel();
          expect(event, 3);
        },
        count: 1,
      ),
    );
  }, timeout: const Timeout(Duration(seconds: 1)));

  test('Rx.takeLast.nullable', () {
    nullableTest<String?>(
      (s) => s.takeLast(1),
    );
  });
}
