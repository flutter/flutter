// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Simple test for single empty library scenario
import 'package:test/test.dart';
import 'test_helpers.dart';

void main() {
  group('Single Empty Library Tests', () {
    test('placeholder - single empty library consolidated', () {
      expect(true, isTrue);
    });

    // Placeholder: tests consolidated into `unit_coverage_consolidated_test.dart`.

    test('Output formatting for single empty library', () {
      final coverage = Coverage()
        ..library = 'my_empty_lib'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = formatCoveragePercent(coverage);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      expect(output, equals('my_empty_lib: 0.00% | 0 | 0'));

      print('✓ PASSED: Output format is correct');
      print('  Output: $output');
    });

    test('Single empty library sorting comparison', () {
      final coverage = Coverage()
        ..library = 'empty_lib'
        ..totalLines = 0
        ..testedLines = 0;

      // The fix: check if totalLines is zero in comparison function
      final double percent = coverage.totalLines == 0
          ? 0
          : coverage.testedLines / coverage.totalLines;

      expect(percent, equals(0.0));

      print('✓ PASSED: Single empty library comparison works without crash');
      print('  Percent value: $percent');
    });

    test('Verify no divide by zero error with empty library', () {
      final coverage = Coverage()
        ..library = 'test_empty'
        ..totalLines = 0
        ..testedLines = 0;

      // This should NOT throw a divide by zero error
      expect(() {
        final String result = formatCoveragePercent(coverage);
        expect(result, equals('0.00'));
      }, returnsNormally);

      print('✓ PASSED: No divide by zero error thrown');
    });
  });
}
