import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  test('Rx.pairwise', () async {
    const expectedOutput = [
      [1, 2],
      [2, 3],
      [3, 4]
    ];
    var count = 0;

    final stream = Rx.range(1, 4).pairwise();

    stream.listen(
      expectAsync1((result) {
        // test to see if the combined output matches
        expect(result, expectedOutput[count++]);
      }, count: expectedOutput.length),
      onError: expectAsync2((Object e, StackTrace s) {}, count: 0),
      onDone: expectAsync0(() {}, count: 1),
    );
  });

  test('Rx.pairwise.empty', () {
    expect(Stream<int>.empty().pairwise(), emitsDone);
  });

  test('Rx.pairwise.single', () {
    expect(Stream.value(1).pairwise(), emitsDone);
  });

  test('Rx.pairwise.compatible', () {
    expect(
      Stream.fromIterable([1, 2]).pairwise(),
      isA<Stream<Iterable<int>>>(),
    );

    Stream<Iterable<int>> s = Stream.fromIterable([1, 2]).pairwise();
    expect(
      s,
      emitsInOrder(<Object>[
        [1, 2],
        emitsDone
      ]),
    );
  });

  test('Rx.pairwise.asBroadcastStream', () async {
    final stream =
        Stream.fromIterable(const [1, 2, 3, 4]).asBroadcastStream().pairwise();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.pairwise.error.shouldThrow.onError', () async {
    final streamWithError = Stream<void>.error(Exception()).pairwise();

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.pairwise.nullable', () {
    nullableTest<Iterable<String?>>(
      (s) => s.pairwise(),
    );
  });
}
