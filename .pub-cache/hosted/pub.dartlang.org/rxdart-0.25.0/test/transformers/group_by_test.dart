import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

String _toEventOdd(int value) => value == 0 ? 'even' : 'odd';

void main() {
  test('Rx.groupBy', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, 4]).groupBy((value) => value),
        emitsInOrder(<Matcher>[
          TypeMatcher<GroupByStream<int, int>>()
              .having((stream) => stream.key, 'key', 1),
          TypeMatcher<GroupByStream<int, int>>()
              .having((stream) => stream.key, 'key', 2),
          TypeMatcher<GroupByStream<int, int>>()
              .having((stream) => stream.key, 'key', 3),
          TypeMatcher<GroupByStream<int, int>>()
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
  });

  test('Rx.groupBy.correctlyEmitsGroupEvents.alternate', () async {
    await expectLater(
        Stream.fromIterable([1, 2, 3, 4])
            .groupBy((value) => _toEventOdd(value % 2))
            // fold is called when onDone triggers on the Stream
            .map((stream) async => await stream.fold(
                {stream.key: <int>[]},
                (Map<String, List<int>> previous, element) =>
                    previous..[stream.key].add(element))),
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
  });

  test('Rx.groupBy.asBroadcastStream', () async {
    final stream = Stream.fromIterable([1, 2, 3, 4])
        .asBroadcastStream()
        .groupBy((value) => value);

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.groupBy.pause.resume', () async {
    var count = 0;
    StreamSubscription subscription;

    subscription = Stream.fromIterable([1, 2, 3, 4])
        .groupBy((value) => value)
        .listen(expectAsync1((result) {
          count++;

          if (count == 4) {
            subscription.cancel();
          }
        }, count: 4));

    subscription.pause(Future<void>.delayed(const Duration(milliseconds: 100)));
  });

  test('Rx.groupBy.error.shouldThrow.onError', () async {
    final streamWithError =
        Stream<void>.error(Exception()).groupBy((value) => value);

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('Rx.groupBy.error.shouldThrow.onGrouper', () async {
    final streamWithError = Stream.fromIterable([1, 2, 3, 4]).groupBy((value) {
      throw Exception();
    });

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
          expect(e, isException);
        }, count: 4));
  });
  test('Rx.groupBy accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.groupBy((_) => _);

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
