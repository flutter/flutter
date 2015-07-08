// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Result {
  final String message;
  final bool error;

  const Result(this.message, { bool isError: true }) : error = isError;

  static final Result success = const Result("Success", isError: false);
  static final Result unimplemented = const Result("Unimplemented");
  static final Result duplicateConstraint =
      const Result("Duplicate Constraint");
  static final Result unsatisfiableConstraint =
      const Result("Unsatisfiable Constraint");
  static final Result unknownConstraint =
      const Result("Unknown Constraint");
  static final Result duplicateEditVariable =
      const Result("Duplicate Edit Variable");
  static final Result badRequiredStrength =
      const Result("Bad Required Strength");
  static final Result unknownEditVariable =
      const Result("Unknown Edit Variable");
  static final Result internalSolverError =
      const Result("Internal Solver Error");
}
