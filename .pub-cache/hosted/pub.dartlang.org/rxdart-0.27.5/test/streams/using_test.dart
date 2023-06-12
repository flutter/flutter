import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

class MockResource {
  final Future<void> Function() closeFunction;
  var closeCount = 0;
  var closeSyncCount = 0;

  MockResource(this.closeFunction);

  Future<void> close() {
    ++closeCount;
    return closeFunction();
  }

  void closeSync() => ++closeSyncCount;
}

Future<void> main() async {
  late MockResource Function() resourceFactory;
  late MockResource resource;

  setUp(() {
    resourceFactory = () {
      resource =
          MockResource(() => Future.delayed(const Duration(milliseconds: 10)));
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

    expect(resource.closeCount, 1);
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

    expect(resource.closeCount, 1);
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
    expect(resource.closeCount, 1);
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
    expect(resource.closeCount, 0);
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
    expect(resource.closeCount, 1);
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

    expect(resource.closeSyncCount, 1);
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

    expect(resource.closeCount, 1);
  });

  test('Rx.using.pause.resume', () async {
    late StreamSubscription<int> subscription;

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
