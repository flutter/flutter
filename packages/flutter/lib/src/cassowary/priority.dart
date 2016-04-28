// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

/// Utility functions for managing cassowary priorities.
///
/// Priorities in cassowary expressions are internally expressed as a number
/// between 0 and 1,000,000,000. These numbers can be created by using the
/// [Priority.create] static method.
class Priority {
  /// The priority level that, by convention, is the highest allowed priority level (1,000,000,000).
  static final double required = create(1e3, 1e3, 1e3);

  /// A priority level that is below the [required] level but still near it (1,000,000).
  static final double strong = create(1.0, 0.0, 0.0);

  /// A priority level logarithmically in the middle of [strong] and [weak] (1,000).
  static final double medium = create(0.0, 1.0, 0.0);

  /// A priority level that, by convention, is the lowest allowed priority level (1).
  static final double weak = create(0.0, 0.0, 1.0);

  /// Computes a priority level by combining three numbers in the range 0..1000.
  ///
  /// The first number is a multiple of [strong].
  ///
  /// The second number is a multiple of [medium].
  ///
  /// The third number is a multiple of [weak].
  ///
  /// By convention, at least one of these numbers should be equal to or greater than 1.
  static double create(double a, double b, double c) {
    double result = 0.0;
    result += max(0.0, min(1e3, a)) * 1e6;
    result += max(0.0, min(1e3, b)) * 1e3;
    result += max(0.0, min(1e3, c));
    return result;
  }
}
