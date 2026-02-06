// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Produces a per-library coverage summary when fed an lcov file, sorted by
/// increasing code coverage percentage.
///
/// Usage: `dart tool/unit_coverage lcov.info`
void main(List<String> args) {
  if (args.isEmpty || args.length > 1) {
    print('Usage: dart tool/unit_coverage lcov.info');
    return;
  }
  final List<String> lines = File(args.single).readAsLinesSync();
  final coverages = <Coverage>[];
  Coverage? currentCoverage;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final String library = line.split('SF:')[1];
      currentCoverage = Coverage()..library = library;
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
  coverages.sort((Coverage left, Coverage right) {
    // Avoid divide by zero by returning early if both have zero lines
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
  double overallNumerator = 0;
  double overallDenominator = 0;
  print('% | tested | total');
  for (final coverage in coverages) {
    overallNumerator += coverage.testedLines;
    overallDenominator += coverage.totalLines;
    // Avoid divide by zero when calculating individual coverage percentage
    final String coveragePercent = coverage.totalLines == 0
        ? 'N/A'
        : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
    print(
      '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}',
    );
  }
  // Avoid divide by zero when calculating overall coverage percentage
  final String overallPercent = overallDenominator == 0
      ? 'N/A'
      : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);
  print('OVERALL: $overallPercent%');
}

class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}
