// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'group.dart';
import 'metadata.dart';
import 'suite_platform.dart';
import 'test.dart';

/// A test suite.
///
/// A test suite is a set of tests that are intended to be run together and that
/// share default configuration.
class Suite {
  /// The platform on which the suite is running.
  final SuitePlatform platform;

  /// The path to the Dart test suite, or `null` if that path is unknown.
  final String? path;

  /// The metadata associated with this test suite.
  ///
  /// This is a shortcut for [group.metadata].
  Metadata get metadata => group.metadata;

  /// The top-level group for this test suite.
  final Group group;

  /// Whether or not to ignore test timeouts.
  final bool ignoreTimeouts;

  /// Creates a new suite containing [group].
  ///
  /// If [platform] and/or [os] are passed, [group] is filtered to match that
  /// platform information.
  ///
  /// If [os] is passed without [platform], throws an [ArgumentError].
  Suite(Group group, this.platform, {this.ignoreTimeouts = false, this.path})
      : group = _filterGroup(group, platform);

  /// Returns [entries] filtered according to [platform] and [os].
  ///
  /// Gracefully handles [platform] being null.
  static Group _filterGroup(Group group, SuitePlatform platform) {
    var filtered = group.forPlatform(platform);
    if (filtered != null) return filtered;
    return Group.root([], metadata: group.metadata);
  }

  /// Returns a new suite with all tests matching [test] removed.
  ///
  /// Unlike [GroupEntry.filter], this never returns `null`. If all entries are
  /// filtered out, it returns an empty suite.
  Suite filter(bool Function(Test) callback) {
    var filtered = group.filter(callback);
    filtered ??= Group.root([], metadata: metadata);
    return Suite(filtered, platform,
        ignoreTimeouts: ignoreTimeouts, path: path);
  }

  bool get isLoadSuite => false;
}
