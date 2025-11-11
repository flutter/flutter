import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tab throws clear error when both text and child are set', () {
    // Wrap in a closure so the assertion is checked at runtime
    expect(
      () {
        Tab(text: 'Hi', child: Text('World')); // no const
      },
      throwsA(isA<AssertionError>()),
    );
  });
}
