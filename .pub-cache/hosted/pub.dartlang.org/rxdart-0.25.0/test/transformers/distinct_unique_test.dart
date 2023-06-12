import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('DistinctUniqueStreamTransformer', () {
    test('works with the equals and hascode of the class', () async {
      final stream = Stream.fromIterable(const [
        _TestObject('a'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('c'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('c'),
        _TestObject('a')
      ]).distinctUnique();

      await expectLater(
          stream,
          emitsInOrder(<dynamic>[
            const _TestObject('a'),
            const _TestObject('b'),
            const _TestObject('c'),
            emitsDone
          ]));
    });

    test('works with a provided equals and hashcode', () async {
      final stream = Stream.fromIterable(const [
        _TestObject('a'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('c'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('c'),
        _TestObject('a')
      ]).distinctUnique(
          equals: (a, b) => a.key == b.key, hashCode: (o) => o.key.hashCode);

      await expectLater(
          stream,
          emitsInOrder(<dynamic>[
            const _TestObject('a'),
            const _TestObject('b'),
            const _TestObject('c'),
            emitsDone
          ]));
    });

    test(
        'sends an error to the subscription if an error occurs in the equals or hashmap methods',
        () async {
      final stream = Stream.fromIterable(
              const [_TestObject('a'), _TestObject('b'), _TestObject('c')])
          .distinctUnique(
              equals: (a, b) => a.key == b.key,
              hashCode: (o) => throw Exception('Catch me if you can!'));

      stream.listen(
        null,
        onError: expectAsync2(
          (Exception e, StackTrace s) => expect(e, isException),
          count: 3,
        ),
      );
    });

    test('is reusable', () async {
      const data = [
        _TestObject('a'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('a'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('b'),
        _TestObject('c'),
        _TestObject('a'),
        _TestObject('b'),
        _TestObject('c'),
        _TestObject('a')
      ];

      final distinctUniqueStreamTransformer =
          DistinctUniqueStreamTransformer<_TestObject>();

      final firstStream =
          Stream.fromIterable(data).transform(distinctUniqueStreamTransformer);

      final secondStream =
          Stream.fromIterable(data).transform(distinctUniqueStreamTransformer);

      await expectLater(
          firstStream,
          emitsInOrder(<dynamic>[
            const _TestObject('a'),
            const _TestObject('b'),
            const _TestObject('c'),
            emitsDone
          ]));

      await expectLater(
          secondStream,
          emitsInOrder(<dynamic>[
            const _TestObject('a'),
            const _TestObject('b'),
            const _TestObject('c'),
            emitsDone
          ]));
    });

    test('Rx.distinctUnique accidental broadcast', () async {
      final controller = StreamController<int>();

      final stream = controller.stream.distinctUnique();

      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);

      controller.add(1);
    });
  });
}

class _TestObject {
  final String key;

  const _TestObject(this.key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestObject &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}
