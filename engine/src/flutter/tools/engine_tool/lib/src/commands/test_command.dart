// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../bazel.dart';
import '../build_plan.dart';
import '../build_utils.dart';
import '../gn.dart';
import '../label.dart';
import '../proc_utils.dart';
import '../worker_pool.dart';
import 'command.dart';

/// The root 'test' command.
final class TestCommand extends CommandBase {
  /// Constructs the 'test' command.
  TestCommand({
    required super.environment,
    required Map<String, BuilderConfig> configs,
    super.help = false,
    super.usageLineLength,
  }) : _configs = configs {
    builds = BuildPlan.configureArgParser(argParser, environment, configs: configs, help: help);
  }

  final Map<String, BuilderConfig> _configs;

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'test';

  @override
  String get description => '''
Runs a test target
et test //flutter/fml/...             # Run all test targets in `//flutter/fml` and its subdirectories.
et test //flutter/fml:all             # Run all test targets in `//flutter/fml`.
et test //flutter/fml:fml_benchmarks  # Run a single test target in `//flutter/fml`.
''';

  @override
  Future<int> run() async {
    final plan = BuildPlan.fromArgResults(argResults!, environment, builds: builds);

    if (plan.backend == BuildBackend.bazel) {
      return _runBazel(plan, argResults!.rest);
    }

    if (!await ensureBuildDir(environment, plan.build, enableRbe: plan.useRbe)) {
      return 1;
    }

    // Builds only accept labels as arguments, so convert patterns to labels.
    final gn = Gn.fromEnvironment(environment);

    // Figure out what targets the user wants to build.
    final buildTargets = <BuildTarget>{};
    for (final String pattern in argResults!.rest) {
      final TargetPattern target = TargetPattern.parse(pattern);
      final List<BuildTarget> found = await gn.desc('out/${plan.build.ninja.config}', target);
      buildTargets.addAll(found);
    }

    if (buildTargets.isEmpty) {
      environment.logger.error('No targets found, nothing to test.');
      return 1;
    }

    // Make sure there is at least one test target.
    final List<ExecutableBuildTarget> testTargets = buildTargets
        .whereType<ExecutableBuildTarget>()
        .where((ExecutableBuildTarget t) => t.testOnly)
        .toList();

    if (testTargets.isEmpty) {
      environment.logger.error('No test targets found');
      return 1;
    }

    final int buildExitCode = await runBuild(
      environment,
      plan.build,
      concurrency: plan.concurrency ?? 0,
      targets: testTargets.map((target) => target.label).toList(),
      enableRbe: plan.useRbe,
      rbeConfig: plan.toRbeConfig(),
    );
    if (buildExitCode != 0) {
      return buildExitCode;
    }
    final workerPool = WorkerPool(environment, ProcessTaskProgressReporter(environment));
    final tasks = <ProcessTask>{};
    for (final target in testTargets) {
      final commandLine = <String>[target.executable];
      tasks.add(
        ProcessTask(target.label.toString(), environment, environment.engine.srcDir, commandLine),
      );
    }
    return await workerPool.run(tasks) ? 0 : 1;
  }

  /// `bazel test --config=<name>` of the patterns' Bazel counterparts (Bazel
  /// picks the tests among them itself), or of the build's own test suite --
  /// what its `run_tests.py` steps run -- when no pattern is given.
  Future<int> _runBazel(BuildPlan plan, List<String> patterns) async {
    final bazel = Bazel(environment, _configs);
    final String? config = bazel.configFor(plan.build);
    if (config == null) {
      return 1;
    }
    final targets = <String>[
      for (final String pattern in patterns) Bazel.labelFor(TargetPattern.parse(pattern)),
    ];
    if (targets.isEmpty) {
      final String? suite = bazel.testSuiteFor(plan.build);
      if (suite == null) {
        environment.logger.error(
          'No targets given, and ${plan.build.name} has no test steps of its own '
          '(no <name>_tests suite in flutter/ci/builders/BUILD.bazel).',
        );
        return 1;
      }
      targets.add(suite);
    }
    return bazel.run(<String>['test', '--config=$config', ...targets]);
  }
}
