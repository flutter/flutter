import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('Rx.whereNotNull', () {
    {
      final notNull = Stream.fromIterable([1, 2, 3, 4]).whereNotNull();

      expect(notNull, isA<Stream<int>>());
      expect(notNull, emitsInOrder(<int>[1, 2, 3, 4]));
    }

    {
      final notNull = Stream.fromIterable([1, 2, null, 3, 4, null])
          .transform(WhereNotNullStreamTransformer());

      expect(notNull, isA<Stream<int>>());
      expect(notNull, emitsInOrder(<int>[1, 2, 3, 4]));
    }
  });

  test('Rx.whereNotNull.shouldThrow', () {
    expect(
      Stream<bool>.error(Exception()).whereNotNull(),
      emitsError(isA<Exception>()),
    );

    expect(
      Rx.concat<int?>([
        Stream.fromIterable([1, 2, null]),
        Stream.error(Exception()),
        Stream.value(3),
      ]).whereNotNull(),
      emitsInOrder(<dynamic>[
        1,
        2,
        emitsError(isException),
        3,
        emitsDone,
      ]),
    );
  });

  test('Rx.whereNotNull.asBroadcastStream', () {
    final stream =
        Stream.fromIterable([1, 2, null]).whereNotNull().asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    expect(true, true);
  });

  test('Rx.whereNotNull.singleSubscription', () {
    final stream = StreamController<int?>().stream.whereNotNull();

    expect(stream.isBroadcast, isFalse);
    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);
  });

  test('Rx.whereNotNull.pause.resume', () async {
    final subscription = Stream.fromIterable([null, 2, 3, null, 4, 5, 6])
        .whereNotNull()
        .listen(null);

    subscription
      ..pause()
      ..onData(expectAsync1((data) {
        expect(data, 2);
        subscription.cancel();
      }))
      ..resume();
  });

  test('Rx.whereNotNull.nullable', () {
    nullableTest<String>(
      (s) => s.whereNotNull(),
    );
  });
}
