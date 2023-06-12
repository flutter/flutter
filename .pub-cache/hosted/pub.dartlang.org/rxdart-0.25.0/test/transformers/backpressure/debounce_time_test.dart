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
  test('Rx.debounceTime', () async {
    await expectLater(
        _getStream().debounceTime(const Duration(milliseconds: 200)),
        emitsInOrder(<dynamic>[4, emitsDone]));
  });

  test('Rx.debounceTime.reusable', () async {
    final transformer = DebounceStreamTransformer<int>(
        (_) => Stream<void>.periodic(const Duration(milliseconds: 200)));

    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[4, emitsDone]));

    await expectLater(_getStream().transform(transformer),
        emitsInOrder(<dynamic>[4, emitsDone]));
  });

  test('Rx.debounceTime.asBroadcastStream', () async {
    final future = _getStream()
        .asBroadcastStream()
        .debounceTime(const Duration(milliseconds: 200))
        .drain<void>();

    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.debounceTime.error.shouldThrowA', () async {
    await expectLater(
        Stream<void>.error(Exception())
            .debounceTime(const Duration(milliseconds: 200)),
        emitsError(isException));
  });

  test('Rx.debounceTime.pause.resume', () async {
    final controller = StreamController<int>();
    StreamSubscription<int> subscription;

    subscription = Stream.fromIterable([1, 2, 3])
        .debounceTime(Duration(milliseconds: 100))
        .listen(controller.add, onDone: () {
      controller.close();
      subscription.cancel();
    });

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 50)));

    await expectLater(controller.stream, emitsInOrder(<dynamic>[3, emitsDone]));
  });

  test('Rx.debounceTime.emits.last.item.immediately', () async {
    final emissions = <int>[];
    final stopwatch = Stopwatch();
    final stream = Stream.fromIterable(const [1, 2, 3])
        .debounceTime(Duration(seconds: 100));
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
    'Rx.debounceTime.cancel.emits.nothing',
    () async {
      StreamSubscription<int> subscription;
      final stream = Stream.fromIterable(const [1, 2, 3]).doOnDone(() {
        subscription.cancel();
      }).debounceTime(Duration(seconds: 10));

      // We expect the onData callback to be called 0 times because the
      // subscription is cancelled when the base stream ends.
      subscription = stream.listen(expectAsync1((_) {}, count: 0));
    },
    timeout: Timeout(Duration(seconds: 3)),
  );

  test('Rx.debounceTime.last.event.can.be.null', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, null])
            .debounceTime(const Duration(milliseconds: 200)),
        emitsInOrder(<dynamic>[null, emitsDone]));
  });
}
