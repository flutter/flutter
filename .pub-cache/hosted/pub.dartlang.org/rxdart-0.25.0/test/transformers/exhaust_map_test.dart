import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('ExhaustMap', () {
    test('does not create a new Stream while emitting', () async {
      var calls = 0;
      final stream = Rx.range(0, 9).exhaustMap((i) {
        calls++;
        return Rx.timer(i, Duration(milliseconds: 100));
      });

      await expectLater(stream, emitsInOrder(<dynamic>[0, emitsDone]));
      await expectLater(calls, 1);
    });

    test('starts emitting again after previous Stream is complete', () async {
      final stream = Stream.fromIterable(const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
          .interval(Duration(milliseconds: 30))
          .exhaustMap((i) async* {
        yield await Future.delayed(Duration(milliseconds: 70), () => i);
      });

      await expectLater(stream, emitsInOrder(<dynamic>[0, 3, 6, 9, emitsDone]));
    });

    test('is reusable', () async {
      final transformer = ExhaustMapStreamTransformer(
          (int i) => Rx.timer(i, Duration(milliseconds: 100)));

      await expectLater(
        Rx.range(0, 9).transform(transformer),
        emitsInOrder(<dynamic>[0, emitsDone]),
      );

      await expectLater(
        Rx.range(0, 9).transform(transformer),
        emitsInOrder(<dynamic>[0, emitsDone]),
      );
    });

    test('works as a broadcast stream', () async {
      final stream = Rx.range(0, 9)
          .asBroadcastStream()
          .exhaustMap((i) => Rx.timer(i, Duration(milliseconds: 100)));

      await expectLater(() {
        stream.listen(null);
        stream.listen(null);
      }, returnsNormally);
    });

    test('should emit errors from source', () async {
      final streamWithError = Stream<int>.error(Exception())
          .exhaustMap((i) => Rx.timer(i, Duration(milliseconds: 100)));

      await expectLater(streamWithError, emitsError(isException));
    });

    test('should emit errors from mapped stream', () async {
      final streamWithError = Stream.value(1).exhaustMap(
          (_) => Stream<void>.error(Exception('Catch me if you can!')));

      await expectLater(streamWithError, emitsError(isException));
    });

    test('should emit errors thrown in the mapper', () async {
      final streamWithError = Stream.value(1).exhaustMap<void>((_) {
        throw Exception('oh noes!');
      });

      await expectLater(streamWithError, emitsError(isException));
    });

    test('can be paused and resumed', () async {
      StreamSubscription<int> subscription;
      final stream = Rx.range(0, 9)
          .exhaustMap((i) => Rx.timer(i, Duration(milliseconds: 20)));

      subscription = stream.listen(expectAsync1((value) {
        expect(value, 0);
        subscription.cancel();
      }, count: 1));

      subscription.pause();
      subscription.resume();
    });

    test('Rx.exhaustMap accidental broadcast', () async {
      final controller = StreamController<int>();

      final stream = controller.stream.exhaustMap((_) => Stream<int>.empty());

      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);

      controller.add(1);
    });
  });
}
