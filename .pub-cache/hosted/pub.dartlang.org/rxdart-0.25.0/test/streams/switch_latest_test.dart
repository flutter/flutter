import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('SwitchLatest', () {
    test('emits all values from an emitted Stream', () {
      expect(
        Rx.switchLatest(
          Stream.value(
            Stream.fromIterable(const ['A', 'B', 'C']),
          ),
        ),
        emitsInOrder(<dynamic>['A', 'B', 'C', emitsDone]),
      );
    });

    test('only emits values from the latest emitted stream', () {
      expect(
        Rx.switchLatest(testStream),
        emits('C'),
      );
    });

    test('emits errors from the higher order Stream to the listener', () {
      expect(
        Rx.switchLatest(
          Stream<Stream<void>>.error(Exception()),
        ),
        emitsError(isException),
      );
    });

    test('emits errors from the emitted Stream to the listener', () {
      expect(
        Rx.switchLatest(errorStream),
        emitsError(isException),
      );
    });

    test('closes after the last event from the last emitted Stream', () {
      expect(
        Rx.switchLatest(testStream),
        emitsThrough(emitsDone),
      );
    });

    test('closes if the higher order stream is empty', () {
      expect(
        Rx.switchLatest(
          Stream<Stream<void>>.empty(),
        ),
        emitsThrough(emitsDone),
      );
    });

    test('is single subscription', () {
      final stream = SwitchLatestStream(testStream);

      expect(stream, emits('C'));
      expect(() => stream.listen(null), throwsStateError);
    });

    test('can be paused and resumed', () {
      // ignore: cancel_subscriptions
      final subscription =
          Rx.switchLatest(testStream).listen(expectAsync1((result) {
        expect(result, 'C');
      }));

      subscription.pause();
      subscription.resume();
    });
  });
}

Stream<Stream<String>> get testStream => Stream.fromIterable([
      Rx.timer('A', Duration(seconds: 2)),
      Rx.timer('B', Duration(seconds: 1)),
      Stream.value('C'),
    ]);

Stream<Stream<String>> get errorStream => Stream.fromIterable([
      Rx.timer('A', Duration(seconds: 2)),
      Rx.timer('B', Duration(seconds: 1)),
      Stream.error(Exception()),
    ]);
