import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() {
  final controller = StreamController<int>();

  Timer(const Duration(milliseconds: 100), () => controller.add(1));
  Timer(const Duration(milliseconds: 200), () => controller.add(2));
  Timer(const Duration(milliseconds: 300), () => controller.add(3));
  Timer(const Duration(milliseconds: 400), () {
    controller.add(4);
    controller.close();
  });

  return controller.stream;
}

void main() {
  test('Rx.debounce', () async {
    await expectLater(
        _getStream().debounce((_) => Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(milliseconds: 200)))),
        emitsInOrder(<dynamic>[4, emitsDone]));
  });

  test('Rx.debounce.dynamicWindow', () async {
    // Given the input [1, 2, 3, 4]
    // debounce 200ms on [1, 2, 4]
    // debounce 0ms on [3]
    // yields [3, 4, done]
    await expectLater(
        _getStream().debounce((value) => value == 3
            ? Stream<bool>.value(true)
            : Stream<void>.fromFuture(
                Future<void>.delayed(const Duration(milliseconds: 200)))),
        emitsInOrder(<dynamic>[3, 4, emitsDone]));
  });

  test('Rx.debounce.reusable', () async {
    final transformer = DebounceStreamTransformer<int>(
        (_) => Stream<void>.periodic(const Duration(milliseconds: 200)));

    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[4, emitsDone]));

    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[4, emitsDone]));
  });

  test('Rx.debounce.asBroadcastStream', () async {
    final future = _getStream()
        .asBroadcastStream()
        .debounce((_) => Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(milliseconds: 200))))
        .drain<void>();

    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.debounce.error.shouldThrowA', () async {
    await expectLater(
        Stream<void>.error(Exception()).debounce((_) => Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(milliseconds: 200)))),
        emitsError(isException));
  });

  test('Rx.debounce.pause.resume', () async {
    final controller = StreamController<int>();
    StreamSubscription<int> subscription;

    subscription = Stream.fromIterable([1, 2, 3])
        .debounce((_) => Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(milliseconds: 200))))
        .listen(controller.add, onDone: () {
      controller.close();
      subscription.cancel();
    });

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 50)));

    await expectLater(controller.stream, emitsInOrder(<dynamic>[3, emitsDone]));
  });

  test('Rx.debounce.emits.last.item.immediately', () async {
    final emissions = <int>[];
    final stopwatch = Stopwatch();
    final stream = Stream.fromIterable(const [1, 2, 3]).debounce((_) =>
        Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(milliseconds: 200))));
    StreamSubscription<int> subscription;

    stopwatch.start();

    subscription = stream.listen(
        expectAsync1((val) {
          emissions.add(val);
        }, count: 1), onDone: expectAsync0(() {
      stopwatch.stop();

      expect(emissions, const [3]);

      // We debounce for 100 seconds. To ensure we aren't waiting that long to
      // emit the last item after the base stream completes, we expect the
      // last value to be emitted to be much shorter than that.
      expect(stopwatch.elapsedMilliseconds < 500, isTrue);

      subscription.cancel();
    }));
  }, timeout: Timeout(Duration(seconds: 3)));

  test(
    'Rx.debounce.cancel.emits.nothing',
    () async {
      StreamSubscription<int> subscription;
      final stream = Stream.fromIterable(const [1, 2, 3]).doOnDone(() {
        subscription.cancel();
      }).debounce((_) => Stream<void>.fromFuture(
          Future<void>.delayed(const Duration(milliseconds: 200))));

      // We expect the onData callback to be called 0 times because the
      // subscription is cancelled when the base stream ends.
      subscription = stream.listen(expectAsync1((_) {}, count: 0));
    },
    timeout: Timeout(Duration(seconds: 3)),
  );

  test('Rx.debounce.last.event.can.be.null', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, null]).debounce((_) =>
            Stream<void>.fromFuture(
                Future<void>.delayed(const Duration(milliseconds: 200)))),
        emitsInOrder(<dynamic>[null, emitsDone]));
  });
}
