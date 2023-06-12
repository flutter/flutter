import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.max', () async {
    await expectLater(_getStream().max(), completion(9));

    expect(
      await Stream.fromIterable(<num>[1, 2, 3, 3.5]).max(),
      3.5,
    );
  });

  test('Rx.max.empty.shouldThrow', () {
    expect(
      () => Stream<int>.empty().max(),
      throwsStateError,
    );
  });

  test('Rx.max.error.shouldThrow', () {
    expect(
      () => Stream.value(1).concatWith(
        [Stream.error(Exception('This is exception'))],
      ).max(),
      throwsException,
    );
  });

  test('Rx.max.with.comparator', () async {
    await expectLater(
      Stream.fromIterable(['one', 'two', 'three'])
          .max((a, b) => a.length - b.length),
      completion('three'),
    );
  });

  test('Rx.max.errorComparator.shouldThrow', () {
    expect(
      () => _getStream().max((a, b) => throw Exception()),
      throwsException,
    );
  });

  test('Rx.max.without.comparator.Comparable', () async {
    const expected = _Class2(3);
    expect(
      await Stream.fromIterable(const [
        _Class2(0),
        expected,
        _Class2(2),
        _Class2(-1),
        _Class2(2),
      ]).max(),
      expected,
    );
  });

  test('Rx.max.without.comparator.not.Comparable', () async {
    expect(
      () => Stream.fromIterable(const [
        _Class1(0),
        _Class1(3),
        _Class1(2),
        _Class1(3),
        _Class1(2),
      ]).max(),
      throwsStateError,
    );
  });
}

class ErrorComparator implements Comparable<ErrorComparator> {
  @override
  int compareTo(ErrorComparator other) {
    throw Exception();
  }
}

Stream<int> _getStream() =>
    Stream<int>.fromIterable(const <int>[2, 3, 3, 5, 2, 9, 1, 2, 0]);

class _Class1 {
  final int value;

  const _Class1(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Class1 &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '_Class{value: $value}';
}

class _Class2 implements Comparable<_Class2> {
  final int value;

  const _Class2(this.value);

  @override
  String toString() => '_Class2{value: $value}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Class2 &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(_Class2 other) => value.compareTo(other.value);
}
