// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils.dart';
import 'version.dart';
import 'version_constraint.dart';
import 'version_union.dart';

/// Constrains versions to a fall within a given range.
///
/// If there is a minimum, then this only allows versions that are at that
/// minimum or greater. If there is a maximum, then only versions less than
/// that are allowed. In other words, this allows `>= min, < max`.
///
/// Version ranges are ordered first by their lower bounds, then by their upper
/// bounds. For example, `>=1.0.0 <2.0.0` is before `>=1.5.0 <2.0.0` is before
/// `>=1.5.0 <3.0.0`.
class VersionRange implements Comparable<VersionRange>, VersionConstraint {
  /// The minimum end of the range.
  ///
  /// If [includeMin] is `true`, this will be the minimum allowed version.
  /// Otherwise, it will be the highest version below the range that is not
  /// allowed.
  ///
  /// This may be `null` in which case the range has no minimum end and allows
  /// any version less than the maximum.
  final Version? min;

  /// The maximum end of the range.
  ///
  /// If [includeMax] is `true`, this will be the maximum allowed version.
  /// Otherwise, it will be the lowest version above the range that is not
  /// allowed.
  ///
  /// This may be `null` in which case the range has no maximum end and allows
  /// any version greater than the minimum.
  final Version? max;

  /// If `true` then [min] is allowed by the range.
  final bool includeMin;

  /// If `true`, then [max] is allowed by the range.
  final bool includeMax;

  /// Creates a new version range from [min] to [max], either inclusive or
  /// exclusive.
  ///
  /// If it is an error if [min] is greater than [max].
  ///
  /// Either [max] or [min] may be omitted to not clamp the range at that end.
  /// If both are omitted, the range allows all versions.
  ///
  /// If [includeMin] is `true`, then the minimum end of the range is inclusive.
  /// Likewise, passing [includeMax] as `true` makes the upper end inclusive.
  ///
  /// If [alwaysIncludeMaxPreRelease] is `true`, this will always include
  /// pre-release versions of an exclusive [max]. Otherwise, it will use the
  /// default behavior for pre-release versions of [max].
  factory VersionRange(
      {Version? min,
      Version? max,
      bool includeMin = false,
      bool includeMax = false,
      bool alwaysIncludeMaxPreRelease = false}) {
    if (min != null && max != null && min > max) {
      throw ArgumentError(
          'Minimum version ("$min") must be less than maximum ("$max").');
    }

    if (!alwaysIncludeMaxPreRelease &&
        !includeMax &&
        max != null &&
        !max.isPreRelease &&
        max.build.isEmpty &&
        (min == null ||
            !min.isPreRelease ||
            !equalsWithoutPreRelease(min, max))) {
      max = max.firstPreRelease;
    }

    return VersionRange._(min, max, includeMin, includeMax);
  }

  VersionRange._(this.min, this.max, this.includeMin, this.includeMax);

  @override
  bool operator ==(Object other) {
    if (other is! VersionRange) return false;

    return min == other.min &&
        max == other.max &&
        includeMin == other.includeMin &&
        includeMax == other.includeMax;
  }

  @override
  int get hashCode =>
      min.hashCode ^
      (max.hashCode * 3) ^
      (includeMin.hashCode * 5) ^
      (includeMax.hashCode * 7);

  @override
  bool get isEmpty => false;

  @override
  bool get isAny => min == null && max == null;

  /// Tests if [other] falls within this version range.
  @override
  bool allows(Version other) {
    if (min != null) {
      if (other < min!) return false;
      if (!includeMin && other == min) return false;
    }

    if (max != null) {
      if (other > max!) return false;
      if (!includeMax && other == max) return false;
    }

    return true;
  }

  @override
  bool allowsAll(VersionConstraint other) {
    if (other.isEmpty) return true;
    if (other is Version) return allows(other);

    if (other is VersionUnion) {
      return other.ranges.every(allowsAll);
    }

    if (other is VersionRange) {
      return !allowsLower(other, this) && !allowsHigher(other, this);
    }

    throw ArgumentError('Unknown VersionConstraint type $other.');
  }

  @override
  bool allowsAny(VersionConstraint other) {
    if (other.isEmpty) return false;
    if (other is Version) return allows(other);

    if (other is VersionUnion) {
      return other.ranges.any(allowsAny);
    }

    if (other is VersionRange) {
      return !strictlyLower(other, this) && !strictlyHigher(other, this);
    }

    throw ArgumentError('Unknown VersionConstraint type $other.');
  }

  @override
  VersionConstraint intersect(VersionConstraint other) {
    if (other.isEmpty) return other;
    if (other is VersionUnion) return other.intersect(this);

    // A range and a Version just yields the version if it's in the range.
    if (other is Version) {
      return allows(other) ? other : VersionConstraint.empty;
    }

    if (other is VersionRange) {
      // Intersect the two ranges.
      Version? intersectMin;
      bool intersectIncludeMin;
      if (allowsLower(this, other)) {
        if (strictlyLower(this, other)) return VersionConstraint.empty;
        intersectMin = other.min;
        intersectIncludeMin = other.includeMin;
      } else {
        if (strictlyLower(other, this)) return VersionConstraint.empty;
        intersectMin = min;
        intersectIncludeMin = includeMin;
      }

      Version? intersectMax;
      bool intersectIncludeMax;
      if (allowsHigher(this, other)) {
        intersectMax = other.max;
        intersectIncludeMax = other.includeMax;
      } else {
        intersectMax = max;
        intersectIncludeMax = includeMax;
      }

      if (intersectMin == null && intersectMax == null) {
        // Open range.
        return VersionRange();
      }

      // If the range is just a single version.
      if (intersectMin == intersectMax) {
        // Because we already verified that the lower range isn't strictly
        // lower, there must be some overlap.
        assert(intersectIncludeMin && intersectIncludeMax);
        return intersectMin!;
      }

      // If we got here, there is an actual range.
      return VersionRange(
          min: intersectMin,
          max: intersectMax,
          includeMin: intersectIncludeMin,
          includeMax: intersectIncludeMax,
          alwaysIncludeMaxPreRelease: true);
    }

    throw ArgumentError('Unknown VersionConstraint type $other.');
  }

  @override
  VersionConstraint union(VersionConstraint other) {
    if (other is Version) {
      if (allows(other)) return this;

      if (other == min) {
        return VersionRange(
            min: min,
            max: max,
            includeMin: true,
            includeMax: includeMax,
            alwaysIncludeMaxPreRelease: true);
      }

      if (other == max) {
        return VersionRange(
            min: min,
            max: max,
            includeMin: includeMin,
            includeMax: true,
            alwaysIncludeMaxPreRelease: true);
      }

      return VersionConstraint.unionOf([this, other]);
    }

    if (other is VersionRange) {
      // If the two ranges don't overlap, we won't be able to create a single
      // VersionRange for both of them.
      var edgesTouch = (max != null &&
              max == other.min &&
              (includeMax || other.includeMin)) ||
          (min != null && min == other.max && (includeMin || other.includeMax));
      if (!edgesTouch && !allowsAny(other)) {
        return VersionConstraint.unionOf([this, other]);
      }

      Version? unionMin;
      bool unionIncludeMin;
      if (allowsLower(this, other)) {
        unionMin = min;
        unionIncludeMin = includeMin;
      } else {
        unionMin = other.min;
        unionIncludeMin = other.includeMin;
      }

      Version? unionMax;
      bool unionIncludeMax;
      if (allowsHigher(this, other)) {
        unionMax = max;
        unionIncludeMax = includeMax;
      } else {
        unionMax = other.max;
        unionIncludeMax = other.includeMax;
      }

      return VersionRange(
          min: unionMin,
          max: unionMax,
          includeMin: unionIncludeMin,
          includeMax: unionIncludeMax,
          alwaysIncludeMaxPreRelease: true);
    }

    return VersionConstraint.unionOf([this, other]);
  }

  @override
  VersionConstraint difference(VersionConstraint other) {
    if (other.isEmpty) return this;

    if (other is Version) {
      if (!allows(other)) return this;

      if (other == min) {
        if (!includeMin) return this;
        return VersionRange(
            min: min,
            max: max,
            includeMax: includeMax,
            alwaysIncludeMaxPreRelease: true);
      }

      if (other == max) {
        if (!includeMax) return this;
        return VersionRange(
            min: min,
            max: max,
            includeMin: includeMin,
            alwaysIncludeMaxPreRelease: true);
      }

      return VersionUnion.fromRanges([
        VersionRange(
            min: min,
            max: other,
            includeMin: includeMin,
            alwaysIncludeMaxPreRelease: true),
        VersionRange(
            min: other,
            max: max,
            includeMax: includeMax,
            alwaysIncludeMaxPreRelease: true)
      ]);
    } else if (other is VersionRange) {
      if (!allowsAny(other)) return this;

      VersionRange? before;
      if (!allowsLower(this, other)) {
        before = null;
      } else if (min == other.min) {
        assert(includeMin && !other.includeMin);
        assert(min != null);
        before = min;
      } else {
        before = VersionRange(
            min: min,
            max: other.min,
            includeMin: includeMin,
            includeMax: !other.includeMin,
            alwaysIncludeMaxPreRelease: true);
      }

      VersionRange? after;
      if (!allowsHigher(this, other)) {
        after = null;
      } else if (max == other.max) {
        assert(includeMax && !other.includeMax);
        assert(max != null);
        after = max;
      } else {
        after = VersionRange(
            min: other.max,
            max: max,
            includeMin: !other.includeMax,
            includeMax: includeMax,
            alwaysIncludeMaxPreRelease: true);
      }

      if (before == null && after == null) return VersionConstraint.empty;
      if (before == null) return after!;
      if (after == null) return before;
      return VersionUnion.fromRanges([before, after]);
    } else if (other is VersionUnion) {
      var ranges = <VersionRange>[];
      var current = this;

      for (var range in other.ranges) {
        // Skip any ranges that are strictly lower than [current].
        if (strictlyLower(range, current)) continue;

        // If we reach a range strictly higher than [current], no more ranges
        // will be relevant so we can bail early.
        if (strictlyHigher(range, current)) break;

        var difference = current.difference(range);
        if (difference.isEmpty) {
          return VersionConstraint.empty;
        } else if (difference is VersionUnion) {
          // If [range] split [current] in half, we only need to continue
          // checking future ranges against the latter half.
          assert(difference.ranges.length == 2);
          ranges.add(difference.ranges.first);
          current = difference.ranges.last;
        } else {
          current = difference as VersionRange;
        }
      }

      if (ranges.isEmpty) return current;
      return VersionUnion.fromRanges(ranges..add(current));
    }

    throw ArgumentError('Unknown VersionConstraint type $other.');
  }

  @override
  int compareTo(VersionRange other) {
    if (min == null) {
      if (other.min == null) return _compareMax(other);
      return -1;
    } else if (other.min == null) {
      return 1;
    }

    var result = min!.compareTo(other.min!);
    if (result != 0) return result;
    if (includeMin != other.includeMin) return includeMin ? -1 : 1;

    return _compareMax(other);
  }

  /// Compares the maximum values of `this` and [other].
  int _compareMax(VersionRange other) {
    if (max == null) {
      if (other.max == null) return 0;
      return 1;
    } else if (other.max == null) {
      return -1;
    }

    var result = max!.compareTo(other.max!);
    if (result != 0) return result;
    if (includeMax != other.includeMax) return includeMax ? 1 : -1;
    return 0;
  }

  @override
  String toString() {
    var buffer = StringBuffer();

    final min = this.min;
    if (min != null) {
      buffer
        ..write(includeMin ? '>=' : '>')
        ..write(min);
    }

    final max = this.max;

    if (max != null) {
      if (min != null) buffer.write(' ');
      if (includeMax) {
        buffer
          ..write('<=')
          ..write(max);
      } else {
        buffer.write('<');
        if (max.isFirstPreRelease) {
          // Since `"<$max"` would parse the same as `"<$max-0"`, we just emit
          // `<$max` to avoid confusing "-0" suffixes.
          buffer.write('${max.major}.${max.minor}.${max.patch}');
        } else {
          buffer.write(max);

          // If `">=$min <$max"` would parse as `">=$min <$max-0"`, add `-*` to
          // indicate that actually does allow pre-release versions.
          var minIsPreReleaseOfMax = min != null &&
              min.isPreRelease &&
              equalsWithoutPreRelease(min, max);
          if (!max.isPreRelease && max.build.isEmpty && !minIsPreReleaseOfMax) {
            buffer.write('-∞');
          }
        }
      }
    }

    if (min == null && max == null) buffer.write('any');
    return buffer.toString();
  }
}

class CompatibleWithVersionRange extends VersionRange {
  CompatibleWithVersionRange(Version version)
      : super._(version, version.nextBreaking.firstPreRelease, true, false);

  @override
  String toString() => '^$min';
}
