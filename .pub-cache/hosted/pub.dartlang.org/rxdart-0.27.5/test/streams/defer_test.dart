import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.defer', () async {
    const value = 1;

    final stream = _getDeferStream();

    stream.listen(expectAsync1((actual) {
      expect(actual, value);
    }, count: 1));
  });

  test('Rx.defer.multiple.listeners', () async {
    const value = 1;

    final stream = _getBroadcastDeferStream();

    stream.listen(expectAsync1((actual) {
      expect(actual, value);
    }, count: 1));

    stream.listen(expectAsync1((actual) {
      expect(actual, value);
    }, count: 1));
  });

  test('Rx.defer.streamFactory.called', () async {
    var count = 0;

    Stream<int> streamFactory() {
      ++count;
      return Stream.value(1);
    }

    var deferStream = DeferStream(
      streamFactory,
      reusable: false,
    );

    expect(count, 0);

    deferStream.listen(
      expectAsync1((_) {
        expect(count, 1);
      }),
    );
  });

  test('Rx.defer.reusable', () async {
    const value = 1;

    final stream = Rx.defer(
      () => Stream.fromFuture(
        Future.delayed(
          Duration(seconds: 1),
          () => value,
        ),
      ),
      reusable: true,
    );

    stream.listen(
      expectAsync1(
        (actual) => expect(actual, value),
        count: 1,
      ),
    );
    stream.listen(
      expectAsync1(
        (actual) => expect(actual, value),
        count: 1,
      ),
    );
  });

  test('Rx.defer.single.subscription', () async {
    final stream = _getDeferStream();

    try {
      stream.listen(null);
      stream.listen(null);
      expect(true, false);
    } catch (e) {
      expect(e, isStateError);
    }
  });

  test('Rx.defer.error.shouldThrow.A', () async {
    final streamWithError = Rx.defer(() => _getErroneousStream());

    streamWithError.listen(null,
        onError: expectAsync1((Exception e) {
          expect(e, isException);
        }, count: 1));
  });

  test('Rx.defer.error.shouldThrow.B', () {
    final deferStream1 = Rx.defer<int>(() => throw Exception());
    expect(
      deferStream1,
      emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
    );

    final deferStream2 = Rx.defer<int>(() => throw Exception(), reusable: true);
    expect(
      deferStream2,
      emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
    );
  });
}

Stream<int> _getDeferStream() => Rx.defer(() => Stream.value(1));

Stream<int> _getBroadcastDeferStream() =>
    Rx.defer(() => Stream.value(1)).asBroadcastStream();

Stream<int> _getErroneousStream() {
  final controller = StreamController<int>();

  controller.addError(Exception());
  controller.close();

  return controller.stream;
}
