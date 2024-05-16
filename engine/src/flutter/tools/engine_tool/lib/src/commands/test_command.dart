// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import '../gn.dart';
import '../label.dart';
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
    super.help = false,
    super.usageLineLength,
  }) {
    // When printing the help/usage for this command, only list all builds
    // when the --verbose flag is supplied.
    final bool includeCiBuilds = environment.verbose || !help;
    builds = runnableBuilds(environment, configs, includeCiBuilds);
    debugCheckBuilds(builds);
    addConfigOption(
      environment,
      argParser,
      builds,
    );
    argParser.addFlag(
      rbeFlag,
      defaultsTo: environment.hasRbeConfigInTree(),
      help: 'RBE is enabled by default when available.',
    );
  }

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
    final String configName = argResults![configFlag] as String;
    final bool useRbe = argResults![rbeFlag] as bool;
    if (useRbe && !environment.hasRbeConfigInTree()) {
      environment.logger.error('RBE was requested but no RBE config was found');
      return 1;
    }
    final String demangledName = demangleConfigName(environment, configName);
    final Build? build =
        builds.where((Build build) => build.name == demangledName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }

    if (!await ensureBuildDir(environment, build, enableRbe: useRbe)) {
      return 1;
    }

    // Builds only accept labels as arguments, so convert patterns to labels.
    final Gn gn = Gn.fromEnvironment(environment);

    // Figure out what targets the user wants to build.
    final Set<BuildTarget> buildTargets = <BuildTarget>{};
    for (final String pattern in argResults!.rest) {
      final TargetPattern target = TargetPattern.parse(pattern);
      final List<BuildTarget> found = await gn.desc(
        'out/${build.ninja.config}',
        target,
      );
      buildTargets.addAll(found);
    }

    // Make sure there is at least one test target.
    final List<ExecutableBuildTarget> testTargets = buildTargets
        .whereType<ExecutableBuildTarget>()
        .where((ExecutableBuildTarget t) => t.testOnly).toList();

    if (testTargets.isEmpty) {
      environment.logger.error('No test targets found');
      return 1;
    }

    final int buildExitCode = await runBuild(
      environment,
      build,
      targets: testTargets.map((BuildTarget target) => target.label).toList(),
      enableRbe: useRbe,
    );
    if (buildExitCode != 0) {
      return buildExitCode;
    }
    final WorkerPool workerPool = WorkerPool(
      environment,
      ProcessTaskProgressReporter(environment),
    );
    final Set<ProcessTask> tasks = <ProcessTask>{};
    for (final ExecutableBuildTarget target in testTargets) {
      final List<String> commandLine = <String>[target.executable];
      tasks.add(ProcessTask(
        target.label.toString(),
        environment,
        environment.engine.srcDir,
        commandLine,
      ));
    }
    return await workerPool.run(tasks) ? 0 : 1;
  }
}
