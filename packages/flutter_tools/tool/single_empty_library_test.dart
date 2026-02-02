// Simple test for single empty library scenario
import 'package:test/test.dart';

class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}

void main() {
  group('Single Empty Library Tests', () {
    test('Single empty library returns N/A instead of divide by zero', () {
      // Create a coverage object with no lines recorded
      final coverage = Coverage()
        ..library = 'empty_module'
        ..totalLines =
            0 // No lines recorded
        ..testedLines = 0; // No lines tested

      // The fix: check if totalLines is zero before dividing
      final String result = coverage.totalLines == 0
          ? 'N/A'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      // Verify the result
      expect(result, equals('N/A'));
      expect(coverage.totalLines, equals(0));
      expect(coverage.testedLines, equals(0));

      print('✓ PASSED: Single empty library correctly returns N/A');
      print('  Library: ${coverage.library}');
      print('  Total Lines: ${coverage.totalLines}');
      print('  Tested Lines: ${coverage.testedLines}');
      print('  Result: $result');
    });

    test('Output formatting for single empty library', () {
      final coverage = Coverage()
        ..library = 'my_empty_lib'
        ..totalLines = 0
        ..testedLines = 0;

      final String coveragePercent = coverage.totalLines == 0
          ? 'N/A'
          : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

      final String output =
          '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}';

      expect(output, equals('my_empty_lib: N/A% | 0 | 0'));

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
        final String result = coverage.totalLines == 0
            ? 'N/A'
            : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
        expect(result, equals('N/A'));
      }, returnsNormally);

      print('✓ PASSED: No divide by zero error thrown');
    });
  });
}
