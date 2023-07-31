// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// Some stock example versions to use in tests.
final v003 = Version.parse('0.0.3');
final v010 = Version.parse('0.1.0');
final v072 = Version.parse('0.7.2');
final v080 = Version.parse('0.8.0');
final v114 = Version.parse('1.1.4');
final v123 = Version.parse('1.2.3');
final v124 = Version.parse('1.2.4');
final v130 = Version.parse('1.3.0');
final v140 = Version.parse('1.4.0');
final v200 = Version.parse('2.0.0');
final v201 = Version.parse('2.0.1');
final v234 = Version.parse('2.3.4');
final v250 = Version.parse('2.5.0');
final v300 = Version.parse('3.0.0');

/// A range that allows pre-release versions of its max version.
final includeMaxPreReleaseRange =
    VersionRange(max: v200, alwaysIncludeMaxPreRelease: true);

/// A [Matcher] that tests if a [VersionConstraint] allows or does not allow a
/// given list of [Version]s.
class _VersionConstraintMatcher implements Matcher {
  final List<Version> _expected;
  final bool _allow;

  _VersionConstraintMatcher(this._expected, this._allow);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      (item is VersionConstraint) &&
      _expected.every((version) => item.allows(version) == _allow);

  @override
  Description describe(Description description) {
    description.addAll(' ${_allow ? "allows" : "does not allow"} versions ',
        ', ', '', _expected);
    return description;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! VersionConstraint) {
      mismatchDescription.add('was not a VersionConstraint');
      return mismatchDescription;
    }

    var first = true;
    for (var version in _expected) {
      if (item.allows(version) != _allow) {
        if (first) {
          if (_allow) {
            mismatchDescription.addDescriptionOf(item).add(' did not allow ');
          } else {
            mismatchDescription.addDescriptionOf(item).add(' allowed ');
          }
        } else {
          mismatchDescription.add(' and ');
        }
        first = false;

        mismatchDescription.add(version.toString());
      }
    }

    return mismatchDescription;
  }
}

/// Gets a [Matcher] that validates that a [VersionConstraint] allows all
/// given versions.
Matcher allows(Version v1,
    [Version? v2,
    Version? v3,
    Version? v4,
    Version? v5,
    Version? v6,
    Version? v7,
    Version? v8]) {
  var versions = _makeVersionList(v1, v2, v3, v4, v5, v6, v7, v8);
  return _VersionConstraintMatcher(versions, true);
}

/// Gets a [Matcher] that validates that a [VersionConstraint] allows none of
/// the given versions.
Matcher doesNotAllow(Version v1,
    [Version? v2,
    Version? v3,
    Version? v4,
    Version? v5,
    Version? v6,
    Version? v7,
    Version? v8]) {
  var versions = _makeVersionList(v1, v2, v3, v4, v5, v6, v7, v8);
  return _VersionConstraintMatcher(versions, false);
}

List<Version> _makeVersionList(Version v1,
    [Version? v2,
    Version? v3,
    Version? v4,
    Version? v5,
    Version? v6,
    Version? v7,
    Version? v8]) {
  var versions = [v1];
  if (v2 != null) versions.add(v2);
  if (v3 != null) versions.add(v3);
  if (v4 != null) versions.add(v4);
  if (v5 != null) versions.add(v5);
  if (v6 != null) versions.add(v6);
  if (v7 != null) versions.add(v7);
  if (v8 != null) versions.add(v8);
  return versions;
}
