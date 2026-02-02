// Comprehensive test file for unit_coverage.dart - Testing edge cases
// Focus: Libraries with no lines recorded

import 'dart:io';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Edge Case: Library with No Lines Recorded', () {
    test('Test 1: Single library with zero lines', () {
      final coverage = Coverage()
        ..library = 'empty_lib'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = formatCoveragePercent(coverage);

      expect(coveragePercent, equals('0.00'));
      print('✓ Test 1 Passed: Single empty library returns 0.00');
    });

    test('Test 2: Multiple libraries, one with no lines', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_lib'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'normal_lib'
          ..totalLines = 50
          ..testedLines = 25,
      ];

      final List<String> results = [];
      for (final coverage in coverages) {
        final String coveragePercent = formatCoveragePercent(coverage);
        results.add('${coverage.library}: $coveragePercent%');
      }

      expect(results[0], equals('empty_lib: 0.00%'));
      expect(results[1], equals('normal_lib: 50.00%'));
      print('✓ Test 2 Passed: Mixed libraries (one empty) handled correctly');
    });

    test('Test 3: Sorting with multiple empty libraries', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_lib_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib_60'
          ..totalLines = 100
          ..testedLines = 60,
        Coverage()
          ..library = 'empty_lib_2'
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

      // Verify sort order: both empty (0%) come before 60%
      expect(coverages[0].library, equals('empty_lib_1'));
      expect(coverages[1].library, equals('empty_lib_2'));
      expect(coverages[2].library, equals('lib_60'));
      print('✓ Test 3 Passed: Multiple empty libraries sort correctly');
    });

    test('Test 4: Overall coverage with all libraries empty', () {
      double overallNumerator = 0;
      double overallDenominator = 0;

      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_lib_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'empty_lib_2'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'empty_lib_3'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(overallPercent, equals('0.00'));
      print('✓ Test 4 Passed: All empty libraries return overall 0.00');
    });

    test('Test 5: Overall coverage with some empty libraries', () {
      double overallNumerator = 0;
      double overallDenominator = 0;

      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_lib'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib_1'
          ..totalLines = 100
          ..testedLines = 50,
        Coverage()
          ..library = 'lib_2'
          ..totalLines = 200
          ..testedLines = 150,
      ];

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      // (50 + 150) / (100 + 200) * 100 = 200 / 300 * 100 = 66.67
      expect(overallPercent, equals('66.67'));
      print('✓ Test 5 Passed: Overall coverage ignores empty libraries correctly');
    });

    test('Test 6: Print output simulation with empty library', () {
      final coverage = Coverage()
        ..library = 'empty_module'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = formatCoveragePercent(coverage);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      expect(output, equals('empty_module: 0.00% | 0 | 0'));
      print('✓ Test 6 Passed: Output formatting with empty library correct');
    });

    test('Test 7: Edge case - empty library after sorting', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'lib_90'
          ..totalLines = 100
          ..testedLines = 90,
        Coverage()
          ..library = 'empty_lib'
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

      // Empty library (0%) should come first
      expect(coverages[0].library, equals('empty_lib'));
      expect(coverages[1].library, equals('lib_90'));
      print('✓ Test 7 Passed: Empty library correctly positioned in sorted list');
    });

    test('Test 8: Coverage with single line vs empty', () {
      final emptyCoverage = Coverage()
        ..library = 'empty'
        ..totalLines = 0
        ..testedLines = 0;

      final singleLineCoverage = Coverage()
        ..library = 'single'
        ..totalLines = 1
        ..testedLines = 1;

      final String emptyPercent = emptyCoverage.totalLines == 0
          ? '0.00'
          : (emptyCoverage.testedLines / emptyCoverage.totalLines * 100).toStringAsFixed(2);

      final String singlePercent = singleLineCoverage.totalLines == 0
          ? '0.00'
          : (singleLineCoverage.testedLines / singleLineCoverage.totalLines * 100).toStringAsFixed(
              2,
            );

      expect(emptyPercent, equals('0.00'));
      expect(singlePercent, equals('100.00'));
      print('✓ Test 8 Passed: Empty vs single line library handled correctly');
    });
  });

  group('All Divide by Zero Prevention Tests', () {
    test('Test 9: Comprehensive integration test', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_module1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib_coverage_30'
          ..totalLines = 100
          ..testedLines = 30,
        Coverage()
          ..library = 'empty_module2'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'lib_coverage_70'
          ..totalLines = 100
          ..testedLines = 70,
      ];

      // Test sorting
      expect(() {
        coverages.sort((Coverage left, Coverage right) {
          final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
          final double rightPercent = right.totalLines == 0
              ? 0
              : right.testedLines / right.totalLines;
          return leftPercent.compareTo(rightPercent);
        });
      }, returnsNormally);

      // Test per-library output
      double overallNumerator = 0;
      double overallDenominator = 0;

      final List<String> lines = [];
      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;
        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
        lines.add(
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}',
        );
      }

      // Test overall calculation
      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(lines.length, equals(4));
      expect(overallPercent, equals('50.00')); // (30 + 70) / (100 + 100) * 100
      print('✓ Test 9 Passed: Comprehensive integration test passed');
    });
  });
}
