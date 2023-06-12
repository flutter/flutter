// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../generate/options.dart';
import '../generate/phase.dart';

/// Returns whether or not [id] should be built based upon [buildDirs],
/// [phase], and optional [buildFilters].
///
/// The logic for this is as follows:
///
/// - If any [buildFilters] are supplied, then this only returns `true` if [id]
///   explicitly matches one of the filters.
/// - If no [buildFilters] are supplied, then the old behavior applies - all
///   build to source builders and all files under `lib` of all packages are
///   always built.
/// - Regardless of the [buildFilters] setting, if [buildDirs] is supplied then
///   `id.path` must start with one of the specified directory names.
bool shouldBuildForDirs(AssetId id, Set<String> buildDirs,
    Set<BuildFilter> buildFilters, BuildPhase phase) {
  buildFilters ??= {};
  if (buildFilters.isEmpty) {
    if (!phase.hideOutput) return true;

    if (id.path.startsWith('lib/')) return true;
  } else {
    if (!buildFilters.any((f) => f.matches(id))) {
      return false;
    }
  }

  if (buildDirs.isEmpty) return true;

  return id.path.startsWith('lib/') || buildDirs.any(id.path.startsWith);
}
