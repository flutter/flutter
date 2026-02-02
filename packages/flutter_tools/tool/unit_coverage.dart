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
  final List<Coverage> coverages = parseLcovLines(lines);
  sortCoveragesByPercent(coverages);

  print('% | tested | total');
  for (final coverage in coverages) {
    print(
      '${coverage.library}: ${formatCoveragePercent(coverage)}% | ${coverage.testedLines} | ${coverage.totalLines}',
    );
  }

  print('OVERALL: ${formatOverallPercent(coverages)}%');
}

List<Coverage> parseLcovLines(List<String> lines) {
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

  return coverages;
}

void sortCoveragesByPercent(List<Coverage> coverages) {
  coverages.sort((Coverage left, Coverage right) {
    final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
    final double rightPercent = right.totalLines == 0 ? 0 : right.testedLines / right.totalLines;
    return leftPercent.compareTo(rightPercent);
  });
}

String formatCoveragePercent(Coverage coverage) {
  if (coverage.totalLines == 0) {
    return '0.00';
  }
  return (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
}

String formatOverallPercent(List<Coverage> coverages) {
  double overallNumerator = 0;
  double overallDenominator = 0;
  for (final coverage in coverages) {
    overallNumerator += coverage.testedLines;
    overallDenominator += coverage.totalLines;
  }
  if (overallDenominator == 0) {
    return '0.00';
  }
  return (overallNumerator / overallDenominator * 100).toStringAsFixed(2);
}

class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}
