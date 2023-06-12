import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.zipWith', () async {
    Stream<int>.value(1)
        .zipWith(Stream<int>.value(2), (int one, int two) => one + two)
        .listen(expectAsync1((int result) {
          expect(result, 3);
        }, count: 1));
  });

  test('Rx.zipWith accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream =
        controller.stream.zipWith(Stream<int>.empty(), (_, dynamic __) => true);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.zipWith on single stream should stay single ', () async {
    final delayedStream = Rx.timer(1, Duration(milliseconds: 10));
    final immediateStream = Stream.value(2);
    final expected = [3, emitsDone];

    final concatenatedStream =
        delayedStream.zipWith(immediateStream, (a, int b) => a + b);

    expect(concatenatedStream.isBroadcast, isFalse);
    expect(concatenatedStream, emitsInOrder(expected));
  });

  test('Rx.zipWith on broadcast stream should stay broadcast ', () async {
    final delayedStream =
        Rx.timer(1, Duration(milliseconds: 10)).asBroadcastStream();
    final immediateStream = Stream.value(2);
    final expected = [3, emitsDone];

    final concatenatedStream =
        delayedStream.zipWith(immediateStream, (a, int b) => a + b);

    expect(concatenatedStream.isBroadcast, isTrue);
    expect(concatenatedStream, emitsInOrder(expected));
  });

  test('Rx.zipWith multiple subscriptions on single ', () async {
    final delayedStream = Rx.timer(1, Duration(milliseconds: 10));
    final immediateStream = Stream.value(2);

    final concatenatedStream =
        delayedStream.zipWith(immediateStream, (a, int b) => a + b);

    expect(() => concatenatedStream.listen(null), returnsNormally);
    expect(() => concatenatedStream.listen(null),
        throwsA(TypeMatcher<StateError>()));
  });
}
