// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'intersect_empty.dart';
import 'profile.dart' as profile;
import 'space.dart';
import 'static_type.dart';

/// Recursively replaces [left] with a union of its sealed subtypes as long as
/// doing so enables it to more precisely match against [right].
List<StaticType> expandType(StaticType left, StaticType right) {
  // If [left] is nullable and right is null or non-nullable, then expand the
  // nullable type.
  if (left.isNullable && (right == StaticType.nullType || !right.isNullable)) {
    return [...expandType(left.underlying, right), StaticType.nullType];
  }

  // If [right] is nullable, then expand using its underlying type.
  if (right.isNullable) {
    return expandType(left, right.underlying);
  }

  // If [left] is a sealed supertype and [right] is in its subtype hierarchy,
  // then expand out the subtypes (recursively) to more precisely match [right].
  if (left.isSealed && left != right && right.isSubtypeOf(left)) {
    return {
      for (StaticType subtype in left.subtypes) ...expandType(subtype, right),
    }.toList();
  }

  return [left];
}

/// Returns a new [Space] that contains all of the values of [left] that are
/// not also in [right].
Space subtract(Space left, Space right) {
  profile.count('subtract');

  // Subtracting from empty is still empty.
  if (left == Space.empty) return Space.empty;

  // Subtracting nothing leaves it unchanged.
  if (right == Space.empty) return left;

  // Distribute a union on the left.
  // A|B - x => A-x | B-x
  if (left is UnionSpace) {
    return new Space.union(
        left.arms.map((arm) => subtract(arm, right)).toList());
  }

  // Distribute a union on the right.
  // x - A|B => x - A - B
  if (right is UnionSpace) {
    Space result = left;
    for (Space arm in right.arms) {
      result = subtract(result, arm);
    }
    return result;
  }

  // Otherwise, it must be two extract spaces.
  return _subtractExtract(left as ExtractSpace, right as ExtractSpace);
}

/// Returns `true` if every field in [leftFields] is covered by the
/// corresponding field in [rightFields].
bool _isLeftSubspace(StaticType leftType, List<String> fieldNames,
    Map<String, Space> leftFields, Map<String, Space> rightFields) {
  for (String name in fieldNames) {
    if (subtract(leftFields[name]!, rightFields[name]!) != Space.empty) {
      return false;
    }
  }

  // If we get here, every field covered.
  return true;
}

/// Subtract [right] from [left].
Space _subtractExtract(ExtractSpace left, ExtractSpace right) {
  List<String> fieldNames =
      {...left.fields.keys, ...right.fields.keys}.toList();

  List<Space> spaces = <Space>[];

  // If the left type is in a sealed hierarchy, expanding it to its subtypes
  // might let us calculate the subtraction more precisely.
  List<StaticType> subtypes = expandType(left.type, right.type);
  for (StaticType subtype in subtypes) {
    spaces.addAll(_subtractExtractAtType(subtype, left, right, fieldNames));
  }

  return new Space.union(spaces);
}

/// Subtract [right] from [left], but using [type] for left's type, which may
/// be a more specific subtype of [left]'s own type is a sealed supertype.
List<Space> _subtractExtractAtType(StaticType type, ExtractSpace left,
    ExtractSpace right, List<String> fieldNames) {
  // If the right type doesn't cover the left (even after expanding sealed
  // types), then we can't do anything with the fields since they may not
  // even come into play for all values. Subtract nothing from this subtype
  // and keep all of the current fields.
  if (!type.isSubtypeOf(right.type)) return [new Space(type, left.fields)];

  // Infer any fields that appear in one space and not the other.
  Map<String, Space> leftFields = <String, Space>{};
  Map<String, Space> rightFields = <String, Space>{};
  for (String name in fieldNames) {
    // If the right space matches on a field that the left doesn't have, infer
    // it from the static type of the field. That contains the same set of
    // values as having no field at all.
    leftFields[name] = left.fields[name] ?? new Space(type.fields[name]!);

    // If the left matches on a field that the right doesn't have, infer top
    // for the right field since the right will accept any of left's values for
    // that field.
    rightFields[name] = right.fields[name] ?? Space.top;
  }

  // If any pair of fields have no overlapping values, then no overall value
  // that matches the left space will also match the right space. So the right
  // space doesn't subtract anything and we keep the left space as-is.
  for (String name in fieldNames) {
    if (intersectEmpty(leftFields[name]!, rightFields[name]!)) {
      return [new Space(type, left.fields)];
    }
  }

  // If all the right's fields strictly cover all of the left's, then the
  // right completely subtracts this type and nothing remains.
  if (_isLeftSubspace(type, fieldNames, leftFields, rightFields)) {
    return const [];
  }

  // The right side is a supertype but its fields don't totally cover, so
  // handle each of them individually.

  // Walk the fields and see which ones are modified by the right-hand fields.
  Map<String, Space> fixed = <String, Space>{};
  Map<String, Space> changedDifference = <String, Space>{};
  for (String name in fieldNames) {
    Space difference = subtract(leftFields[name]!, rightFields[name]!);
    if (difference == Space.empty) {
      // The right field accepts all the values that the left field accepts, so
      // keep the left field as it is.
      fixed[name] = leftFields[name]!;
    } else if (difference.isTop) {
      // If the resulting field matches everything, simply discard it since
      // it's equivalent to omitting the field.
    } else {
      changedDifference[name] = difference;
    }
  }

  // If no fields are affected by the subtraction, just return a single arm
  // with all of the fields.
  if (changedDifference.isEmpty) return [new Space(type, fixed)];

  // For each field whose `left - right` is different, include an arm that
  // includes that one difference.
  List<String> changedFields = changedDifference.keys.toList();
  List<Space> spaces = <Space>[];
  for (int i = 0; i < changedFields.length; i++) {
    Map<String, Space> fields = {...fixed};

    for (int j = 0; j < changedFields.length; j++) {
      String name = changedFields[j];
      if (i == j) {
        fields[name] = changedDifference[name]!;
      } else {
        fields[name] = leftFields[name]!;
      }
    }

    spaces.add(new Space(type, fields));
  }

  return spaces;
}
