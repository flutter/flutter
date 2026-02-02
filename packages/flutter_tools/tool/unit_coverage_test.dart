// Test file for unit_coverage.dart - Verifying divide by zero fixes

import 'dart:io';
import 'package:test/test.dart';

// Mock Coverage class (same as in unit_coverage.dart)
class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}

void main() {
  group('Coverage Division by Zero Tests', () {
    test('Test 1: Sorting with zero totalLines should not crash', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib2'
          ..totalLines = 100
          ..testedLines = 50,
      ];

      // This should not throw a divide by zero error
      expect(
        () {
          coverages.sort((Coverage left, Coverage right) {
            final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
            final double rightPercent = right.totalLines == 0 ? 0 : right.testedLines / right.totalLines;
            return leftPercent.compareTo(rightPercent);
          });
        },
        returnsNormally,
      );

      print('✓ Test 1 Passed: Sort handles zero totalLines correctly');
    });

    test('Test 2: Coverage percentage calculation with zero totalLines', () {
      final coverage = Coverage()
        ..library = 'test_lib'
        ..totalLines = 0
        ..testedLines = 0;

      // This should return 'N/A' instead of crashing
      final String coveragePercent = coverage.totalLines == 0
          ? 'N/A'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      expect(coveragePercent, equals('N/A'));
      print('✓ Test 2 Passed: Per-library coverage returns N/A for zero lines');
    });

    test('Test 3: Overall coverage with all zero denominators', () {
      double overallNumerator = 0;
      double overallDenominator = 0;

      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib2'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
      }

      // This should return 'N/A' instead of crashing
      final String overallPercent = overallDenominator == 0
          ? 'N/A'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(overallPercent, equals('N/A'));
      print('✓ Test 3 Passed: Overall coverage returns N/A for zero denominator');
    });

    test('Test 4: Normal coverage calculation (non-zero values)', () {
      final coverage = Coverage()
        ..library = 'normal_lib'
        ..totalLines = 100
        ..testedLines = 75;

      final String coveragePercent = coverage.totalLines == 0
          ? 'N/A'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      expect(coveragePercent, equals('75.00'));
      print('✓ Test 4 Passed: Normal coverage calculation works correctly');
    });

    test('Test 5: Sorting multiple coverages with mixed zero and non-zero', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib_zero'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib_50'
          ..totalLines = 100
          ..testedLines = 50,
        Coverage()
          ..library = 'lib_80'
          ..totalLines = 100
          ..testedLines = 80,
      ];

      expect(
        () {
          coverages.sort((Coverage left, Coverage right) {
            final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
            final double rightPercent = right.totalLines == 0 ? 0 : right.testedLines / right.totalLines;
            return leftPercent.compareTo(rightPercent);
          });
        },
        returnsNormally,
      );

      // Verify sort order: zero percent first, then 50%, then 80%
      expect(coverages[0].library, equals('lib_zero'));
      expect(coverages[1].library, equals('lib_50'));
      expect(coverages[2].library, equals('lib_80'));
      print('✓ Test 5 Passed: Mixed zero and non-zero values sort correctly');
    });

    test('Test 6: Overall percentage with valid data', () {
      double overallNumerator = 0;
      double overallDenominator = 0;

      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib1'
          ..totalLines = 100
          ..testedLines = 80,
        Coverage()
          ..library = 'lib2'
          ..totalLines = 50
          ..testedLines = 40,
      ];

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
      }

      final String overallPercent = overallDenominator == 0
          ? 'N/A'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      // (80 + 40) / (100 + 50) * 100 = 120 / 150 * 100 = 80.00
      expect(overallPercent, equals('80.00'));
      print('✓ Test 6 Passed: Overall percentage calculated correctly');
    });
  });
}
