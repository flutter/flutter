import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/streams/using.dart';
import 'package:test/test.dart';

class MockResource extends Mock {
  Future<void> close();

  void closeSync();
}

Future<void> main() async {
  MockResource Function() resourceFactory;
  MockResource resource;

  setUp(() {
    resourceFactory = () {
      resource = MockResource();
      when(resource.close())
          .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 10)));
      return resource;
    };
  });

  test('Rx.using.done', () async {
    final stream = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Stream.value(resource).mapTo(1),
      (resource) => resource.close(),
    );

    await expectLater(
      stream,
      emitsInOrder(<dynamic>[
        1,
        emitsDone,
      ]),
    );

    verify(resource.close()).called(1);
  });

  test('Rx.using.resourceFactory.throws', () async {
    var calledStreamFactory = false;
    var callDisposer = false;

    final stream = Rx.using<int, MockResource>(
      () => throw Exception(),
      (resource) {
        calledStreamFactory = true;
        return Rx.range(0, 3);
      },
      (resource) {
        callDisposer = true;
        return resource.close();
      },
    );

    await expectLater(
      stream,
      emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
    );

    expect(calledStreamFactory, false);
    expect(callDisposer, false);
  });

  test('Rx.using.streamFactory.throws', () async {
    final stream = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => throw Exception(),
      (resource) => resource.close(),
    );

    await expectLater(
      stream,
      emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
    );

    verify(resource.close()).called(1);
  });

  test('Rx.using.cancel.A', () async {
    final subscription = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Rx.concat([
        Rx.range(0, 5),
        Stream.error(Exception()),
        Rx.range(0, 1000).interval(const Duration(milliseconds: 100)),
      ]),
      (resource) => resource.close(),
    ).listen(
      null,
      onError: (Object e, StackTrace s) {},
      cancelOnError: false,
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    await subscription.cancel();
    verify(resource.close()).called(1);
  });

  test('Rx.using.cancel.B', () async {
    final subscription = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Rx.concat([
        Rx.range(0, 5),
        Stream.error(Exception()),
        Rx.range(0, 1000).interval(const Duration(milliseconds: 100)),
      ]),
      (resource) => resource.close(),
    ).listen(
      expectAsync1((v) => expect(true, false), count: 0),
      onError: expectAsync2(
        (Object e, StackTrace stackTrace) => expect(true, false),
        count: 0,
      ),
      onDone: expectAsync0(() => expect(true, false), count: 0),
    );

    await subscription.cancel();
  });

  test('Rx.using.errors.notCancelOnError', () async {
    Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Rx.concat([
        Rx.range(0, 5),
        Stream.error(Exception()),
        Rx.range(0, 1000).interval(const Duration(milliseconds: 100)),
      ]),
      (resource) => resource.close(),
    ).listen(
      null,
      onError: (Object e, StackTrace s) {},
      cancelOnError: false,
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    verifyNever(resource.close());
  });

  test('Rx.using.errors.shouldThrows', () {
    expect(
      () => UsingStream<int, int>(null, (_) => Stream.value(1), (_) {}),
      throwsArgumentError,
    );

    expect(
      () => UsingStream<int, int>(() => 1, null, (_) {}),
      throwsArgumentError,
    );

    expect(
      () => UsingStream<int, int>(() => 1, (_) => Stream.value(1), null),
      throwsArgumentError,
    );
  });

  test('Rx.using.errors.cancelOnError', () async {
    Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Rx.concat([
        Rx.range(0, 5),
        Stream.error(Exception()),
        Rx.range(0, 1000).interval(const Duration(milliseconds: 100)),
      ]),
      (resource) => resource.close(),
    ).listen(
      null,
      onError: (Object e, StackTrace s) {},
      cancelOnError: true,
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    verify(resource.close()).called(1);
  });

  test('Rx.using.disposer.sync', () async {
    final stream = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Rx.range(0, 3),
      (resource) => resource.closeSync(),
    );

    await expectLater(
      stream,
      emitsInOrder(<dynamic>[0, 1, 2, 3, emitsDone]),
    );

    verify(resource.closeSync()).called(1);
  });

  test('Rx.using.single.subscription', () async {
    final stream = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Rx.range(0, 3),
      (resource) => resource.close(),
    );
    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);
  });

  test('Rx.using.asBroadcastStream', () async {
    final stream = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Stream.periodic(
        const Duration(milliseconds: 50),
        (i) => i,
      ),
      (resource) => resource.close(),
    ).asBroadcastStream(onCancel: (s) => s.cancel());

    final s1 = stream.listen(null);
    final s2 = stream.listen(null);

    expect(true, true);

    await Future<void>.delayed(const Duration(milliseconds: 100));
    await s1.cancel();
    await s2.cancel();

    verify(resource.close()).called(1);
  });

  test('Rx.using.pause.resume', () async {
    StreamSubscription<int> subscription;

    subscription = Rx.using<int, MockResource>(
      resourceFactory,
      (resource) => Stream.periodic(
        const Duration(milliseconds: 20),
        (i) => i,
      ),
      (resource) => resource.close(),
    ).listen(
      expectAsync1(
        (value) {
          subscription.cancel();
          expect(value, 0);
        },
        count: 1,
      ),
    );

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 50)));
  });
}
