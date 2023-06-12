import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _stream() =>
    Stream.periodic(const Duration(milliseconds: 100), (i) => i + 1).take(10);

void main() {
  test('Rx.throttle', () async {
    await expectLater(
        _stream()
            .throttle(
                (_) => Stream<void>.periodic(const Duration(milliseconds: 250)))
            .take(3),
        emitsInOrder(<dynamic>[1, 4, 7, emitsDone]));
  });

  test('Rx.throttle.trailing', () async {
    await expectLater(
        _stream()
            .throttle(
                (_) => Stream<void>.periodic(const Duration(milliseconds: 250)),
                trailing: true,
                leading: false)
            .take(3),
        emitsInOrder(<dynamic>[3, 6, 9, emitsDone]));
  });

  test('Rx.throttle.dynamic.window', () async {
    await expectLater(
        _stream()
            .throttle((value) => value == 1
                ? Stream<void>.periodic(const Duration(milliseconds: 10))
                : Stream<void>.periodic(const Duration(milliseconds: 250)))
            .take(3),
        emitsInOrder(<dynamic>[1, 2, 5, emitsDone]));
  });

  test('Rx.throttle.dynamic.window.trailing', () async {
    await expectLater(
        _stream()
            .throttle(
                (value) => value == 1
                    ? Stream<void>.periodic(const Duration(milliseconds: 10))
                    : Stream<void>.periodic(const Duration(milliseconds: 250)),
                trailing: true,
                leading: false)
            .take(3),
        emitsInOrder(<dynamic>[1, 4, 7, emitsDone]));
  });

  test('Rx.throttle.leading.trailing.1', () async {
    // --1--2--3--4--5--6--7--8--9--10--11|
    // --1-----3--4-----6--7-----9--10-----11|
    // --^--------^--------^---------^-----

    final values = <int>[];

    final stream = _stream()
        .concatWith([Rx.timer(11, const Duration(milliseconds: 100))]).throttle(
      (v) {
        values.add(v);
        return Stream<void>.periodic(const Duration(milliseconds: 250));
      },
      leading: true,
      trailing: true,
    );
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[1, 3, 4, 6, 7, 9, 10, 11, emitsDone]),
    );
    expect(values, [1, 4, 7, 10]);
  });

  test('Rx.throttle.leading.trailing.2', () async {
    // --1--2--3--4--5--6--7--8--9--10--11|
    // --1-----3--4-----6--7-----9--10-----11|
    // --^--------^--------^---------^-----

    final values = <int>[];

    final stream = _stream().throttle(
      (v) {
        values.add(v);
        return Stream<void>.periodic(const Duration(milliseconds: 250));
      },
      leading: true,
      trailing: true,
    );
    await expectLater(
      stream,
      emitsInOrder(<dynamic>[1, 3, 4, 6, 7, 9, 10, emitsDone]),
    );
    expect(values, [1, 4, 7, 10]);
  });

  test('Rx.throttle.reusable', () async {
    final transformer = ThrottleStreamTransformer<int>(
        (_) => Stream<void>.periodic(const Duration(milliseconds: 250)));

    await expectLater(_stream().transform(transformer).take(2),
        emitsInOrder(<dynamic>[1, 4, emitsDone]));

    await expectLater(_stream().transform(transformer).take(2),
        emitsInOrder(<dynamic>[1, 4, emitsDone]));
  });

  test('Rx.throttle.asBroadcastStream', () async {
    final future = _stream()
        .asBroadcastStream()
        .throttle(
            (_) => Stream<void>.periodic(const Duration(milliseconds: 250)))
        .drain<void>();

    // listen twice on same stream
    await expectLater(future, completes);
    await expectLater(future, completes);
  });

  test('Rx.throttle.error.shouldThrowA', () async {
    final streamWithError = Stream<void>.error(Exception()).throttle(
        (_) => Stream<void>.periodic(const Duration(milliseconds: 250)));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.throttle.error.shouldThrowB', () {
    expect(() => Stream.value(1).throttle(null),
        throwsA(const TypeMatcher<AssertionError>()));
  });

  test('Rx.throttle.pause.resume', () async {
    StreamSubscription<int> subscription;

    final controller = StreamController<int>();

    subscription = _stream()
        .throttle(
            (_) => Stream<void>.periodic(const Duration(milliseconds: 250)))
        .take(2)
        .listen(controller.add, onDone: () {
      controller.close();
      subscription.cancel();
    });

    await expectLater(
        controller.stream, emitsInOrder(<dynamic>[1, 4, emitsDone]));

    await Future<Null>.delayed(const Duration(milliseconds: 150)).whenComplete(
        () => subscription
            .pause(Future<Null>.delayed(const Duration(milliseconds: 150))));
  });
}
