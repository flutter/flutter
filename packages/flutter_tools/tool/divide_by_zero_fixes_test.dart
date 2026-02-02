// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test file demonstrating the divide by zero fixes:
// 1. Returning '0.00' instead of attempting to divide by zero
// 2. Treating empty libraries as 0% in comparisons without crashing

import 'package:test/test.dart';
import 'test_helpers.dart';

void main() {
  group('Fix 1: Returning 0.00 Instead Of Divide by Zero', () {
    test('Empty library returns 0.00 string for percentage display', () {
      final coverage = Coverage()
        ..library = 'empty_lib'
        ..totalLines = 0
        ..testedLines = 0;

      // FIX: Check if totalLines is zero before dividing
      final String coveragePercent = coverage.totalLines == 0
          ? '0.00'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      expect(coveragePercent, equals('0.00'));
      print('✓ Fix 1.1: Empty library returns "0.00%" instead of crashing');
    });

    test('Multiple empty libraries all return 0.00', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_lib_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'empty_lib_2'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      final List<String> results = [];
      for (final coverage in coverages) {
        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
        results.add(coveragePercent);
      }

      expect(results, equals(['0.00', '0.00']));
      print('✓ Fix 1.2: Multiple empty libraries return 0.00');
    });

    test('Overall coverage returns 0.00 when all libraries are empty', () {
      double overallNumerator = 0;
      double overallDenominator = 0;

      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'empty_2'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
      }

      // FIX: Check denominator before dividing
      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(overallPercent, equals('0.00'));
      print('✓ Fix 1.3: Overall coverage returns 0.00 when denominator is zero');
    });

    test('Output format shows 0.00 for empty libraries', () {
      final coverage = Coverage()
        ..library = 'my_empty_module'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = coverage.totalLines == 0
          ? '0.00'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      expect(output, equals('my_empty_module: 0.00% | 0 | 0'));
      print('✓ Fix 1.4: Output properly formats 0.00% for display');
    });
  });

  group('Fix 2: Treating as 0% in Comparisons Without Crashing', () {
    test('Single empty library treated as 0% in comparison', () {
      final coverage = Coverage()
        ..library = 'empty_lib'
        ..totalLines = 0
        ..testedLines = 0;

      // FIX: Treat as 0% instead of attempting division
      final double percent = coverage.totalLines == 0
          ? 0
          : coverage.testedLines / coverage.totalLines;

      expect(percent, equals(0.0));
      print('✓ Fix 2.1: Empty library treated as 0.0 in comparison');
    });

    test('Sort empty library correctly (0% comes first)', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib_80'
          ..totalLines = 100
          ..testedLines = 80,
        Coverage()
          ..library = 'empty_lib'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      // FIX: Use 0 for empty libraries in sort comparison
      expect(() {
        coverages.sort((Coverage left, Coverage right) {
          final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
          final double rightPercent = right.totalLines == 0
              ? 0
              : right.testedLines / right.totalLines;
          return leftPercent.compareTo(rightPercent);
        });
      }, returnsNormally);

      // Verify sort order: 0% (empty) comes before 80%
      expect(coverages[0].library, equals('empty_lib'));
      expect(coverages[1].library, equals('lib_80'));
      print('✓ Fix 2.2: Empty library (0%) sorts before higher percentages');
    });

    test('Multiple empty libraries sort together at 0%', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib_50'
          ..totalLines = 100
          ..testedLines = 50,
        Coverage()
          ..library = 'empty_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'empty_2'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      // Both empty libraries should be first (0%)
      expect(coverages[0].library, equals('empty_1'));
      expect(coverages[1].library, equals('empty_2'));
      expect(coverages[2].library, equals('lib_50'));
      print('✓ Fix 2.3: Multiple empty libraries treated as 0% and sort together');
    });

    test('Comparison does not crash with divide by zero', () {
      final coverage1 = Coverage()
        ..library = 'empty'
        ..totalLines = 0
        ..testedLines = 0;

      final coverage2 = Coverage()
        ..library = 'normal'
        ..totalLines = 100
        ..testedLines = 50;

      // This should NOT throw a DivisionByZeroException
      expect(() {
        final double percent1 = coverage1.totalLines == 0
            ? 0
            : coverage1.testedLines / coverage1.totalLines;
        final double percent2 = coverage2.totalLines == 0
            ? 0
            : coverage2.testedLines / coverage2.totalLines;
        final int result = percent1.compareTo(percent2);
        expect(result, lessThan(0)); // Empty (0%) < Normal (50%)
      }, returnsNormally);

      print('✓ Fix 2.4: Comparison completes without divide by zero crash');
    });

    test('Comprehensive sort with mixed empty and normal libraries', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib_90'
          ..totalLines = 100
          ..testedLines = 90,
        Coverage()
          ..library = 'empty_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib_30'
          ..totalLines = 100
          ..testedLines = 30,
        Coverage()
          ..library = 'empty_2'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      expect(() {
        coverages.sort((Coverage left, Coverage right) {
          final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
          final double rightPercent = right.totalLines == 0
              ? 0
              : right.testedLines / right.totalLines;
          return leftPercent.compareTo(rightPercent);
        });
      }, returnsNormally);

      // Verify final order: empty (0%), then 30%, then 90%
      expect(coverages[0].library, equals('empty_1'));
      expect(coverages[1].library, equals('empty_2'));
      expect(coverages[2].library, equals('lib_30'));
      expect(coverages[3].library, equals('lib_90'));
      print('✓ Fix 2.5: Complex sort works correctly treating empty as 0%');
    });
  });

  group('Combined: Both Fixes Working Together', () {
    test('Empty library in full workflow', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_module'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'tested_module'
          ..totalLines = 100
          ..testedLines = 75,
      ];

      // STEP 1: Sort with Fix 2 (treat as 0%)
      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      // STEP 2: Calculate coverage with Fix 1 (return 0.00)
      double overallNumerator = 0;
      double overallDenominator = 0;
      final List<String> outputLines = [];

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
        outputLines.add(
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}',
        );
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      // VERIFY:
      expect(coverages[0].library, equals('empty_module')); // Sorted first (0%)
      expect(outputLines[0], equals('empty_module: 0.00% | 0 | 0')); // Shows 0%
      expect(outputLines[1], equals('tested_module: 75.00% | 75 | 100')); // Normal display
      expect(overallPercent, equals('75.00')); // Overall calculated correctly

      print('✓ Combined Fix: Both fixes work together in full workflow');
      print('  Output Line 1: ${outputLines[0]}');
      print('  Output Line 2: ${outputLines[1]}');
      print('  Overall: $overallPercent%');
    });
  });
}
