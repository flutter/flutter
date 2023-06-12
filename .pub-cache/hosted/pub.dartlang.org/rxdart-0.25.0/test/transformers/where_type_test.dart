import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<Object> _getStream() {
  final controller = StreamController<dynamic>();

  Timer(const Duration(milliseconds: 100), () => controller.add(1));
  Timer(const Duration(milliseconds: 200), () => controller.add('2'));
  Timer(
      const Duration(milliseconds: 300), () => controller.add(const {'3': 3}));
  Timer(const Duration(milliseconds: 400), () {
    controller.add(const {'4': '4'});
  });
  Timer(const Duration(milliseconds: 500), () {
    controller.add(5.0);
    controller.close();
  });

  return controller.stream;
}

void main() {
  test('Rx.whereType', () async {
    _getStream().whereType<Map<String, int>>().listen(expectAsync1((result) {
          expect(result, isMap);
        }, count: 1));
  });

  test('Rx.whereType.polymorphism', () async {
    _getStream().whereType<num>().listen(expectAsync1((result) {
          expect(result is num, true);
        }, count: 2));
  });

  test('Rx.whereType.null.values', () async {
    await expectLater(
        Stream.fromIterable([null, 1, null, 'two', 3]).whereType<String>(),
        emitsInOrder(const <String>['two']));
  });

  test('Rx.whereType.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().whereType<int>();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.whereType.error.shouldThrow', () async {
    final streamWithError = Stream<void>.error(Exception()).whereType<num>();

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.whereType.pause.resume', () async {
    StreamSubscription<int> subscription;
    final stream = Stream.value(1).whereType<int>();

    subscription = stream.listen(expectAsync1((value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.whereType accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.whereType<int>();

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
