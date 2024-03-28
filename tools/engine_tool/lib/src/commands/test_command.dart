// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:path/path.dart' as p;

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
  }) {
    builds = runnableBuilds(environment, configs);
    debugCheckBuilds(builds);
    addConfigOption(argParser, runnableBuilds(environment, configs));
  }

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'test';

  @override
  String get description => 'Runs a test target'
      'et test //flutter/fml/...             # Run all test targets in `//flutter/fml/`'
      'et test //flutter/fml:fml_benchmarks  # Run a single test target in `//flutter/fml/`';

  @override
  Future<int> run() async {
    final String configName = argResults![configFlag] as String;
    final Build? build =
        builds.where((Build build) => build.name == configName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }

    final Map<String, TestTarget> allTargets = await findTestTargets(
        environment,
        Directory(p.join(environment.engine.outDir.path, build.ninja.config)));
    final Set<TestTarget> selectedTargets =
        selectTargets(argResults!.rest, allTargets);
    if (selectedTargets.isEmpty) {
      environment.logger.error(
          'No build targets matched ${argResults!.rest}\nRun `et query tests` to see list of targets.');
      return 1;
    }
    // Chop off the '//' prefix.
    final List<String> buildTargets = selectedTargets
        .map<String>((TestTarget target) => target.label.substring('//'.length))
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
    for (final TestTarget target in selectedTargets) {
      final List<String> commandLine = <String>[target.executable.path];
      tasks.add(ProcessTask(
          target.label, environment, environment.engine.srcDir, commandLine));
    }
    return await workerPool.run(tasks) ? 0 : 1;
  }
}
