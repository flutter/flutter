import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.min', () async {
    await expectLater(_getStream().min(), completion(0));

    expect(
      await Stream.fromIterable(<num>[1, 2, 3, 3.5]).min(),
      1,
    );
  });

  test('Rx.min.empty.shouldThrow', () {
    expect(
      () => Stream<int>.empty().min(),
      throwsStateError,
    );
  });

  test('Rx.min.error.shouldThrow', () {
    expect(
      () => Stream.value(1).concatWith(
        [Stream.error(Exception('This is exception'))],
      ).min(),
      throwsException,
    );
  });

  test('Rx.min.errorComparator.shouldThrow', () {
    expect(
      () => _getStream().min((a, b) => throw Exception()),
      throwsException,
    );
  });

  test('Rx.min.with.comparator', () async {
    await expectLater(
      Stream.fromIterable(['one', 'two', 'three'])
          .min((a, b) => a.length - b.length),
      completion('one'),
    );
  });

  test('Rx.min.without.comparator.Comparable', () async {
    const expected = _Class2(-1);
    expect(
      await Stream.fromIterable(const [
        _Class2(0),
        _Class2(3),
        _Class2(2),
        expected,
        _Class2(2),
      ]).min(),
      expected,
    );
  });

  test('Rx.min.without.comparator.not.Comparable', () async {
    expect(
      () => Stream.fromIterable(const [
        _Class1(0),
        _Class1(3),
        _Class1(2),
        _Class1(3),
        _Class1(2),
      ]).min(),
      throwsStateError,
    );
  });
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
