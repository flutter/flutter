import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.concatWith', () async {
    final delayedStream = Rx.timer(1, Duration(milliseconds: 10));
    final immediateStream = Stream.value(2);
    const expected = [1, 2];
    var count = 0;

    delayedStream.concatWith([immediateStream]).listen(expectAsync1((result) {
      expect(result, expected[count++]);
    }, count: expected.length));
  });
  test('Rx.concatWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.concatWith([Stream<int>.empty()]);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.concatWith on broadcast stream should stay broadcast ', () async {
    final delayedStream =
        Rx.timer(1, Duration(milliseconds: 10)).asBroadcastStream();
    final immediateStream = Stream.value(2);
    final expected = [1, 2, emitsDone];

    final concatenatedStream = delayedStream.concatWith([immediateStream]);

    expect(concatenatedStream.isBroadcast, isTrue);
    expect(concatenatedStream, emitsInOrder(expected));
  });
}
