// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'equal.dart';
import 'static_type.dart';

/// The main space for matching types and destructuring.
///
/// It has a type which determines the type of values it contains. The type may
/// be [StaticType.top] to indicate that it doesn't filter by type.
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
  bool get isTop => type == StaticType.top && fields.isEmpty;

  @override
  String toString() {
    if (isTop) return '()';

    // If there are no fields, just show the type.
    if (fields.isEmpty) return type.name;

    StringBuffer buffer = new StringBuffer();

    // We model a bare record pattern by treating it like an extractor on top.
    if (type != StaticType.top) buffer.write(type.name);

    buffer.write('(');
    bool first = true;

    // Positional fields have stringified number names.
    for (int i = 0;; i++) {
      Space? pattern = fields[i.toString()];
      if (pattern == null) break;

      if (!first) buffer.write(', ');
      buffer.write(pattern);
      first = false;
    }

    fields.forEach((name, pattern) {
      // Skip positional fields.
      if (int.tryParse(name) != null) return;

      if (!first) buffer.write(', ');
      buffer.write('$name: $pattern');
      first = false;
    });

    buffer.write(')');

    return buffer.toString();
  }
}

// TODO(paulberry, rnystrom): List spaces.

abstract class Space {
  static final _EmptySpace empty = new _EmptySpace._();
  static final Space top = new Space(StaticType.top);

  factory Space(StaticType type, [Map<String, Space> fields = const {}]) =>
      new ExtractSpace._(type, fields);

  factory Space.record([Map<String, Space> fields = const {}]) =>
      new Space(StaticType.top, fields);

  factory Space.union(List<Space> arms) {
    // Simplify the arms if possible.
    List<Space> allArms = <Space>[];

    void addSpace(Space space) {
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
        for (Space arm in space.arms) {
          addSpace(arm);
        }
      } else {
        addSpace(space);
      }
    }

    if (allArms.isEmpty) return empty;
    if (allArms.length == 1) return allArms.first;
    return new UnionSpace._(allArms);
  }

  Space._();

  /// An untyped record space with no fields matches all values and thus isn't
  /// very useful.
  bool get isTop => false;
}

/// A union of spaces. The space A|B contains all of the values of A and B.
class UnionSpace extends Space {
  final List<Space> arms;

  UnionSpace._(this.arms) : super._() {
    assert(arms.length > 1);
  }

  @override
  String toString() => arms.join('|');
}

/// The uninhabited space.
class _EmptySpace extends Space {
  _EmptySpace._() : super._();

  @override
  String toString() => '∅';
}
