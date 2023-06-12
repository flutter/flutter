// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'space.dart';
import 'static_type.dart';
import 'subtract.dart';

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
String reportErrors(StaticType valueType, List<Space> cases) {
  List<String> errors = <String>[];

  Space remaining = new Space(valueType);
  for (int i = 0; i < cases.length; i++) {
    // See if this case is covered by previous ones.
    if (i > 0) {
      Space previous = new Space.union(cases.sublist(0, i));
      if (subtract(cases[i], previous) == Space.empty) {
        errors.add('Case #${i + 1} ${cases[i]} is covered by $previous.');
      }
    }

    remaining = subtract(remaining, cases[i]);
  }

  if (remaining != Space.empty) {
    errors.add(
        '$valueType is not exhaustively matched by ${new Space.union(cases)}.');
  }

  return errors.join('\n');
}
