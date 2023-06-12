// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'space.dart';
import 'static_type.dart';

/// Calculates whether the intersection of [left] and [right] is empty.
///
/// This is used to tell if two field spaces on a pair of spaces being
/// subtracted have no common values.
bool intersectEmpty(Space left, Space right) {
  // The intersection with an empty space is always empty.
  if (left == Space.empty) return true;
  if (right == Space.empty) return true;

  // The intersection of a union is empty if all of the arms are.
  if (left is UnionSpace) {
    return left.arms.every((arm) => intersectEmpty(arm, right));
  }

  if (right is UnionSpace) {
    return right.arms.every((arm) => intersectEmpty(left, arm));
  }

  // Otherwise, we're intersecting two [ExtractSpaces].
  return _intersectExtracts(left as ExtractSpace, right as ExtractSpace);
}

/// Returns true if the intersection of two static types [left] and [right] is
/// empty.
bool intersectTypes(StaticType left, StaticType right) {
  // If one type is a subtype, the subtype is the intersection.
  if (left.isSubtypeOf(right)) return false;
  if (right.isSubtypeOf(left)) return false;

  // Unrelated types.
  return true;
}

/// Returns the interaction of extract spaces [left] and [right].
bool _intersectExtracts(ExtractSpace left, ExtractSpace right) {
  if (intersectTypes(left.type, right.type)) return true;

  // Recursively intersect the fields.
  List<String> fieldNames =
      {...left.fields.keys, ...right.fields.keys}.toList();
  for (String name in fieldNames) {
    // If the fields are disjoint, then the entire space will have no values.
    if (_intersectFields(left.fields[name], right.fields[name])) return true;
  }

  return false;
}

bool _intersectFields(Space? left, Space? right) {
  if (left == null) return right! == Space.empty;
  if (right == null) return left == Space.empty;
  return intersectEmpty(left, right);
}
