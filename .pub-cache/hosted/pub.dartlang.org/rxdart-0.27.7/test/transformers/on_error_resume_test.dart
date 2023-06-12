import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

Stream<int> _getStream() => Stream.fromIterable(const [0, 1, 2, 3]);

const List<int> expected = [0, 1, 2, 3];

void main() {
  test('Rx.onErrorResumeNext', () async {
    var count = 0;

    Stream<int>.error(Exception())
        .onErrorResumeNext(_getStream())
        .listen(expectAsync1((result) {
          expect(result, expected[count++]);
        }, count: expected.length));
  });

  test('Rx.onErrorResume', () async {
    var count = 0;

    Stream<int>.error(Exception())
        .onErrorResume((e, st) => _getStream())
        .listen(expectAsync1((result) {
          expect(result, expected[count++]);
        }, count: expected.length));
  });

  test('Rx.onErrorResume.correctError', () async {
    final exception = Exception();

    expect(
      Stream<Object>.error(exception).onErrorResume((e, st) => Stream.value(e)),
      emits(exception),
    );
  });

  test('Rx.onErrorResumeNext.asBroadcastStream', () async {
    final stream = Stream<int>.error(Exception())
        .onErrorResumeNext(_getStream())
        .asBroadcastStream();
    var countA = 0, countB = 0;

    await expectLater(stream.isBroadcast, isTrue);

    stream.listen(expectAsync1((result) {
      expect(result, expected[countA++]);
    }, count: expected.length));
    stream.listen(expectAsync1((result) {
      expect(result, expected[countB++]);
    }, count: expected.length));
  });

  test('Rx.onErrorResumeNext.error.shouldThrow', () async {
    final streamWithError = Stream<void>.error(Exception())
        .onErrorResumeNext(Stream<void>.error(Exception()));

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.onErrorResumeNext.pause.resume', () async {
    final transformer =
        OnErrorResumeStreamTransformer<int>((_, __) => _getStream());
    final exp = const [50] + expected;
    late StreamSubscription<num> subscription;
    var count = 0;

    subscription = Rx.merge([
      Stream.value(50),
      Stream<int>.error(Exception()),
    ]).transform(transformer).listen(expectAsync1((result) {
          expect(result, exp[count++]);

          if (count == exp.length) {
            subscription.cancel();
          }
        }, count: exp.length));

    subscription.pause();
    subscription.resume();
  });

  test('Rx.onErrorResumeNext.close', () async {
    var count = 0;

    Stream<int>.error(Exception()).onErrorResumeNext(_getStream()).listen(
        expectAsync1((result) {
          expect(result, expected[count++]);
        }, count: expected.length),
        onDone: expectAsync0(() {
          // The code should reach this point
          expect(true, true);
        }, count: 1));
  });

  test('Rx.onErrorResumeNext.noErrors.close', () async {
    expect(
      Stream<int>.empty().onErrorResumeNext(_getStream()),
      emitsDone,
    );
  });

  test('OnErrorResumeStreamTransformer.reusable', () async {
    final transformer = OnErrorResumeStreamTransformer<int>(
        (_, __) => _getStream().asBroadcastStream());
    var countA = 0, countB = 0;

    Stream<int>.error(Exception())
        .transform(transformer)
        .listen(expectAsync1((result) {
          expect(result, expected[countA++]);
        }, count: expected.length));

    Stream<int>.error(Exception())
        .transform(transformer)
        .listen(expectAsync1((result) {
          expect(result, expected[countB++]);
        }, count: expected.length));
  });

  test('Rx.onErrorResume accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream =
        controller.stream.onErrorResume((_, __) => Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.onErrorResumeNext accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.onErrorResumeNext(Stream<int>.empty());

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.onErrorResume still adds data when Stream emits an error: issue/616',
      () {
    {
      final stream = Rx.concat<int>([
        Stream.value(1),
        Stream.error(Exception()),
        Stream.fromIterable([2, 3]),
        Stream.error(Exception()),
        Stream.value(4),
      ]).onErrorResume((e, s) => Stream.value(-1));
      expect(
        stream,
        emitsInOrder(<Object>[1, -1, 2, 3, -1, 4, emitsDone]),
      );
    }

    {
      final stream = Rx.concat<int>([
        Stream.value(1),
        Stream.error(Exception()),
        Stream.fromIterable([2, 3]),
        Stream.error(Exception()),
        Stream.value(4),
      ]).onErrorResumeNext(Stream.value(-1));
      expect(
        stream,
        emitsInOrder(<Object>[1, -1, 2, 3, -1, 4, emitsDone]),
      );
    }
  });

  test('Rx.onErrorResumeNext with many errors', () {
    final stream = Rx.concat<int>([
      Stream.value(1),
      Stream.error(Exception()),
      Stream.value(2),
      Stream.error(StateError('')),
      Stream.value(3),
    ]).onErrorResume((e, s) {
      if (e is Exception) {
        return Rx.timer(-1, const Duration(milliseconds: 100));
      }
      if (e is StateError) {
        return Rx.timer(-2, const Duration(milliseconds: 200));
      }
      throw e;
    });
    expect(
      stream,
      emitsInOrder(<Object>[1, 2, 3, -1, -2, emitsDone]),
    );
  });

  test('Rx.onErrorResumeNext.nullable', () {
    nullableTest<String?>(
      (s) => s.onErrorResumeNext(Stream.empty()),
    );
  });
}
