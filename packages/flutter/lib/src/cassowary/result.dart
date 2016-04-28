// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'solver.dart';

/// Return values used by methods on the cassowary [Solver].
class Result {
  const Result._(this.message, { bool isError: true }) : error = isError;

  /// The human-readable string associated with this result.
  ///
  /// This message is typically brief and intended for developers to help debug
  /// erroneous expressions.
  final String message;

  /// Whether this [Result] represents an error (true) or not (false).
  final bool error;

  static const Result success =
      const Result._('Success', isError: false);

  static const Result duplicateConstraint =
      const Result._('Duplicate constraint');

  static const Result unsatisfiableConstraint =
      const Result._('Unsatisfiable constraint');

  static const Result unknownConstraint =
      const Result._('Unknown constraint');

  static const Result duplicateEditVariable =
      const Result._('Duplicate edit variable');

  static const Result badRequiredStrength =
      const Result._('Bad required strength');

  static const Result unknownEditVariable =
      const Result._('Unknown edit variable');
}
