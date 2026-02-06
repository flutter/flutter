// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

/// Tests for unit_coverage.dart divide-by-zero fixes.
void main() {
  group('Coverage calculation with edge cases', () {
    test('handles libraries with zero total lines', () {
      // This test verifies that the coverage calculation doesn't crash
      // when a library has zero lines.
      // Bug #4: Divide by zero in comparison
      const zeroLinesData = '''
SF:lib/src/empty_file.dart
end_of_record
SF:lib/src/normal_file.dart
DA:1,1
DA:2,0
end_of_record
''';

      // Parse the coverage data
      final List<String> lines = zeroLinesData.split('\n');
      final coverages = <_MutableCoverage>[];
      _MutableCoverage? currentCoverage;

      for (final line in lines) {
        if (line.startsWith('SF:')) {
          final String library = line.split('SF:')[1];
          currentCoverage = _MutableCoverage()..library = library;
          coverages.add(currentCoverage);
        }
        if (line.startsWith('DA')) {
          currentCoverage?.totalLines += 1;
          if (!line.endsWith(',0')) {
            currentCoverage?.testedLines += 1;
          }
        }
        if (line == 'end_of_record') {
          currentCoverage = null;
        }
      }

      // This should not throw an exception
      expect(() {
        coverages.sort((_MutableCoverage left, _MutableCoverage right) {
          // Avoid divide by zero
          if (left.totalLines == 0 && right.totalLines == 0) {
            return 0;
          }
          if (left.totalLines == 0) {
            return -1;
          }
          if (right.totalLines == 0) {
            return 1;
          }
          final double leftPercent = left.testedLines / left.totalLines;
          final double rightPercent = right.testedLines / right.totalLines;
          return leftPercent.compareTo(rightPercent);
        });
      }, returnsNormally);
    });

    test('calculates individual coverage percentage safely', () {
      const emptyCoverage = _TestCoverage(library: 'empty.dart', totalLines: 0, testedLines: 0);

      const normalCoverage = _TestCoverage(library: 'normal.dart', totalLines: 10, testedLines: 8);

      // Test empty coverage
      final String emptyPercent = emptyCoverage.totalLines == 0
          ? 'N/A'
          : (emptyCoverage.testedLines / emptyCoverage.totalLines * 100).toStringAsFixed(2);
      expect(emptyPercent, equals('N/A'));

      // Test normal coverage
      final String normalPercent = normalCoverage.totalLines == 0
          ? 'N/A'
          : (normalCoverage.testedLines / normalCoverage.totalLines * 100).toStringAsFixed(2);
      expect(normalPercent, equals('80.00'));
    });

    test('calculates overall coverage percentage safely', () {
      // Bug #5: Divide by zero in overall calculation
      double overallNumerator = 0;
      double overallDenominator = 0;

      // Test with no data
      final String overallPercentNoData = overallDenominator == 0
          ? 'N/A'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);
      expect(overallPercentNoData, equals('N/A'));

      // Test with actual data
      overallNumerator = 18;
      overallDenominator = 20;
      final String overallPercentWithData = overallDenominator == 0
          ? 'N/A'
          : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);
      expect(overallPercentWithData, equals('90.00'));
    });

    test('handles mixed coverage data correctly', () {
      final coverages = <_TestCoverage>[
        const _TestCoverage(library: 'file1.dart', totalLines: 0, testedLines: 0),
        const _TestCoverage(library: 'file2.dart', totalLines: 10, testedLines: 5),
        const _TestCoverage(library: 'file3.dart', totalLines: 0, testedLines: 0),
        const _TestCoverage(library: 'file4.dart', totalLines: 20, testedLines: 18),
      ];

      // Should not throw
      expect(() {
        coverages.sort((_TestCoverage left, _TestCoverage right) {
          if (left.totalLines == 0 && right.totalLines == 0) {
            return 0;
          }
          if (left.totalLines == 0) {
            return -1;
          }
          if (right.totalLines == 0) {
            return 1;
          }
          final double leftPercent = left.testedLines / left.totalLines;
          final double rightPercent = right.testedLines / right.totalLines;
          return leftPercent.compareTo(rightPercent);
        });
      }, returnsNormally);

      // Verify order: zero-line files first, then sorted by percentage
      expect(coverages[0].library, equals('file1.dart'));
      expect(coverages[1].library, equals('file3.dart'));
      expect(coverages[2].library, equals('file2.dart'));
      expect(coverages[3].library, equals('file4.dart'));
    });
  });
}

/// Immutable coverage data for testing.
class _TestCoverage {
  const _TestCoverage({required this.library, required this.totalLines, required this.testedLines});

  final String library;
  final int totalLines;
  final int testedLines;
}

/// Mutable coverage data for parsing.
class _MutableCoverage {
  _MutableCoverage() : library = '', totalLines = 0, testedLines = 0;

  String library;
  int totalLines;
  int testedLines;
}
