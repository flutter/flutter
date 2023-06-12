import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.retry', () async {
    const retries = 3;

    await expectLater(Rx.retry(_getRetryStream(retries), retries),
        emitsInOrder(<dynamic>[1, emitsDone]));
  });

  test('RetryStream', () async {
    const retries = 3;

    await expectLater(RetryStream<int>(_getRetryStream(retries), retries),
        emitsInOrder(<dynamic>[1, emitsDone]));
  });

  test('RetryStream.onDone', () async {
    const retries = 3;

    await expectLater(RetryStream(_getRetryStream(retries), retries),
        emitsInOrder(<dynamic>[1, emitsDone]));
  });

  test('RetryStream.infinite.retries', () async {
    await expectLater(RetryStream(_getRetryStream(1000)),
        emitsInOrder(<dynamic>[1, emitsDone]));
  });

  test('RetryStream.emits.original.items', () async {
    const retries = 3;

    await expectLater(RetryStream(_getStreamWithExtras(retries), retries),
        emitsInOrder(<dynamic>[1, 1, 1, 2, emitsDone]));
  });

  test('RetryStream.single.subscription', () async {
    const retries = 3;

    final stream = RetryStream(_getRetryStream(retries), retries);

    try {
      stream.listen(null);
      stream.listen(null);
    } catch (e) {
      await expectLater(e, isStateError);
    }
  });

  test('RetryStream.asBroadcastStream', () async {
    const retries = 3;

    final stream =
        RetryStream(_getRetryStream(retries), retries).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('RetryStream.error.shouldThrow', () async {
    final streamWithError = RetryStream(_getRetryStream(3), 2);

    await expectLater(
      streamWithError,
      emitsInOrder(
        <Matcher>[
          emitsError(isA<Error>()),
          emitsError(isA<Error>()),
          emitsError(isA<Error>()),
          emitsDone,
        ],
      ),
    );
  });

  test('RetryStream.error.capturesErrors', () {
    RetryStream(_getRetryStream(3), 2).listen(
      expectAsync1((_) {}, count: 0),
      onError: expectAsync2(
        (Object e, StackTrace st) {
          expect(e, isA<Error>());
          expect(st, isNotNull);
        },
        count: 3,
      ),
      onDone: expectAsync0(() {}, count: 1),
    );
  });

  test('RetryStream.pause.resume', () async {
    late StreamSubscription<int> subscription;
    const retries = 3;

    subscription = RetryStream(_getRetryStream(retries), retries)
        .listen(expectAsync1((result) {
      expect(result, 1);

      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });
}

Stream<int> Function() _getRetryStream(int failCount) {
  var count = 0;

  return () {
    if (count < failCount) {
      count++;
      return Stream<int>.error(Error(), StackTrace.fromString('S'));
    } else {
      return Stream.value(1);
    }
  };
}

Stream<int> Function() _getStreamWithExtras(int failCount) {
  var count = 0;

  return () {
    if (count < failCount) {
      count++;

      // Emit first item
      return Stream.value(1)
          // Emit the error
          .concatWith([Stream<int>.error(Error())])
          // Emit an extra item, testing that it is not included
          .concatWith([Stream.value(1)]);
    } else {
      return Stream.value(2);
    }
  };
}
