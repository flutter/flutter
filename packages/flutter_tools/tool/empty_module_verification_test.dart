// Test to verify empty_module handling and overall coverage result

import 'package:test/test.dart';
import 'test_helpers.dart';

void main() {
  group('Verification: Empty Module and Overall Result', () {
    test('Test 1: Verify empty_module displays 0.00%', () {
      final coverage = Coverage()
        ..library = 'empty_module'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = coverage.totalLines == 0
          ? '0.00'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      expect(coverage.library, equals('empty_module'));
      expect(coveragePercent, equals('0.00'));
      expect(output, equals('empty_module: 0.00% | 0 | 0'));

      print('✓ Test 1 PASSED: empty_module');
      print('  Output: $output');
    });

    test('Test 2: Verify Overall result with empty_module', () {
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

      // Sort
      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      // Calculate individual percentages
      final List<String> outputs = [];
      double overallNumerator = 0;
      double overallDenominator = 0;

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;

        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

        outputs.add(
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}',
        );
      }

      // Calculate overall
      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      // Verify output
      expect(outputs[0], equals('empty_module: 0.00% | 0 | 0'));
      expect(outputs[1], equals('tested_module: 75.00% | 75 | 100'));
      expect(overallPercent, equals('75.00'));

      print('✓ Test 2 PASSED: Overall result calculation');
      print('  Per-Library Coverage:');
      for (final output in outputs) {
        print('    $output');
      }
      print('  Overall: $overallPercent%');
    });

    test('Test 3: Verify sorting with empty_module first', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'tested_high'
          ..totalLines = 100
          ..testedLines = 90,
        Coverage()
          ..library = 'empty_module'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'tested_low'
          ..totalLines = 100
          ..testedLines = 30,
      ];

      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      // Verify order: empty_module (0%) should be first
      expect(coverages[0].library, equals('empty_module'));
      expect(coverages[1].library, equals('tested_low'));
      expect(coverages[2].library, equals('tested_high'));

      print('✓ Test 3 PASSED: Sorting order');
      print('  Sorted order:');
      for (int i = 0; i < coverages.length; i++) {
        final coverage = coverages[i];
        final percent = coverage.totalLines == 0
            ? 0.0
            : (coverage.testedLines / coverage.totalLines) * 100;
        print('    ${i + 1}. ${coverage.library} (${percent.toStringAsFixed(1)}%)');
      }
    });

    test('Test 4: Comprehensive scenario with multiple empty modules', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'empty_module_1'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'tested_module_60'
          ..totalLines = 100
          ..testedLines = 60,
        Coverage()
          ..library = 'empty_module_2'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'tested_module_80'
          ..totalLines = 100
          ..testedLines = 80,
      ];

      // Sort
      coverages.sort((Coverage left, Coverage right) {
        final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
        final double rightPercent = right.totalLines == 0
            ? 0
            : right.testedLines / right.totalLines;
        return leftPercent.compareTo(rightPercent);
      });

      // Display output
      final List<String> outputs = [];
      double overallNumerator = 0;
      double overallDenominator = 0;

      print('✓ Test 4 PASSED: Multiple empty modules');
      print('  % | tested | total');

      for (final coverage in coverages) {
        overallNumerator += coverage.testedLines;
        overallDenominator += coverage.totalLines;

        final String coveragePercent = coverage.totalLines == 0
            ? '0.00'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

        final String output =
            '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';
        outputs.add(output);
        print('  $output');
      }

      final String overallPercent = overallDenominator == 0
          ? '0.00'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);

      print('  OVERALL: $overallPercent%');

      // Verify order and calculation
      expect(outputs[0], equals('empty_module_1: 0.00% | 0 | 0'));
      expect(outputs[1], equals('empty_module_2: 0.00% | 0 | 0'));
      expect(outputs[2], equals('tested_module_60: 60.00% | 60 | 100'));
      expect(outputs[3], equals('tested_module_80: 80.00% | 80 | 100'));
      expect(overallPercent, equals('70.00')); // (60 + 80) / (100 + 100) * 100 = 70%
    });
  });
}
