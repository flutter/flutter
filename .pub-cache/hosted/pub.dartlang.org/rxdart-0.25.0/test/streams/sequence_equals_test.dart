import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.sequenceEqual.equals', () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 2, 3, 4, 5]),
        Stream.fromIterable(const [1, 2, 3, 4, 5]));

    await expectLater(stream, emitsInOrder(<dynamic>[true, emitsDone]));
  });

  test('Rx.sequenceEqual.diffTime.equals', () async {
    final stream = Rx.sequenceEqual(
        Stream.periodic(const Duration(milliseconds: 100), (i) => i + 1)
            .take(5),
        Stream.fromIterable(const [1, 2, 3, 4, 5]));

    await expectLater(stream, emitsInOrder(<dynamic>[true, emitsDone]));
  });

  test('Rx.sequenceEqual.equals.customCompare.equals', () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 1, 1, 1, 1]),
        Stream.fromIterable(const [2, 2, 2, 2, 2]),
        equals: (int a, int b) => true);

    await expectLater(stream, emitsInOrder(<dynamic>[true, emitsDone]));
  });

  test('Rx.sequenceEqual.diffTime.notEquals', () async {
    final stream = Rx.sequenceEqual(
        Stream.periodic(const Duration(milliseconds: 100), (i) => i + 1)
            .take(5),
        Stream.fromIterable(const [1, 1, 1, 1, 1]));

    await expectLater(stream, emitsInOrder(<dynamic>[false, emitsDone]));
  });

  test('Rx.sequenceEqual.notEquals', () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 2, 3, 4, 5]),
        Stream.fromIterable(const [1, 2, 3, 5, 4]));

    await expectLater(stream, emitsInOrder(<dynamic>[false, emitsDone]));
  });

  test('Rx.sequenceEqual.equals.customCompare.notEquals', () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 1, 1, 1, 1]),
        Stream.fromIterable(const [1, 1, 1, 1, 1]),
        equals: (int a, int b) => false);

    await expectLater(stream, emitsInOrder(<dynamic>[false, emitsDone]));
  });

  test('Rx.sequenceEqual.notEquals.differentLength', () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 2, 3, 4, 5]),
        Stream.fromIterable(const [1, 2, 3, 4, 5, 6]));

    await expectLater(stream, emitsInOrder(<dynamic>[false, emitsDone]));
  });

  test('Rx.sequenceEqual.notEquals.differentLength.customCompare.notEquals',
      () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 2, 3, 4, 5]),
        Stream.fromIterable(const [1, 2, 3, 4, 5, 6]),
        equals: (int a, int b) => true);

    // expect false,
    // even if the equals handler always returns true,
    // the emitted events length is different
    await expectLater(stream, emitsInOrder(<dynamic>[false, emitsDone]));
  });

  test('Rx.sequenceEqual.equals.errors', () async {
    final stream = Rx.sequenceEqual(
        Stream<void>.error(ArgumentError('error A')),
        Stream<void>.error(ArgumentError('error A')));

    await expectLater(stream, emitsInOrder(<dynamic>[true, emitsDone]));
  });

  test('Rx.sequenceEqual.notEquals.errors', () async {
    final stream = Rx.sequenceEqual(
        Stream<void>.error(ArgumentError('error A')),
        Stream<void>.error(ArgumentError('error B')));

    await expectLater(stream, emitsInOrder(<dynamic>[false, emitsDone]));
  });

  test('Rx.sequenceEqual.single.subscription', () async {
    final stream = Rx.sequenceEqual(Stream.fromIterable(const [1, 2, 3, 4, 5]),
        Stream.fromIterable(const [1, 2, 3, 4, 5]));

    await expectLater(stream, emitsInOrder(<dynamic>[true, emitsDone]));
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('Rx.sequenceEqual.asBroadcastStream', () async {
    final future = Rx.sequenceEqual(Stream.fromIterable(const [1, 2, 3, 4, 5]),
            Stream.fromIterable(const [1, 2, 3, 4, 5]))
        .asBroadcastStream()
        .drain<void>();

    // listen twice on same stream
    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.sequenceEqual.error.shouldThrowA', () {
    expect(
        () => Rx.sequenceEqual<int, void>(
            Stream.fromIterable(const [1, 2, 3, 4, 5]), null),
        throwsArgumentError);
  });

  test('Rx.sequenceEqual.error.shouldThrowB', () {
    expect(
        () => Rx.sequenceEqual<void, int>(
            null, Stream.fromIterable(const [1, 2, 3, 4, 5])),
        throwsArgumentError);
  });
}
