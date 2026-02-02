// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'unit_coverage.dart';

void main() {
  group('unit_coverage core functions', () {
    test('parseLcovLines and formatCoveragePercent handle empty library', () {
      final lines = <String>['SF:lib/empty.dart', 'end_of_record'];
      final coverages = parseLcovLines(lines);
      expect(coverages.length, equals(1));
      expect(formatCoveragePercent(coverages.first), equals('0.00'));
    });

    test('formatCoveragePercent formats non-zero correctly', () {
      final coverage = Coverage()
        ..library = 'lib'
        ..totalLines = 100
        ..testedLines = 75;
      expect(formatCoveragePercent(coverage), equals('75.00'));
    });

    test('sortCoveragesByPercent orders by increasing percent', () {
      final a = Coverage()
        ..library = 'a'
        ..totalLines = 0
        ..testedLines = 0;
      final b = Coverage()
        ..library = 'b'
        ..totalLines = 100
        ..testedLines = 50;
      final c = Coverage()
        ..library = 'c'
        ..totalLines = 100
        ..testedLines = 80;
      final list = <Coverage>[c, a, b];
      sortCoveragesByPercent(list);
      expect(list[0].library, equals('a'));
      expect(list[1].library, equals('b'));
      expect(list[2].library, equals('c'));
    });

    test('formatOverallPercent handles zero denominator', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'x'
          ..totalLines = 0
          ..testedLines = 0,
        Coverage()
          ..library = 'y'
          ..totalLines = 0
          ..testedLines = 0,
      ];
      expect(formatOverallPercent(coverages), equals('0.00'));
    });

    test('formatOverallPercent calculates weighted percent', () {
      final coverages = <Coverage>[
        Coverage()
          ..library = 'x'
          ..totalLines = 100
          ..testedLines = 80,
        Coverage()
          ..library = 'y'
          ..totalLines = 50
          ..testedLines = 40,
      ];
      // (80 + 40) / (100 + 50) * 100 = 80.00
      expect(formatOverallPercent(coverages), equals('80.00'));
    });
  });
}
