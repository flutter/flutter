import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

String _toEventOdd(int value) => value == 0 ? 'even' : 'odd';

void main() {
  test('Rx.groupBy', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, 4]).groupBy((value) => value),
        emitsInOrder(<Matcher>[
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 1),
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 2),
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 3),
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 4),
          emitsDone
        ]));

    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy((value) => value, durationSelector: (_) => Rx.never()),
        emitsInOrder(<Matcher>[
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 1),
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 2),
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 3),
          TypeMatcher<GroupedStream<int, int>>()
              .having((stream) => stream.key, 'key', 4),
          emitsDone
        ]));
  });

  test('Rx.groupBy.correctlyEmitsGroupEvents', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy((value) => _toEventOdd(value % 2))
            .flatMap((stream) => stream.map((event) => {stream.key: event})),
        emitsInOrder(<dynamic>[
          {'odd': 1},
          {'even': 2},
          {'odd': 3},
          {'even': 4},
          emitsDone
        ]));

    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy(
              (value) => _toEventOdd(value % 2),
              durationSelector: (_) =>
                  Stream.periodic(const Duration(seconds: 1)),
            )
            .flatMap((stream) => stream.map((event) => {stream.key: event})),
        emitsInOrder(<dynamic>[
          {'odd': 1},
          {'even': 2},
          {'odd': 3},
          {'even': 4},
          emitsDone
        ]));
  });

  test('Rx.groupBy.correctlyEmitsGroupEvents.alternate', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy((value) => _toEventOdd(value % 2))
            // fold is called when onDone triggers on the Stream
            .map((stream) async => await stream.fold(
                {stream.key: <int>[]},
                (Map<String, List<int>> previous, element) =>
                    previous..[stream.key]?.add(element))),
        emitsInOrder(<dynamic>[
          {
            'odd': [1, 3]
          },
          {
            'even': [2, 4]
          },
          emitsDone
        ]));

    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy(
              (value) => _toEventOdd(value % 2),
              durationSelector: (_) =>
                  Stream.periodic(const Duration(seconds: 1)),
            )
            // fold is called when onDone triggers on the Stream
            .map((stream) async => await stream.fold(
                {stream.key: <int>[]},
                (Map<String, List<int>> previous, element) =>
                    previous..[stream.key]?.add(element))),
        emitsInOrder(<dynamic>[
          {
            'odd': [1, 3]
          },
          {
            'even': [2, 4]
          },
          emitsDone
        ]));
  });

  test('Rx.groupBy.emittedStreamCallOnDone', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy((value) => value)
            // drain will emit 'done' onDone
            .map((stream) async => await stream.drain('done')),
        emitsInOrder(<dynamic>['done', 'done', 'done', 'done', emitsDone]));

    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy((value) => value, durationSelector: (_) => Rx.never())
            // drain will emit 'done' onDone
            .map((stream) async => await stream.drain('done')),
        emitsInOrder(<dynamic>['done', 'done', 'done', 'done', emitsDone]));
  });

  test('Rx.groupBy.asBroadcastStream', () async {
    {
      final stream = Stream.fromIterable([1, 2, 3, 4])
          .asBroadcastStream()
          .groupBy((value) => value);

      // listen twice on same stream
      stream.listen(null);
      stream.listen(null);
      // code should reach here
      await expectLater(true, true);
    }

    {
      final stream =
          Stream.fromIterable([1, 2, 3, 4]).asBroadcastStream().groupBy(
                (value) => value,
                durationSelector: (_) =>
                    Stream.periodic(const Duration(seconds: 2)),
              );

      // listen twice on same stream
      stream.listen(null);
      stream.listen(null);
      // code should reach here
      await expectLater(true, true);
    }
  });

  test('Rx.groupBy.pause.resume', () async {
    {
      var count = 0;
      late StreamSubscription subscription;

      subscription = Stream.fromIterable([1, 2, 3, 4])
          .groupBy((value) => value)
          .listen(expectAsync1((result) {
            count++;

            if (count == 4) {
              subscription.cancel();
            }
          }, count: 4));

      subscription
          .pause(Future<void>.delayed(const Duration(milliseconds: 100)));
    }

    {
      var count = 0;
      late StreamSubscription subscription;

      subscription = Stream.fromIterable([1, 2, 3, 4])
          .groupBy(
            (value) => value,
            durationSelector: (_) => Rx.timer(null, const Duration(seconds: 1)),
          )
          .listen(expectAsync1((result) {
            count++;

            if (count == 4) {
              subscription.cancel();
            }
          }, count: 4));

      subscription
          .pause(Future<void>.delayed(const Duration(milliseconds: 100)));
    }
  });

  test('Rx.groupBy.error.shouldThrow.onError', () async {
    {
      final streamWithError =
          Stream<void>.error(Exception()).groupBy((value) => value);

      streamWithError.listen(null,
          onError: expectAsync2((Exception e, StackTrace s) {
        expect(e, isException);
      }));
    }

    {
      final streamWithError = Stream<void>.error(Exception()).groupBy(
        (value) => value,
        durationSelector: (_) => Rx.timer(null, const Duration(seconds: 1)),
      );

      streamWithError.listen(null,
          onError: expectAsync2((Exception e, StackTrace s) {
        expect(e, isException);
      }));
    }
  });

  test('Rx.groupBy.error.shouldThrow.onGrouper', () async {
    {
      final streamWithError =
          Stream.fromIterable([1, 2, 3, 4]).groupBy((value) {
        throw Exception();
      });

      streamWithError.listen(null,
          onError: expectAsync2((Exception e, StackTrace s) {
            expect(e, isException);
          }, count: 4));
    }

    {
      final streamWithError = Stream.fromIterable([1, 2, 3, 4]).groupBy(
        (value) => throw Exception(),
        durationSelector: (_) => Rx.timer(null, const Duration(seconds: 1)),
      );

      streamWithError.listen(null,
          onError: expectAsync2((Exception e, StackTrace s) {
            expect(e, isException);
          }, count: 4));
    }
  });
  test('Rx.groupBy accidental broadcast', () async {
    {
      final controller = StreamController<int>();

      final stream = controller.stream.groupBy((_) => _);

      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);

      controller.add(1);
    }

    {
      final controller = StreamController<int>();

      final stream = controller.stream.groupBy(
        (_) => _,
        durationSelector: (_) => Rx.timer(null, const Duration(seconds: 1)),
      );

      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);

      controller.add(1);
    }
  });

  test('Rx.groupBy.durationSelector', () {
    final g = [
      '0 -> 1',
      '1 -> 1',
      '2 -> 1',
      '0 -> 2',
      '1 -> 2',
      '2 -> 2',
    ];
    final take = 30;

    final stream = Stream.periodic(const Duration(milliseconds: 100), (i) => i)
        .groupBy(
          (i) => i % 3,
          durationSelector: (i) =>
              Rx.timer(null, const Duration(milliseconds: 400)),
        )
        .flatMap((g) => g
            .scan<int>((acc, value, index) => acc + 1, 0)
            .map((event) => '${g.key} -> $event'))
        .take(take);

    expect(
      stream,
      emitsInOrder(<Object>[
        ...List.filled(take ~/ g.length, g).expand<String>((e) => e),
        emitsDone,
      ]),
    );
  });

  test('Rx.groupBy.nullable', () {
    nullableTest<GroupedStream<String?, String?>>(
      (s) => s.groupBy((v) => v),
    );
  });
}
