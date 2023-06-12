// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'profile.dart' as profile;
import 'space.dart';

/// Returns `true` if [left] and [right] are equivalent spaces.
///
/// Equality is defined purely structurally/syntactically.
bool equal(Space left, Space right, String reason) {
  profile.count('equal', reason);

  if (identical(left, right)) return true;

  // Empty is only equal to itself (and will get caught by the previous check).
  if (left == Space.empty) return false;
  if (right == Space.empty) return false;

  if (left is UnionSpace && right is UnionSpace) {
    return _equalUnions(left, right);
  }

  if (left is ExtractSpace && right is ExtractSpace) {
    return _equalExtracts(left, right);
  }

  // If we get here, one is a union and one is an extract.
  return false;
}

/// Returns `true` if [left] and [right] have the same type and the same fields
/// with equal subspaces.
bool _equalExtracts(ExtractSpace left, ExtractSpace right) {
  // Must have the same type.
  if (left.type != right.type) return false;

  // And the same fields.
  Set<String> fields = {...left.fields.keys, ...right.fields.keys};
  if (left.fields.length != fields.length) return false;
  if (right.fields.length != fields.length) return false;

  for (String field in fields) {
    if (!equal(left.fields[field]!, right.fields[field]!, 'recurse extract')) {
      return false;
    }
  }

  return true;
}

/// Returns `true` if [left] and [right] contain equal arms in any order.
///
/// Assumes that all duplicates have already been removed from each union.
bool _equalUnions(UnionSpace left, UnionSpace right) {
  if (left.arms.length != right.arms.length) return false;

  /// For each left arm, should find an equal right arm.
  for (Space leftArm in left.arms) {
    bool found = false;
    for (Space rightArm in right.arms) {
      if (equal(leftArm, rightArm, 'recurse union')) {
        found = true;
        break;
      }
    }
    if (!found) return false;
  }

  return true;
}
