// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'space.dart';
import 'static_type.dart';
import 'subtract.dart';
import 'witness.dart';

/// Returns `true` if [cases] exhaustively covers all possible values of
/// [value].
///
/// This is defined simply in terms of subtraction and unions: [cases] is a
/// union space, and it's exhaustive if subtracting it from [value] leaves
/// nothing.
bool isExhaustive(Space value, List<Space> cases) {
  return subtract(value, new Space.union(cases)) == Space.empty;
}

/// Checks the [cases] representing a series of switch cases to see if they
/// exhaustively cover all possible values of the matched [valueType]. Also
/// checks to see if any case can't be matched because it's covered by previous
/// cases.
///
/// Returns a string containing any unreachable case or non-exhaustive match
/// errors. Returns an empty string if all cases are reachable and the cases
/// are exhaustive.

List<ExhaustivenessError> reportErrors(StaticType valueType, List<Space> cases,
    [List<Space>? remainingSpaces]) {
  return reportErrorsNew(valueType, cases);
}

List<ExhaustivenessError> reportErrorsOld(
    StaticType valueType, List<Space> cases,
    [List<Space>? remainingSpaces]) {
  List<ExhaustivenessError> errors = <ExhaustivenessError>[];

  Space remaining = new Space(valueType);
  for (int i = 0; i < cases.length; i++) {
    // See if this case is covered by previous ones.
    if (i > 0) {
      Space previous = new Space.union(cases.sublist(0, i));
      if (subtract(cases[i], previous) == Space.empty) {
        errors.add(new UnreachableCaseErrorOld(valueType, cases, i, previous));
      }
    }

    remainingSpaces?.add(remaining);
    remaining = subtract(remaining, cases[i]);
  }
  remainingSpaces?.add(remaining);

  if (remaining != Space.empty) {
    errors.add(new NonExhaustiveErrorOld(valueType, cases, remaining));
  }

  return errors;
}

class ExhaustivenessError {}

abstract class NonExhaustiveError implements ExhaustivenessError {
  StaticType get valueType;
  List<Space> get cases;
  String get witness;
}

class NonExhaustiveErrorNew implements NonExhaustiveError {
  @override
  final StaticType valueType;

  @override
  final List<Space> cases;

  @override
  final String witness;

  NonExhaustiveErrorNew(this.valueType, this.cases, this.witness);

  @override
  String toString() =>
      '$valueType is not exhaustively matched by ${new Space.union(cases)}.';
}

class NonExhaustiveErrorOld implements NonExhaustiveError {
  @override
  final StaticType valueType;

  @override
  final List<Space> cases;

  final Space remaining;

  NonExhaustiveErrorOld(this.valueType, this.cases, this.remaining);

  @override
  String get witness => '$remaining';

  @override
  String toString() =>
      '$valueType is not exhaustively matched by ${new Space.union(cases)}.';
}

abstract class UnreachableCaseError implements ExhaustivenessError {
  StaticType get valueType;
  List<Space> get cases;
  int get index;
}

class UnreachableCaseErrorNew implements UnreachableCaseError {
  @override
  final StaticType valueType;
  @override
  final List<Space> cases;
  @override
  final int index;

  UnreachableCaseErrorNew(this.valueType, this.cases, this.index);

  @override
  String toString() => 'Case #${index + 1} ${cases[index]} is unreachable.';
}

class UnreachableCaseErrorOld implements UnreachableCaseError {
  @override
  final StaticType valueType;
  @override
  final List<Space> cases;
  @override
  final int index;
  final Space previous;

  UnreachableCaseErrorOld(
      this.valueType, this.cases, this.index, this.previous);

  @override
  String toString() =>
      'Case #${index + 1} ${cases[index]} is covered by $previous.';
}
