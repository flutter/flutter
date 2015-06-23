// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Result {
  final bool error;
  final String message;

  const Result(this.message, this.error);

  static final Result success = const Result("Success", false);
  static final Result unimplemented = const Result("Unimplemented", true);
  static final Result duplicateConstraint =
      const Result("Duplicate Constraint", true);
  static final Result unsatisfiableConstraint =
      const Result("Unsatisfiable Constraint", true);
  static final Result unknownConstraint =
      const Result("Unknown Constraint", true);
  static final Result duplicateEditVariable =
      const Result("Duplicate Edit Variable", true);
  static final Result badRequiredStrength =
      const Result("Bad Required Strength", true);
  static final Result unknownEditVariable =
      const Result("Unknown Edit Variable", true);
  static final Result internalSolverError =
      const Result("Internal Solver Error", true);
}
