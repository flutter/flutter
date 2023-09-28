// File that does not end in "_test"

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('I should not run', () {
    expect(1, 1, reason: 'Test should succeed');
  });
}
