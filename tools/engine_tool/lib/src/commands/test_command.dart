// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import '../gn_utils.dart';
import '../proc_utils.dart';
import '../worker_pool.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'test' command.
final class TestCommand extends CommandBase {
  /// Constructs the 'test' command.
  TestCommand({
    required super.environment,
    required Map<String, BuilderConfig> configs,
    super.verbose = false,
    super.usageLineLength,
  }) {
    builds = runnableBuilds(environment, configs, verbose);
    debugCheckBuilds(builds);
    addConfigOption(
      environment,
      argParser,
      builds,
    );
  }

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'test';

  @override
  String get description => '''
Runs a test target
et test //flutter/fml/...             # Run all test targets in `//flutter/fml/`
et test //flutter/fml:fml_benchmarks  # Run a single test target in `//flutter/fml/`
''';

  @override
  Future<int> run() async {
    final String configName = argResults![configFlag] as String;
    final String demangledName = demangleConfigName(environment, configName);
    final Build? build =
        builds.where((Build build) => build.name == demangledName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }

    final List<BuildTarget>? selectedTargets = await targetsFromCommandLine(
      environment,
      build,
      argResults!.rest,
      defaultToAll: true,
    );
    if (selectedTargets == null) {
      // The user typed something wrong and targetsFromCommandLine has already
      // logged the error message.
      return 1;
    }
    if (selectedTargets.isEmpty) {
      environment.logger.fatal(
        'targetsFromCommandLine unexpectedly returned an empty list',
      );
    }

    for (final BuildTarget target in selectedTargets) {
      if (!target.testOnly || target.type != BuildTargetType.executable) {
        // Remove any targets that aren't testOnly and aren't executable.
        selectedTargets.remove(target);
      }
      if (target.executable == null) {
        environment.logger.fatal(
            '$target is an executable but is missing the executable path');
      }
    }
    // Chop off the '//' prefix.
    final List<String> buildTargets = selectedTargets
        .map<String>(
            (BuildTarget target) => target.label.substring('//'.length))
        .toList();
    // TODO(johnmccutchan): runBuild manipulates buildTargets and adds some
    // targets listed in Build. Fix this.
    final int buildExitCode =
        await runBuild(environment, build, targets: buildTargets);
    if (buildExitCode != 0) {
      return buildExitCode;
    }
    final WorkerPool workerPool =
        WorkerPool(environment, ProcessTaskProgressReporter(environment));
    final Set<ProcessTask> tasks = <ProcessTask>{};
    for (final BuildTarget target in selectedTargets) {
      final List<String> commandLine = <String>[target.executable!.path];
      tasks.add(ProcessTask(
          target.label, environment, environment.engine.srcDir, commandLine));
    }
    return await workerPool.run(tasks) ? 0 : 1;
  }
}
