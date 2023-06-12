import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.fromCallable.sync', () {
    var called = false;

    var stream = Rx.fromCallable(() {
      called = true;
      return 2;
    });

    expect(called, false);
    expectLater(stream, emitsInOrder(<dynamic>[2, emitsDone]));
    expect(called, true);
  });

  test('Rx.fromCallable.async', () {
    var called = false;

    var stream = FromCallableStream(() async {
      called = true;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return 2;
    });

    expect(called, false);
    expectLater(stream, emitsInOrder(<dynamic>[2, emitsDone]));
    expect(called, true);
  });

  test('Rx.fromCallable.reusable', () {
    var stream = Rx.fromCallable(() => 2, reusable: true);
    expect(stream.isBroadcast, isTrue);

    stream.listen(null);
    stream.listen(null);

    expect(true, true);
  });

  test('Rx.fromCallable.singleSubscription', () {
    {
      var stream = Rx.fromCallable(() =>
          Future.delayed(const Duration(milliseconds: 10), () => 'Value'));

      expect(stream.isBroadcast, isFalse);
      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);
    }

    {
      var stream = Rx.fromCallable(() => Future<String>.error(Exception()));

      expect(stream.isBroadcast, isFalse);
      stream.listen(null, onError: (Object e) {});
      expect(
          () => stream.listen(null, onError: (Object e) {}), throwsStateError);
    }
  });

  test('Rx.fromCallable.asBroadcastStream', () async {
    final stream = Rx.fromCallable(() => 2).asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    await expectLater(stream.isBroadcast, isTrue);
  });

  test('Rx.fromCallable.sync.shouldThrow', () {
    var stream = Rx.fromCallable<String>(() => throw Exception());

    expectLater(
      stream,
      emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
    );
  });

  test('Rx.fromCallable.async.shouldThrow', () {
    {
      var stream = Rx.fromCallable<String>(() async => throw Exception());

      expectLater(
        stream,
        emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
      );
    }

    {
      var stream = Rx.fromCallable<String>(() => Future.error(Exception()));

      expectLater(
        stream,
        emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
      );
    }
  });

  test('Rx.fromCallable.sync.pause.resume', () {
    var stream = Rx.fromCallable(() => 'Value');

    stream
        .listen(
          expectAsync1(
            (v) => expect(v, 'Value'),
            count: 1,
          ),
        )
        .pause(Future<void>.delayed(const Duration(milliseconds: 50)));
  });

  test('Rx.fromCallable.async.pause.resume', () {
    var stream = Rx.fromCallable(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return 'Value';
    });

    stream
        .listen(
          expectAsync1(
            (v) => expect(v, 'Value'),
            count: 1,
          ),
        )
        .pause(Future<void>.delayed(const Duration(milliseconds: 50)));
  });
}
