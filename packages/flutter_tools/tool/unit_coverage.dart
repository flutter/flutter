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
    final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
    final double rightPercent = right.totalLines == 0 ? 0 : right.testedLines / right.totalLines;
    return leftPercent.compareTo(rightPercent);
  });
  double overallNumerator = 0;
  double overallDenominator = 0;
  print('% | tested | total');
  for (final coverage in coverages) {
    overallNumerator += coverage.testedLines;
    overallDenominator += coverage.totalLines;
    final String coveragePercent = coverage.totalLines == 0
        ? '0.00'
        : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
    print(
      '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}',
    );
  }
  final String overallPercent = overallDenominator == 0
      ? '0.00'
      : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);
  print('OVERALL: $overallPercent%');
}

class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}
