// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Shared test helpers for unit_coverage tests
class Coverage {
  String? library;
  int totalLines = 0;
  int testedLines = 0;
}

String formatCoveragePercent(Coverage coverage) {
  return coverage.totalLines == 0
      ? '0.00'
      : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);
}
