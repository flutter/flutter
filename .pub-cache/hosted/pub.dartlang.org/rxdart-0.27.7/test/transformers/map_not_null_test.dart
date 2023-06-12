import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('Rx.mapNotNull', () {
    expect(
        Stream.fromIterable(['1', '2', 'invalid_num', '3', 'invalid_num', '4'])
            .mapNotNull(int.tryParse),
        emitsInOrder(<int>[1, 2, 3, 4]));

    // 0-----1-----2-----3-----...-----8-----9-----|
    // 1-----null--3-----null--...-----9-----null--|
    // 1--3--5--7--9--|
    final stream = Stream.periodic(const Duration(milliseconds: 10), (i) => i)
        .take(10)
        .transform(MapNotNullStreamTransformer((i) => i.isOdd ? null : i + 1));
    expect(stream, emitsInOrder(<Object>[1, 3, 5, 7, 9, emitsDone]));
  });

  test('Rx.mapNotNull.shouldThrowA', () {
    expect(
      Stream<bool>.error(Exception()).mapNotNull((_) => true),
      emitsError(isA<Exception>()),
    );

    expect(
      Rx.concat<int>([
        Stream.fromIterable([1, 2]),
        Stream.error(Exception()),
        Stream.value(3),
      ]).mapNotNull((i) => i.isEven ? i + 1 : null),
      emitsInOrder(<dynamic>[
        3,
        emitsError(isException),
        emitsDone,
      ]),
    );
  });

  test('Rx.mapNotNull.shouldThrowB', () {
    expect(
      Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).mapNotNull((i) {
        if (i == 4) throw Exception();
        return i.isEven ? i + 1 : null;
      }),
      emitsInOrder(<dynamic>[
        3,
        emitsError(isException),
        7,
        9,
        11,
        emitsDone,
      ]),
    );
  });

  test('Rx.mapNotNull.asBroadcastStream', () {
    final stream = Stream.fromIterable([2, 3, 4, 5, 6])
        .mapNotNull<int>((i) => null)
        .asBroadcastStream();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);

    // code should reach here
    expect(true, true);
  });

  test('Rx.mapNotNull.singleSubscription', () {
    final stream = StreamController<int>().stream.mapNotNull((i) => i);

    expect(stream.isBroadcast, isFalse);
    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);
  });

  test('Rx.mapNotNull.pause.resume', () async {
    final subscription =
        Stream.fromIterable([2, 3, 4, 5, 6]).mapNotNull((i) => i).listen(null);

    subscription
      ..pause()
      ..onData(expectAsync1((data) {
        expect(data, 2);
        subscription.cancel();
      }))
      ..resume();
  });

  test('Rx.mapNotNull.nullable', () {
    nullableTest<String?>(
      (s) => s.mapNotNull((i) => i),
    );
  });
}
