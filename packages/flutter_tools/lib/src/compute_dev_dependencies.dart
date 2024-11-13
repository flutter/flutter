// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import 'base/io.dart';
import 'base/logger.dart';
import 'convert.dart';

/// Returns dependencies of [project] that are _only_ used as `dev_dependency`.
///
/// That is, computes and returns a subset of dependencies, where the original
/// set is based on packages listed as [`dev_dependency`][dev_deps] in the
/// `pubspec.yaml` file, and removing packages from that set that appear as
/// dependencies (implicitly non-dev) in any non-dev package depended on.
Future<Set<String>> computeExclusiveDevDependencies(
  ProcessManager processes, {
  required Logger logger,
  required String projectPath,
}) async {
  final ProcessResult processResult = await processes.run(
    <String>['dart', 'pub', 'deps', '--json'],
    workingDirectory: projectPath,
  );

  Never fail([String? reason]) {
    final Object? stdout = processResult.stdout;
    if (stdout is String && stdout.isNotEmpty) {
      logger.printTrace(stdout);
    }
    final String stderr = processResult.stderr.toString();
    throw StateError(
      'dart pub deps --json ${reason != null ? 'had unexpected output: $reason' : 'failed'}'
      '${stderr.isNotEmpty ? '\n$stderr' : ''}',
    );
  }

  // Guard against dart pub deps crashing.
  final Map<String, Object?> jsonResult;
  if (processResult.exitCode != 0 || processResult.stdout is! String) {
    fail();
  }

  // Guard against dart pub deps having explicitly invalid output.
  final String stdout;
  try {
    stdout = processResult.stdout as String;

    // This is an indication that `FakeProcessManager.any` was used, which by
    // contract emits exit code 0 and no output on either stdout or stderr. To
    // avoid this code, we'd have to go and make this function injectable into
    // every callsite and mock-it out manually, which at the time of this
    // writing was 130+ unit test cases alone.
    //
    // So, this is the lesser of two evils.
    if (stdout.isEmpty && processResult.stderr == '') {
      return <String>{};
    }

    jsonResult = json.decode(stdout) as Map<String, Object?>;
  } on FormatException catch (e) {
    fail('$e');
  }

  List<T> asListOrFail<T>(Object? value, String name) {
    // Allow omitting a list as empty to default to an empty list
    if (value == null) {
      return <T>[];
    }
    if (value is! List<Object?>) {
      fail('Expected field "$name" to be a list, got "$value"');
    }
    return <T>[
      for (final Object? any in value)
        if (any is T) any else fail('Expected element to be a $T, got "$any"')
    ];
  }

  // Parse the JSON roughly in the following format:
  //
  // ```json
  // {
  //   "root": "my_app",
  //   "packages": [
  //     {
  //       "name": "my_app",
  //       "kind": "root",
  //       "dependencies": [
  //         "foo_plugin",
  //         "bar_plugin"
  //       ],
  //       "directDependencies": [
  //         "foo_plugin"
  //       ],
  //       "devDependencies": [
  //         "bar_plugin"
  //       ]
  //     }
  //   ]
  // }
  // ```
  final List<Map<String, Object?>> packages = asListOrFail(
    jsonResult['packages'],
    'packages',
  );

  Map<String, Object?> packageWhere(
    bool Function(Map<String, Object?>) test, {
    required String reason,
  }) {
    return packages.firstWhere(test, orElse: () => fail(reason));
  }

  final Map<String, Object?> rootPackage = packageWhere(
    (Map<String, Object?> package) => package['kind'] == 'root',
    reason: 'A package with kind "root" was not found.',
  );

  // Start initially with every `devDependency` listed.
  final Set<String> devDependencies = asListOrFail<String>(
    rootPackage['devDependencies'] ?? <String>[],
    'devDependencies',
  ).toSet();

  // Then traverse and exclude non-dev dependencies that list that dependency.
  //
  // This avoids the pathalogical problem of using, say, `path_provider` in a
  // package's dev_dependencies:, but a (non-dev) dependency using it as a
  // standard dependency - in that case we would not want to report it is used
  // as a dev dependency.
  final Set<String> visited = <String>{};
  void visitPackage(String packageName) {
    final bool wasAlreadyVisited = !visited.add(packageName);
    if (wasAlreadyVisited) {
      return;
    }

    final Map<String, Object?> package = packageWhere(
      (Map<String, Object?> package) => package['name'] == packageName,
      reason: 'A package with name "$packageName" was not found',
    );

    // Do not traverse packages that themselves are dev dependencies.
    if (package['kind'] == 'dev') {
      return;
    }

    final List<String> directDependencies = asListOrFail(
      package['directDependencies'],
      'directDependencies',
    );

    // Remove any listed dependency from dev dependencies; it might have been
    // a dev dependency for the app (root) package, but it is being used as a
    // real dependency for a dependend on package, so we would not want to send
    // a signal that the package can be ignored/removed.
    devDependencies.removeAll(directDependencies);

    // And continue visiting (visitPackage checks for circular loops).
    directDependencies.forEach(visitPackage);
  }

  // Start with the root package.
  visitPackage(rootPackage['name']! as String);

  return devDependencies;
}
