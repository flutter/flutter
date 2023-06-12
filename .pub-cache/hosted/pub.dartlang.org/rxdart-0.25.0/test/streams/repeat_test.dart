import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/streams/repeat.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.repeat', () async {
    const retries = 3;

    await expectLater(Rx.repeat(_getRepeatStream('A'), retries),
        emitsInOrder(<dynamic>['A0', 'A1', 'A2', emitsDone]));
  });

  test('RepeatStream', () async {
    const retries = 3;

    await expectLater(RepeatStream(_getRepeatStream('A'), retries),
        emitsInOrder(<dynamic>['A0', 'A1', 'A2', emitsDone]));
  });

  test('RepeatStream.onDone', () async {
    const retries = 0;

    await expectLater(RepeatStream(_getRepeatStream('A'), retries), emitsDone);
  });

  test('RepeatStream.infinite.repeats', () async {
    await expectLater(
        RepeatStream(_getRepeatStream('A')), emitsThrough('A100'));
  });

  test('RepeatStream.single.subscription', () async {
    const retries = 3;

    final stream = RepeatStream(_getRepeatStream('A'), retries);

    try {
      stream.listen(null);
      stream.listen(null);
    } catch (e) {
      await expectLater(e, isStateError);
    }
  });

  test('RepeatStream.asBroadcastStream', () async {
    const retries = 3;

    final stream =
        RepeatStream(_getRepeatStream('A'), retries).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('RepeatStream.error.shouldThrow', () async {
    final streamWithError = RepeatStream(_getErroneusRepeatStream('A'), 2);

    await expectLater(
        streamWithError,
        emitsInOrder(<dynamic>[
          'A0',
          emitsError(TypeMatcher<Error>()),
          'A0',
          emitsError(TypeMatcher<Error>()),
          emitsDone
        ]));
  });

  test('RepeatStream.pause.resume', () async {
    StreamSubscription<String> subscription;
    const retries = 3;

    subscription = RepeatStream(_getRepeatStream('A'), retries)
        .listen(expectAsync1((result) {
      expect(result, 'A0');

      subscription.cancel();
    }));

    subscription.pause();
    subscription.resume();
  });
}

Stream<String> Function(int) _getRepeatStream(String symbol) =>
    (int repeatIndex) async* {
      yield await Future.delayed(
          const Duration(milliseconds: 20), () => '$symbol$repeatIndex');
    };

Stream<String> Function(int) _getErroneusRepeatStream(String symbol) =>
    (int repeatIndex) {
      return Stream.value('A0')
          // Emit the error
          .concatWith([Stream<String>.error(Error())]);
    };
