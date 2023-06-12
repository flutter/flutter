import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

const resourceDuration = Duration(milliseconds: 5);

class MockResource {
  var _closed = false;

  bool get isClosed => _closed;

  MockResource();

  Future<void> close() {
    if (_closed) {
      throw StateError('Resource has already been closed.');
    }
    _closed = true;
    return Future<void>.delayed(resourceDuration);
  }

  void closeSync() {
    if (_closed) {
      throw StateError('Resource has already been closed.');
    }
    _closed = true;
  }
}

enum Close {
  sync,
  async,
}

enum Create {
  sync,
  async,
}

void main() async {
  for (final close in Close.values) {
    for (final create in Create.values) {
      final groupPrefix =
          'Rx.using.${create.toString().toLowerCase()}.${close.toString().toLowerCase()}';

      group(groupPrefix, () {
        late MockResource resource;
        var isResourceCreated = false;

        late FutureOr<MockResource> Function() resourceFactory;
        late FutureOr<MockResource> Function() resourceFactoryThrows;

        late FutureOr<void> Function(MockResource) disposer;
        late FutureOr<void> Function(MockResource) disposerThrows;

        setUp(() {
          isResourceCreated = false;

          resourceFactory = () {
            switch (create) {
              case Create.sync:
                isResourceCreated = true;
                return resource = MockResource();
              case Create.async:
                return Future<MockResource>.delayed(
                  resourceDuration,
                  () {
                    isResourceCreated = true;
                    return resource = MockResource();
                  },
                );
            }
          };

          resourceFactoryThrows = () {
            switch (create) {
              case Create.sync:
                throw Exception();
              case Create.async:
                return Future<MockResource>.delayed(
                  resourceDuration,
                  () => throw Exception(),
                );
            }
          };

          disposer = (resource) {
            switch (close) {
              case Close.async:
                return resource.close();
              case Close.sync:
                // ignore: unnecessary_cast
                return resource.closeSync() as FutureOr<void>;
            }
          };

          disposerThrows = (resource) {
            switch (close) {
              case Close.async:
                return Future<void>.delayed(
                  resourceDuration,
                  () => throw Exception(),
                );
              case Close.sync:
                throw Exception();
            }
          };
        });

        test('$groupPrefix.done', () async {
          final stream = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Stream.value(resource)
                .flatMap((_) => Stream.fromIterable([1, 2, 3])),
            disposer,
          );

          await expectLater(
            stream,
            emitsInOrder(<dynamic>[
              1,
              2,
              3,
              emitsDone,
            ]),
          );

          expect(isResourceCreated, true);
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.resourceFactory.throws', () async {
          var calledStreamFactory = false;
          var callDisposer = false;

          final stream = Rx.using<int, MockResource>(
            resourceFactoryThrows,
            (resource) {
              calledStreamFactory = true;
              return Rx.range(0, 3);
            },
            (resource) {
              callDisposer = true;
              return disposer(resource);
            },
          );

          await expectLater(
            stream,
            emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
          );

          expect(isResourceCreated, false);
          expect(calledStreamFactory, false);
          expect(callDisposer, false);
        });

        test('$groupPrefix.disposer.throws', () async {
          final subscription = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Rx.timer(0, resourceDuration),
            disposerThrows,
          ).listen(null);

          if (create == Create.async) {
            await Future<void>.delayed(resourceDuration * 1.2);
          }

          await expectLater(
            subscription.cancel(),
            throwsException,
          );
        });

        test('$groupPrefix.streamFactory.throws', () async {
          final stream = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => throw Exception(),
            disposer,
          );

          await expectLater(
            stream,
            emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
          );

          expect(isResourceCreated, true);
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.streamFactory.errors', () async {
          final stream = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Stream.error(Exception()),
            disposer,
          );

          await expectLater(
            stream,
            emitsInOrder(<dynamic>[emitsError(isException), emitsDone]),
          );

          expect(isResourceCreated, true);
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.cancel.delayed', () async {
          const duration = Duration(milliseconds: 200);

          final subscription = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Rx.concat([
              Rx.timer(0, duration),
              Stream.error(Exception()),
            ]),
            disposer,
          ).listen(
            null,
            cancelOnError: false,
          );

          // ensure the stream has started
          await Future<void>.delayed(resourceDuration + duration ~/ 2);
          await subscription.cancel();
          await Future<void>.delayed(resourceDuration * 1.2);

          expect(isResourceCreated, true);
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.cancel.immediately', () async {
          final subscription = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Rx.concat([
              Rx.timer(0, const Duration(milliseconds: 10)),
              Stream.error(Exception()),
            ]),
            disposer,
          ).listen(
            expectAsync1((v) => expect(true, false), count: 0),
            onError: expectAsync2(
              (Object e, StackTrace stackTrace) => expect(true, false),
              count: 0,
            ),
            onDone: expectAsync0(() => expect(true, false), count: 0),
          );

          await subscription.cancel();
          await Future<void>.delayed(resourceDuration * 2);

          expect(isResourceCreated, true);
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.errors.continueOnError', () async {
          Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Rx.concat([
              Rx.timer(0, resourceDuration * 2),
              Stream<int>.error(Exception())
            ]),
            disposer,
          ).listen(
            null,
            onError: (Object e, StackTrace s) {},
            cancelOnError: false,
          );

          await Future<void>.delayed(resourceDuration * 1.2);
          expect(isResourceCreated, true);
          expect(resource.isClosed, false);
        });

        test('$groupPrefix.errors.cancelOnError', () async {
          Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Stream.error(Exception()),
            disposer,
          ).listen(
            null,
            onError: (Object e, StackTrace s) {},
            cancelOnError: true,
          );

          await Future<void>.delayed(resourceDuration * 1.2);
          expect(isResourceCreated, true);
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.single.subscription', () async {
          final stream = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Rx.range(0, 3),
            disposer,
          );
          stream.listen(null);
          expect(() => stream.listen(null), throwsStateError);
        });

        test('$groupPrefix.asBroadcastStream', () async {
          final stream = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Stream.periodic(
              const Duration(milliseconds: 50),
              (i) => i,
            ),
            disposer,
          ).asBroadcastStream(onCancel: (s) => s.cancel());

          final s1 = stream.listen(null);
          final s2 = stream.listen(null);

          // can reach here
          expect(true, true);

          await Future<void>.delayed(resourceDuration * 1.2);
          await s1.cancel();
          await s2.cancel();
          expect(resource.isClosed, true);
        });

        test('$groupPrefix.pause.resume', () async {
          late StreamSubscription<int> subscription;

          subscription = Rx.using<int, MockResource>(
            resourceFactory,
            (resource) => Stream.periodic(
              const Duration(milliseconds: 20),
              (i) => i,
            ),
            disposer,
          ).listen(
            expectAsync1(
              (value) {
                subscription.cancel();
                expect(value, 0);
              },
              count: 1,
            ),
          );

          subscription
              .pause(Future<void>.delayed(const Duration(milliseconds: 50)));
        });
      });
    }
  }
}
