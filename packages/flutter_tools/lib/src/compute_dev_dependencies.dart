// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'project.dart';

/// Returns dependencies of [project] that are only used as `dev_dependency`.
///
/// That is, computes and returns a subset of dependencies, where the original
/// set is based on packages listed as [`dev_dependency`][dev_deps] in the
/// `pubspec.yaml` file, and removing packages from that set that appear as
/// dependencies (implicitly non-dev) in any non-dev package depended on.
///
/// Indirectly uses `dart pub deps --json`, which looks something like this:
/// ```json
/// {
///   "root": "my_app",
///   "packages": [
///     {
///       "name": "my_app",
///       "kind": "root",
///       "dependencies": [
///         "foo_plugin",
///         "bar_plugin"
///       ],
///       "directDependencies": [
///         "foo_plugin"
///       ],
///       "devDependencies": [
///         "bar_plugin"
///       ]
///     }
///   ]
/// }
/// ```
Future<Set<String>> computeDirectDevDependencies(FlutterProject project) {
  throw UnimplementedError();
}
