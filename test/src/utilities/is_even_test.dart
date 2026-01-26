import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/src/utilities/is_even.dart';

void main() {
  test('isEven returns true for even numbers', () {
    expect(isEven(2), isTrue);
    expect(isEven(0), isTrue);
    expect(isEven(-4), isTrue);
  });

  test('isEven returns false for odd numbers', () {
    expect(isEven(3), isFalse);
    expect(isEven(-1), isFalse);
  });
}
