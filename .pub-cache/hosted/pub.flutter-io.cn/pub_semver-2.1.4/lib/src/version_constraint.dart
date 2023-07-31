// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'patterns.dart';
import 'utils.dart';
import 'version.dart';
import 'version_range.dart';
import 'version_union.dart';

/// A [VersionConstraint] is a predicate that can determine whether a given
/// version is valid or not.
///
/// For example, a ">= 2.0.0" constraint allows any version that is "2.0.0" or
/// greater. Version objects themselves implement this to match a specific
/// version.
abstract class VersionConstraint {
  /// A [VersionConstraint] that allows all versions.
  static VersionConstraint any = VersionRange();

  /// A [VersionConstraint] that allows no versions -- the empty set.
  static VersionConstraint empty = const _EmptyVersion();

  /// Parses a version constraint.
  ///
  /// This string is one of:
  ///
  ///   * "any". [any] version.
  ///   * "^" followed by a version string. Versions compatible with
  ///     ([VersionConstraint.compatibleWith]) the version.
  ///   * a series of version parts. Each part can be one of:
  ///     * A version string like `1.2.3`. In other words, anything that can be
  ///       parsed by [Version.parse()].
  ///     * A comparison operator (`<`, `>`, `<=`, or `>=`) followed by a
  ///       version string.
  ///
  /// Whitespace is ignored.
  ///
  /// Examples:
  ///
  ///     any
  ///     ^0.7.2
  ///     ^1.0.0-alpha
  ///     1.2.3-alpha
  ///     <=5.1.4
  ///     >2.0.4 <= 2.4.6
  factory VersionConstraint.parse(String text) {
    var originalText = text;

    void skipWhitespace() {
      text = text.trim();
    }

    skipWhitespace();

    // Handle the "any" constraint.
    if (text == 'any') return any;

    // Try to parse and consume a version number.
    Version? matchVersion() {
      var version = startVersion.firstMatch(text);
      if (version == null) return null;

      text = text.substring(version.end);
      return Version.parse(version[0]!);
    }

    // Try to parse and consume a comparison operator followed by a version.
    VersionRange? matchComparison() {
      var comparison = startComparison.firstMatch(text);
      if (comparison == null) return null;

      var op = comparison[0];
      text = text.substring(comparison.end);
      skipWhitespace();

      var version = matchVersion();
      if (version == null) {
        throw FormatException('Expected version number after "$op" in '
            '"$originalText", got "$text".');
      }

      switch (op) {
        case '<=':
          return VersionRange(max: version, includeMax: true);
        case '<':
          return VersionRange(max: version, alwaysIncludeMaxPreRelease: true);
        case '>=':
          return VersionRange(min: version, includeMin: true);
        case '>':
          return VersionRange(min: version);
      }
      throw UnsupportedError(op!);
    }

    // Try to parse the "^" operator followed by a version.
    VersionConstraint? matchCompatibleWith() {
      if (!text.startsWith(compatibleWithChar)) return null;

      text = text.substring(compatibleWithChar.length);
      skipWhitespace();

      var version = matchVersion();
      if (version == null) {
        throw FormatException('Expected version number after '
            '"$compatibleWithChar" in "$originalText", got "$text".');
      }

      if (text.isNotEmpty) {
        throw FormatException('Cannot include other constraints with '
            '"$compatibleWithChar" constraint in "$originalText".');
      }

      return VersionConstraint.compatibleWith(version);
    }

    var compatibleWith = matchCompatibleWith();
    if (compatibleWith != null) return compatibleWith;

    Version? min;
    var includeMin = false;
    Version? max;
    var includeMax = false;

    for (;;) {
      skipWhitespace();

      if (text.isEmpty) break;

      var newRange = matchVersion() ?? matchComparison();
      if (newRange == null) {
        throw FormatException('Could not parse version "$originalText". '
            'Unknown text at "$text".');
      }

      if (newRange.min != null) {
        if (min == null || newRange.min! > min) {
          min = newRange.min;
          includeMin = newRange.includeMin;
        } else if (newRange.min == min && !newRange.includeMin) {
          includeMin = false;
        }
      }

      if (newRange.max != null) {
        if (max == null || newRange.max! < max) {
          max = newRange.max;
          includeMax = newRange.includeMax;
        } else if (newRange.max == max && !newRange.includeMax) {
          includeMax = false;
        }
      }
    }

    if (min == null && max == null) {
      throw const FormatException('Cannot parse an empty string.');
    }

    if (min != null && max != null) {
      if (min > max) return VersionConstraint.empty;
      if (min == max) {
        if (includeMin && includeMax) return min;
        return VersionConstraint.empty;
      }
    }

    return VersionRange(
        min: min, includeMin: includeMin, max: max, includeMax: includeMax);
  }

  /// Creates a version constraint which allows all versions that are
  /// backward compatible with [version].
  ///
  /// Versions are considered backward compatible with [version] if they
  /// are greater than or equal to [version], but less than the next breaking
  /// version ([Version.nextBreaking]) of [version].
  factory VersionConstraint.compatibleWith(Version version) =>
      CompatibleWithVersionRange(version);

  /// Creates a new version constraint that is the intersection of
  /// [constraints].
  ///
  /// It only allows versions that all of those constraints allow. If
  /// constraints is empty, then it returns a VersionConstraint that allows
  /// all versions.
  factory VersionConstraint.intersection(
      Iterable<VersionConstraint> constraints) {
    var constraint = VersionRange();
    for (var other in constraints) {
      constraint = constraint.intersect(other) as VersionRange;
    }
    return constraint;
  }

  /// Creates a new version constraint that is the union of [constraints].
  ///
  /// It allows any versions that any of those constraints allows. If
  /// [constraints] is empty, this returns a constraint that allows no versions.
  factory VersionConstraint.unionOf(Iterable<VersionConstraint> constraints) {
    var flattened = constraints.expand((constraint) {
      if (constraint.isEmpty) return <VersionRange>[];
      if (constraint is VersionUnion) return constraint.ranges;
      if (constraint is VersionRange) return [constraint];
      throw ArgumentError('Unknown VersionConstraint type $constraint.');
    }).toList();

    if (flattened.isEmpty) return VersionConstraint.empty;

    if (flattened.any((constraint) => constraint.isAny)) {
      return VersionConstraint.any;
    }

    flattened.sort();

    var merged = <VersionRange>[];
    for (var constraint in flattened) {
      // Merge this constraint with the previous one, but only if they touch.
      if (merged.isEmpty ||
          (!merged.last.allowsAny(constraint) &&
              !areAdjacent(merged.last, constraint))) {
        merged.add(constraint);
      } else {
        merged[merged.length - 1] =
            merged.last.union(constraint) as VersionRange;
      }
    }

    if (merged.length == 1) return merged.single;
    return VersionUnion.fromRanges(merged);
  }

  /// Returns `true` if this constraint allows no versions.
  bool get isEmpty;

  /// Returns `true` if this constraint allows all versions.
  bool get isAny;

  /// Returns `true` if this constraint allows [version].
  bool allows(Version version);

  /// Returns `true` if this constraint allows all the versions that [other]
  /// allows.
  bool allowsAll(VersionConstraint other);

  /// Returns `true` if this constraint allows any of the versions that [other]
  /// allows.
  bool allowsAny(VersionConstraint other);

  /// Returns a [VersionConstraint] that only allows [Version]s allowed by both
  /// this and [other].
  VersionConstraint intersect(VersionConstraint other);

  /// Returns a [VersionConstraint] that allows [Version]s allowed by either
  /// this or [other].
  VersionConstraint union(VersionConstraint other);

  /// Returns a [VersionConstraint] that allows [Version]s allowed by this but
  /// not [other].
  VersionConstraint difference(VersionConstraint other);
}

class _EmptyVersion implements VersionConstraint {
  const _EmptyVersion();

  @override
  bool get isEmpty => true;

  @override
  bool get isAny => false;

  @override
  bool allows(Version other) => false;

  @override
  bool allowsAll(VersionConstraint other) => other.isEmpty;

  @override
  bool allowsAny(VersionConstraint other) => false;

  @override
  VersionConstraint intersect(VersionConstraint other) => this;

  @override
  VersionConstraint union(VersionConstraint other) => other;

  @override
  VersionConstraint difference(VersionConstraint other) => this;

  @override
  String toString() => '<empty>';
}
