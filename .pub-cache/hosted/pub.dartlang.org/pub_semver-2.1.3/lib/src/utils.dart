// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'version.dart';
import 'version_range.dart';

/// Returns whether [range1] is immediately next to, but not overlapping,
/// [range2].
bool areAdjacent(VersionRange range1, VersionRange range2) {
  if (range1.max != range2.min) return false;

  return (range1.includeMax && !range2.includeMin) ||
      (!range1.includeMax && range2.includeMin);
}

/// Returns whether [range1] allows lower versions than [range2].
bool allowsLower(VersionRange range1, VersionRange range2) {
  if (range1.min == null) return range2.min != null;
  if (range2.min == null) return false;

  var comparison = range1.min!.compareTo(range2.min!);
  if (comparison == -1) return true;
  if (comparison == 1) return false;
  return range1.includeMin && !range2.includeMin;
}

/// Returns whether [range1] allows higher versions than [range2].
bool allowsHigher(VersionRange range1, VersionRange range2) {
  if (range1.max == null) return range2.max != null;
  if (range2.max == null) return false;

  var comparison = range1.max!.compareTo(range2.max!);
  if (comparison == 1) return true;
  if (comparison == -1) return false;
  return range1.includeMax && !range2.includeMax;
}

/// Returns whether [range1] allows only versions lower than those allowed by
/// [range2].
bool strictlyLower(VersionRange range1, VersionRange range2) {
  if (range1.max == null || range2.min == null) return false;

  var comparison = range1.max!.compareTo(range2.min!);
  if (comparison == -1) return true;
  if (comparison == 1) return false;
  return !range1.includeMax || !range2.includeMin;
}

/// Returns whether [range1] allows only versions higher than those allowed by
/// [range2].
bool strictlyHigher(VersionRange range1, VersionRange range2) =>
    strictlyLower(range2, range1);

bool equalsWithoutPreRelease(Version version1, Version version2) =>
    version1.major == version2.major &&
    version1.minor == version2.minor &&
    version1.patch == version2.patch;
