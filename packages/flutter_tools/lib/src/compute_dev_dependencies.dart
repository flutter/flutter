// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';

import 'base/common.dart';
import 'base/logger.dart';

/// Returns dependencies of [project] that are only used as `dev_dependency`.
///
/// That is, computes and returns a subset of dependencies, where the original
/// set is based on packages listed as [`dev_dependency`][dev_deps] in the
/// `pubspec.yaml` file, and removing packages from that set that appear as
/// dependencies (implicitly non-dev) in any non-dev package depended on.
Future<Set<String>> computeDevDependencies(
  ProcessManager processes, {
  required Logger logger,
  required String projectPath,
}) async {
  final ProcessResult processResult = await processes.run(
    <String>['dart', 'pub', 'deps', '--json'],
    workingDirectory: projectPath,
  );

  // Guard against dart pub deps crashing.
  final Map<String, Object?> jsonResult;
  if (processResult.exitCode != 0 || processResult.stdout is! String) {
    logger.printError('dart pub deps --json failed: ${processResult.stderr}');
    throwToolExit(null);
  }

  // Guard against dart pub deps having explicitly invalid output.
  final String stdout;
  try {
    stdout = processResult.stdout as String;
    jsonResult = json.decode(stdout) as Map<String, Object?>;
  } on FormatException catch (e) {
    logger.printError('dart pub deps --json had invalid output: $e');
    throwToolExit(null);
  }

  throw UnimplementedError();
}

/// Represents the decoded result of `dart pub deps --json`:
///
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
final class _PubDependency {
  const _PubDependency({
    required this.name,
    required this.kind,
    required this.dependencies,
    required this.directDependencies,
    required this.devDependencies,
  });

  final String name;
  final String kind;
  final List<String> dependencies;
  final List<String> directDependencies;
  final List<String> devDependencies;
}
