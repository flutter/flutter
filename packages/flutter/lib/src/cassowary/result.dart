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

  /// The result when the operation was successful.
  static const Result success =
      const Result._('Success', isError: false);

  /// The result when the [Constraint] could not be added to the [Solver]
  /// because it was already present in the solver.
  static const Result duplicateConstraint =
      const Result._('Duplicate constraint');

  /// The result when the [Constraint] could not be added to the [Solver]
  /// because it was unsatisfiable. Try lowering the [Priority] of the
  /// [Constraint] and try again.
  static const Result unsatisfiableConstraint =
      const Result._('Unsatisfiable constraint');

  /// The result when the [Constraint] could not be removed from the solver
  /// because it was not present in the [Solver] to begin with.
  static const Result unknownConstraint =
      const Result._('Unknown constraint');

  /// The result when could not add the edit [Variable] to the [Solver] because
  /// it was already added to the [Solver] previously.
  static const Result duplicateEditVariable =
      const Result._('Duplicate edit variable');

  /// The result when the [Constraint] constraint was added at an invalid
  /// priority or an edit [Variable] was added at an invalid or required
  /// priority.
  static const Result badRequiredStrength =
      const Result._('Bad required strength');

  /// The result when the edit [Variable] could not be removed from the solver
  /// because it was not present in the [Solver] to begin with.
  static const Result unknownEditVariable =
      const Result._('Unknown edit variable');
}
