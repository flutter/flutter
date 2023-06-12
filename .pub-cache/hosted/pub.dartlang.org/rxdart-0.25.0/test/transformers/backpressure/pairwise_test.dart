import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.pairwise', () async {
    const expectedOutput = [
      [1, 2],
      [2, 3],
      [3, 4]
    ];
    var count = 0;

    final stream = Rx.range(1, 4).pairwise();

    stream.listen(expectAsync1((result) {
      // test to see if the combined output matches
      expect(expectedOutput[count].length, result.length);
      expect(expectedOutput[count][0], result.elementAt(0));
      if (expectedOutput[count].length > 1) {
        expect(expectedOutput[count][1], result.elementAt(1));
      }
      count++;
    }, count: expectedOutput.length));
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
}
