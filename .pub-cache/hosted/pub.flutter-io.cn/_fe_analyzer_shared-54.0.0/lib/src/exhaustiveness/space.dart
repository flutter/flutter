// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'equal.dart';
import 'static_type.dart';

/// The main space for matching types and destructuring.
///
/// It has a type which determines the type of values it contains. The type may
/// be [StaticType.nullableObject] to indicate that it doesn't filter by type.
///
/// It may also contain zero or more named fields. The space then only contains
/// values where the field values are contained by the corresponding field
/// spaces.
class ExtractSpace extends Space {
  /// The type of values the space matches.
  final StaticType type;

  /// Any field subspaces the space matches.
  final Map<String, Space> fields;

  ExtractSpace._(this.type, [this.fields = const {}]) : super._();

  /// An [ExtractSpace] with no type and no fields contains all values.
  @override
  bool get isTop => type == StaticType.nullableObject && fields.isEmpty;

  @override
  String toString() {
    if (isTop) return '()';
    if (this == Space.empty) return '∅';

    if (type.isRecord) {
      StringBuffer buffer = new StringBuffer();
      buffer.write('(');
      bool first = true;
      type.fields.forEach((String name, StaticType staticType) {
        if (!first) buffer.write(', ');
        // TODO(johnniwinther): Ensure using Dart syntax for positional fields.
        buffer.write('$name: ${fields[name] ?? staticType}');
        first = false;
      });

      buffer.write(')');
      return buffer.toString();
    } else {
      // If there are no fields, just show the type.
      if (fields.isEmpty) return type.name;

      StringBuffer buffer = new StringBuffer();
      buffer.write(type.name);

      buffer.write('(');
      bool first = true;

      fields.forEach((String name, Space space) {
        if (!first) buffer.write(', ');
        buffer.write('$name: $space');
        first = false;
      });

      buffer.write(')');
      return buffer.toString();
    }
  }
}

// TODO(paulberry, rnystrom): List spaces.

abstract class Space {
  /// The uninhabited space.
  static final Space empty = new Space(StaticType.neverType);

  /// The space containing everything.
  static final Space top = new Space(StaticType.nullableObject);

  /// The space containing only `null`.
  static final Space nullSpace = new Space(StaticType.nullType);

  factory Space(StaticType type, [Map<String, Space> fields = const {}]) =>
      new ExtractSpace._(type, fields);

  factory Space.union(List<Space> arms) {
    // Simplify the arms if possible.
    List<ExtractSpace> allArms = <ExtractSpace>[];

    void addSpace(ExtractSpace space) {
      // Discard duplicate arms. Duplicates can appear when working through a
      // series of cases that destructure multiple fields with different types.
      // Discarding the duplicates isn't necessary for correctness (a union with
      // redundant arms contains the same set of values), but improves
      // performance greatly. In the "sealed subtypes large T with all cases"
      // test, you end up with a union containing 2520 arms, 2488 are
      // duplicates. With this check, the largest union has only 5 arms.
      //
      // This is O(n^2) since we define only equality on spaces, but a real
      // implementation would likely define hash code too and then simply
      // create a hash set to merge duplicates in O(n) time.
      for (Space existing in allArms) {
        if (equal(existing, space, 'dedupe union')) return;
      }

      allArms.add(space);
    }

    for (Space space in arms) {
      // Discard empty arms.
      if (space == empty) continue;

      // Flatten unions. We don't need to flatten recursively since we always
      // go through this constructor to create unions. A UnionSpace will never
      // contain UnionSpaces.
      if (space is UnionSpace) {
        for (ExtractSpace arm in space.arms) {
          addSpace(arm);
        }
      } else {
        addSpace(space as ExtractSpace);
      }
    }

    if (allArms.isEmpty) return empty;
    if (allArms.length == 1) return allArms.first;
    if (allArms.length == 2) {
      if (allArms[0].type == StaticType.nullType &&
          allArms[0].fields.isEmpty &&
          allArms[1].fields.isEmpty) {
        return new Space(allArms[1].type.nullable);
      } else if (allArms[1].type == StaticType.nullType &&
          allArms[1].fields.isEmpty &&
          allArms[0].fields.isEmpty) {
        return new Space(allArms[0].type.nullable);
      }
    }
    return new UnionSpace._(allArms);
  }

  Space._();

  /// An untyped record space with no fields matches all values and thus isn't
  /// very useful.
  bool get isTop => false;
}

/// A union of spaces. The space A|B contains all of the values of A and B.
class UnionSpace extends Space {
  final List<ExtractSpace> arms;

  UnionSpace._(this.arms) : super._() {
    assert(arms.length > 1);
  }

  @override
  String toString() => arms.join('|');
}
