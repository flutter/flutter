import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.mergeWith', () async {
    final delayedStream = Rx.timer(1, Duration(milliseconds: 10));
    final immediateStream = Stream.value(2);
    const expected = [2, 1];
    var count = 0;

    delayedStream.mergeWith([immediateStream]).listen(expectAsync1((result) {
      expect(result, expected[count++]);
    }, count: expected.length));
  });

  test('Rx.mergeWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.mergeWith([Stream<int>.empty()]);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.mergeWith on single stream should stay single ', () async {
    final delayedStream = Rx.timer(1, Duration(milliseconds: 10));
    final immediateStream = Stream.value(2);
    final expected = [2, 1, emitsDone];

    final concatenatedStream = delayedStream.mergeWith([immediateStream]);

    expect(concatenatedStream.isBroadcast, isFalse);
    expect(concatenatedStream, emitsInOrder(expected));
  });

  test('Rx.mergeWith on broadcast stream should stay broadcast ', () async {
    final delayedStream =
        Rx.timer(1, Duration(milliseconds: 10)).asBroadcastStream();
    final immediateStream = Stream.value(2);
    final expected = [2, 1, emitsDone];

    final concatenatedStream = delayedStream.mergeWith([immediateStream]);

    expect(concatenatedStream.isBroadcast, isTrue);
    expect(concatenatedStream, emitsInOrder(expected));
  });

  test('Rx.mergeWith multiple subscriptions on single ', () async {
    final delayedStream = Rx.timer(1, Duration(milliseconds: 10));
    final immediateStream = Stream.value(2);

    final concatenatedStream = delayedStream.mergeWith([immediateStream]);

    expect(() => concatenatedStream.listen(null), returnsNormally);
    expect(() => concatenatedStream.listen(null),
        throwsA(TypeMatcher<StateError>()));
  });
}
