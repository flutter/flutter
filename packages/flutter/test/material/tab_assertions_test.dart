import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tab throws clear error when both text and child are set', () {
    expect(
      () => const Tab(text: 'Hi', child: Text('World')),
      throwsAssertionError,
    );
  });
}
