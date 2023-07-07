// Test for ensuring that protobuf lists compare using value semantics.
library list_equality_test;

import 'package:test/test.dart';

import 'mock_util.dart' show T;

void main() {
  test('empty lists compare as equal', () {
    final first = T();
    final second = T();
    expect(first.int32s == second.int32s, isTrue);
  });

  test('empty frozen lists compare as equal', () {
    final first = T()..freeze();
    final second = T()..freeze();
    expect(first.int32s == second.int32s, isTrue);
  });

  test('non-empty lists compare as equal', () {
    final first = T()..int32s.add(1);
    final second = T()..int32s.add(1);
    expect(first.int32s == second.int32s, isTrue);
  });

  test('non-empty frozen lists compare as equal', () {
    final first = T()
      ..int32s.add(1)
      ..freeze();
    final second = T()
      ..int32s.add(1)
      ..freeze();
    expect(first.int32s == second.int32s, isTrue);
  });

  test('different lists do not compare as equal', () {
    final first = T()..int32s.add(1);
    final second = T()..int32s.add(2);
    expect(first.int32s == second.int32s, isFalse);
  });

  test('different frozen lists do not compare as equal', () {
    final first = T()
      ..int32s.add(1)
      ..freeze();
    final second = T()
      ..int32s.add(2)
      ..freeze();
    expect(first.int32s == second.int32s, isFalse);
  });
}
