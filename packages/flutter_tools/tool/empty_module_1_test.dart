// Test for completely empty file scenario
// empty_module_1 has no lines recorded (0 total lines, 0 tested lines)

import 'package:test/test.dart';

class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}

void main() {
  group('Empty File Test: empty_module_1 with No Lines', () {
    test('Test 1: Single completely empty file', () {
      final coverage = Coverage()
        ..library = 'empty_module_1'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = coverage.totalLines == 0
          ? '0.00'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      expect(coverage.library, equals('empty_module_1'));
      expect(coverage.totalLines, equals(0));
      expect(coverage.testedLines, equals(0));
      expect(coveragePercent, equals('0.00'));
      expect(output, equals('empty_module_1: 0.00% | 0 | 0'));

      print('✓ Test 1 PASSED: Single empty file');
      print('  Library: empty_module_1');
      print('  Total Lines: 0');
      print('  Tested Lines: 0');
      print('  Coverage: 0.00%');
      print('  Output: $output');
    });

    test('Test 2: Only empty_module_1 with no other files', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_module_1'
          ..totalLines = 0
          ..testedLines = 0,
      ];

      double overallNumerator = 0;
      double overallDenominator = 0;

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;

        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

        final String output =
            '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';
        print('  $output');
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(overallPercent, equals('0.00'));

      print('✓ Test 2 PASSED: Only empty_module_1 file');
      print('  OVERALL: $overallPercent%');
    });

    test('Test 3: empty_module_1 with other files', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_module_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'normal_module'
          ..totalLines = 50
          ..testedLines = 30,
      ];

      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      double overallNumerator = 0;
      double overallDenominator = 0;

      print('  % | tested | total');
      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;

        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

        final String output =
            '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';
        print('  $output');
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(coverages[0].library, equals('empty_module_1'));
      expect(overallPercent, equals('60.00')); // 30 / 50 = 60%

      print('✓ Test 3 PASSED: empty_module_1 with other files');
      print('  OVERALL: $overallPercent%');
    });

    test('Test 4: Multiple empty modules including empty_module_1', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_module_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'empty_module_2'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'file_with_code'
          ..totalLines = 100
          ..testedLines = 50,
      ];

      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      double overallNumerator = 0;
      double overallDenominator = 0;

      print('  % | tested | total');
      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;

        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

        final String output =
            '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';
        print('  $output');
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      expect(coverages[0].library, equals('empty_module_1'));
      expect(coverages[1].library, equals('empty_module_2'));
      expect(coverages[2].library, equals('file_with_code'));
      expect(overallPercent, equals('50.00')); // 50 / 100 = 50%

      print('✓ Test 4 PASSED: Multiple empty modules with empty_module_1');
      print('  OVERALL: $overallPercent%');
    });

    test('Test 5: No division by zero error with empty_module_1', () {
      final coverage = Coverage()
        ..library = 'empty_module_1'
        ..totalLines = 0
        ..testedLines = 0;

      // This should NOT throw a DivisionByZeroException
      expect(() {
        final String percent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
        expect(percent, equals('0.00'));

        // Also test in a comparison
        final double comparisonPercent = coverage.totalLines == 0
            ? 0
            : coverage.testedLines / coverage.totalLines;
        expect(comparisonPercent, equals(0.0));
      }, returnsNormally);

      print('✓ Test 5 PASSED: No divide by zero error with empty_module_1');
    });

    test('Test 6: empty_module_1 output format matches expected', () {
      final coverage = Coverage()
        ..library = 'empty_module_1'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = coverage.totalLines == 0
          ? '0.00'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      // Expected format: "empty_module_1: 0.00% | 0 | 0"
      expect(output, equals('empty_module_1: 0.00% | 0 | 0'));

      print('✓ Test 6 PASSED: empty_module_1 output format');
      print('  Expected: empty_module_1: 0.00% | 0 | 0');
      print('  Actual:   $output');
      print('  Match: ✓');
    });
  });
}
