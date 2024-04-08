// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'build_utils.dart';
import 'environment.dart';
import 'json_utils.dart';
import 'proc_utils.dart';

/// Canonicalized build targets start with this prefix.
const String buildTargetPrefix = '//';

/// A suffix to build targets that recursively selects all child build targets.
const String _buildTargetGlobSuffix = '/...';

/// The type of a BuildTarget
enum BuildTargetType {
  /// Produces an executable program.
  executable,

  /// Produces a shared library.
  sharedLibrary,

  /// Produces a static library.
  staticLibrary,
}

BuildTargetType? _buildTargetTypeFromString(String type) {
  switch (type) {
    case 'executable':
      return BuildTargetType.executable;
    case 'shared_library':
      return BuildTargetType.sharedLibrary;
    case 'static_library':
      return BuildTargetType.staticLibrary;
    default:
      // We ignore a number of types here.
      return null;
  }
}

// TODO(johnmccutchan): What should we do about source_sets and other
// output-less targets? Also, what about action targets which are kind of
// "internal" build steps? For now we are ignoring them.

/// Information about a build target.
final class BuildTarget {
  //// Construct a build target.
  BuildTarget(this.type, this.label, {this.executable, this.testOnly = false});

  /// The type of build target.
  final BuildTargetType type;

  /// The build target label. `//flutter/fml:fml_unittests`.
  final String label;

  /// The executable file produced after the build target is built.
  final File? executable;

  /// Is this a target that is only used by tests?
  final bool testOnly;

  @override
  String toString() {
    return 'target=$label type=$type testOnly=$testOnly executable=${executable ?? "N/A"}';
  }
}

/// Returns all targets for a given build directory.
Future<Map<String, BuildTarget>> findTargets(
    Environment environment, Directory buildDir) async {
  final Map<String, BuildTarget> r = <String, BuildTarget>{};
  final List<String> getBuildInfoCommandLine = <String>[
    gnBinPath(environment),
    'desc',
    buildDir.path,
    '*',
    '--format=json',
  ];

  final ProcessRunnerResult result = await environment.processRunner.runProcess(
      getBuildInfoCommandLine,
      workingDirectory: environment.engine.srcDir,
      failOk: true);

  // Handle any process failures.
  fatalIfFailed(environment, getBuildInfoCommandLine, result);

  late final Map<String, Object?> jsonResult;
  try {
    jsonResult = jsonDecode(result.stdout) as Map<String, Object?>;
  } catch (e) {
    environment.logger.fatal(
        'gn desc output could not be parsed:\nE=$e\nIN=${result.stdout}\n');
  }

  for (final MapEntry<String, Object?> targetEntry in jsonResult.entries) {
    final String label = targetEntry.key;
    if (targetEntry.value == null) {
      environment.logger
          .fatal('gn desc output is malformed $label has no value.');
    }
    final Map<String, Object?> properties =
        targetEntry.value! as Map<String, Object?>;
    final String? typeString = getString(properties, 'type');
    if (typeString == null) {
      environment.logger.fatal('gn desc is missing target type: $properties');
    }
    final BuildTargetType? type = _buildTargetTypeFromString(typeString!);
    if (type == null) {
      // Target is a type that we don't support.
      continue;
    }
    final bool testOnly = getBool(properties, 'testonly');
    final List<String> outputs =
        getListOfString(properties, 'outputs') ?? <String>[];
    File? executable;
    if (type == BuildTargetType.executable) {
      if (outputs.isEmpty) {
        environment.logger.fatal('gn executable target $label has no outputs.');
      }
      executable = File(p.join(buildDir.path, outputs.first));
    }
    final BuildTarget target =
        BuildTarget(type, label, testOnly: testOnly, executable: executable);
    r[label] = target;
  }
  return r;
}

/// Process selectors and filter allTargets for matches.
///
/// We support:
///   1) Exact label matches (the '//' prefix will be stripped off).
///   2) '/...' suffix which selects all targets that match the prefix.
///
/// NOTE: if selectors is empty all targets will be selected.
Set<BuildTarget> selectTargets(
    List<String> selectors, Map<String, BuildTarget> allTargets) {
  final Set<BuildTarget> selected = <BuildTarget>{};

  if (selectors.isEmpty) {
    // Default to all if no selectors are specified.
    // TODO(johnmccutchan): Reconsider this default or at least lift
    // this logic up to the caller.
    allTargets.values.forEach(selected.add);
    return selected;
  }

  for (String selector in selectors) {
    if (!selector.startsWith(buildTargetPrefix)) {
      // Insert the prefix when necessary.
      selector = '$buildTargetPrefix$selector';
    }
    final bool recursiveMatch = selector.endsWith(_buildTargetGlobSuffix);
    if (recursiveMatch) {
      // Remove the /... suffix.
      selector = selector.substring(
          0, selector.length - _buildTargetGlobSuffix.length);
      // TODO(johnmccutchan): Accelerate this by using a trie.
      for (final BuildTarget target in allTargets.values) {
        if (target.label.startsWith(selector)) {
          selected.add(target);
        }
      }
    } else {
      for (final BuildTarget target in allTargets.values) {
        if (target.label == selector) {
          selected.add(target);
        }
      }
    }
  }
  return selected;
}

/// Given a list of target specifications from the command line, return a list
/// of [BuildTarget]s from the [Build] that match those specifications.
///
/// If `commandLineTargets` is empty, by default this will return the empty
/// list, which indicates that the caller should delegate the selection of
/// build targets to whatever is specified by the [Build] object. However,
/// if `defaultToAll` is `true`, then this function will return the list of
/// all build targets.
Future<List<BuildTarget>?> targetsFromCommandLine(
  Environment environment,
  Build build,
  List<String> commandLineTargets, {
  bool defaultToAll = false,
}) async {
  // If there are no targets specified on the command line, then delegate to
  // the default targets specified in the Build object unless directed
  // otherwise by the defaultToAll argument.
  if (commandLineTargets.isEmpty && !defaultToAll) {
    return <BuildTarget>[];
  }

  final Directory buildDir = Directory(p.join(
    environment.engine.outDir.path,
    build.ninja.config,
  ));
  // If the expected build output directory doesn't exist yet, eagerly run
  // the build's GN step to try to produce it.
  if (!buildDir.existsSync()) {
    environment.logger.status(
      'Build output directory at ${buildDir.path} not found. Running GN.',
    );
    final int gnResult = await runGn(environment, build);
    if (gnResult != 0 || !buildDir.existsSync()) {
      environment.logger.error(
        'The specified build did not produce the expected build '
        'output directory.',
      );
      return null;
    }
  }

  // Find all targets buildable in the configuration.
  final Map<String, BuildTarget> allTargets = await findTargets(
    environment,
    buildDir,
  );
  // Use the targets specified on the command line to filter the list of
  // all targets.
  final Set<BuildTarget> selectedTargets = selectTargets(
    commandLineTargets,
    allTargets,
  );
  // Report an error if applying the filter yields no results.
  if (selectedTargets.isEmpty) {
    environment.logger.error(
      'No build targets matched ${commandLineTargets.join(',')}\n'
      'Run `et query targets` to see list of targets.',
    );
    return null;
  }
  return selectedTargets.toList();
}
