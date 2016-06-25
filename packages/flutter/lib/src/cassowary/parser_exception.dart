// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'equation_member.dart';

/// Exception thrown when attempting to create a non-linear expression.
///
/// During the creation of constraints or expressions using the overloaded
/// operators, it may be possible to end up with non-linear expressions. Such
/// expressions are not suitable for [Constraint] creation because the [Solver]
/// will reject the same. A [ParserException] is thrown when a developer tries
/// to create such an expression.
///
/// The only cases where this is possible is when trying to multiply two
/// expressions where at least one of them is not a constant expression, or,
/// when trying to divide two expressions where the divisor is not constant.
class ParserException implements Exception {
  /// Creates a new [ParserException] with a given message and a list of the
  /// offending member for debugging purposes.
  ParserException(this.message, this.members);

  /// A detailed message describing the exception.
  final String message;

  /// The members that caused the exception.
  List<EquationMember> members;

  @override
  String toString() {
    if (message == null)
      return 'Error while parsing constraint or expression';
    return 'Error: "$message" while trying to parse constraint or expression';
  }
}
