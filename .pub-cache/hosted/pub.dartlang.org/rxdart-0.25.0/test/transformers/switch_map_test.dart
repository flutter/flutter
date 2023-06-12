import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() {
  final controller = StreamController<int>();

  Timer(const Duration(milliseconds: 10), () => controller.add(1));
  Timer(const Duration(milliseconds: 20), () => controller.add(2));
  Timer(const Duration(milliseconds: 30), () => controller.add(3));
  Timer(const Duration(milliseconds: 40), () {
    controller.add(4);
    controller.close();
  });

  return controller.stream;
}

Stream<int> _getOtherStream(int value) {
  final controller = StreamController<int>();

  Timer(const Duration(milliseconds: 15), () => controller.add(value + 1));
  Timer(const Duration(milliseconds: 25), () => controller.add(value + 2));
  Timer(const Duration(milliseconds: 35), () => controller.add(value + 3));
  Timer(const Duration(milliseconds: 45), () {
    controller.add(value + 4);
    controller.close();
  });

  return controller.stream;
}

Stream<int> range() =>
    Stream.fromIterable(const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

void main() {
  test('Rx.switchMap', () async {
    const expectedOutput = [5, 6, 7, 8];
    var count = 0;

    _getStream().switchMap(_getOtherStream).listen(expectAsync1((result) {
          expect(result, expectedOutput[count++]);
        }, count: expectedOutput.length));
  });

  test('Rx.switchMap.reusable', () async {
    final transformer = SwitchMapStreamTransformer<int, int>(_getOtherStream);
    const expectedOutput = [5, 6, 7, 8];
    var countA = 0, countB = 0;

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(result, expectedOutput[countA++]);
        }, count: expectedOutput.length));

    _getStream().transform(transformer).listen(expectAsync1((result) {
          expect(result, expectedOutput[countB++]);
        }, count: expectedOutput.length));
  });

  test('Rx.switchMap.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().switchMap(_getOtherStream);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.switchMap.error.shouldThrowA', () async {
    final streamWithError =
        Stream<int>.error(Exception()).switchMap(_getOtherStream);

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.switchMap.error.shouldThrowB', () async {
    final streamWithError = Stream.value(1).switchMap(
        (_) => Stream<void>.error(Exception('Catch me if you can!')));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.switchMap.error.shouldThrowC', () async {
    final streamWithError = Stream.value(1).switchMap<void>((_) {
      throw Exception('oh noes!');
    });

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.switchMap.pause.resume', () async {
    StreamSubscription<int> subscription;
    final stream = Stream.value(0).switchMap((_) => Stream.value(1));

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.switchMap stream close after switch', () async {
    final controller = StreamController<int>();
    final list = controller.stream
        .switchMap((it) => Stream.fromIterable([it, it]))
        .toList();

    controller.add(1);
    await Future<void>.delayed(Duration(microseconds: 1));
    controller.add(2);

    await controller.close();
    expect(await list, [1, 1, 2, 2]);
  });

  test('Rx.switchMap accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.switchMap((_) => Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.switchMap closes after the last inner Stream closed - issue/511',
      () async {
    final outer = StreamController<bool>();
    final inner = BehaviorSubject.seeded(false);
    final stream = outer.stream.switchMap((_) => inner.stream);

    expect(stream, emitsThrough(emitsDone));

    outer.add(true);
    await Future<void>.delayed(Duration.zero);
    await inner.close();
    await outer.close();
  });
}
