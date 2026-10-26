// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../bazel.dart';
import '../build_plan.dart';
import '../build_utils.dart';
import '../gn.dart';
import '../label.dart';
import 'command.dart';

/// The root 'build' command.
final class BuildCommand extends CommandBase {
  /// Constructs the 'build' command.
  BuildCommand({
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
  String get name => 'build';

  @override
  String get description => '''
Builds the engine
et build //flutter/fml/...             # Build all targets in `//flutter/fml` and its subdirectories.
et build //flutter/fml:all             # Build all targets in `//flutter/fml`.
et build //flutter/fml:fml_benchmarks  # Build a specific target in `//flutter/fml`.
''';

  @override
  Future<int> run() async {
    final plan = BuildPlan.fromArgResults(argResults!, environment, builds: builds);

    final List<String> commandLineTargets = argResults!.rest;
    if (plan.backend == BuildBackend.bazel) {
      return _runBazel(plan, commandLineTargets);
    }
    if (commandLineTargets.isNotEmpty &&
        !await ensureBuildDir(environment, plan.build, enableRbe: plan.useRbe)) {
      return 1;
    }

    // Builds only accept labels as arguments, so convert patterns to labels.
    // TODO(matanlurey): Can be optimized in cases where wildcards are not used.
    final gn = Gn.fromEnvironment(environment);
    final allTargets = <Label>{};
    for (final pattern in commandLineTargets) {
      final TargetPattern target = TargetPattern.parse(pattern);
      final List<BuildTarget> targets = await gn.desc('out/${plan.build.ninja.config}', target);
      allTargets.addAll(targets.map((target) => target.label));
    }

    // Warn that we've discarded some targets.
    // Other warnings should have been emitted above, so if this ends up being
    // unneccesarily noisy, we can remove it or limit it to verbose mode.
    if (allTargets.length < commandLineTargets.length) {
      // Report which targets were not found.
      final Iterable<String> notFound = commandLineTargets.where(
        (target) => !allTargets.contains(Label.parse(target)),
      );
      environment.logger.warning(
        'One or more targets specified did not match any build targets:\n\n'
        '${notFound.join('\n')}',
      );
    }

    return runBuild(
      environment,
      plan.build,
      concurrency: plan.concurrency ?? 0,
      extraGnArgs: plan.toGnArgs(),
      targets: allTargets.toList(),
      enableRbe: plan.useRbe,
      rbeConfig: plan.toRbeConfig(),
    );
  }

  /// The Bazel build of the same configuration: `bazel build --config=<name>`
  /// of the targets' Bazel counterparts, or, with no targets (GN's default of
  /// everything), the whole build: for a developer's build, the local engine
  /// target, whose manifest the flutter tool reads where the outputs are (the
  /// directory to name is printed); for a CI build, which names ninja
  /// targets, its install target run into its build directory, which is what
  /// a GN build leaves behind.
  Future<int> _runBazel(BuildPlan plan, List<String> commandLineTargets) async {
    final bazel = Bazel(environment, _configs);
    final String? config = bazel.configFor(plan.build);
    if (config == null) {
      return 1;
    }
    if (plan.extraGnArgs.isNotEmpty) {
      environment.logger.error(
        '--gn-args has no Bazel counterpart; the configuration is the whole of it.',
      );
      return 1;
    }
    if (commandLineTargets.isEmpty) {
      final String? installTarget = bazel.installTargetFor(plan.build);
      if (installTarget == null) {
        final String? localEngine = await bazel.buildLocalEngine(config);
        if (localEngine == null) {
          return 1;
        }
        // Another platform's build pairs with a host build of the same mode,
        // built the same way.
        final String host = bazel.isHostBuild(plan.build)
            ? localEngine
            : "<the host build's directory: et build --backend bazel --config host_<mode>>";
        environment.logger.status(
          'Local engine: $localEngine\n'
          '  flutter <command> --local-engine=$localEngine --local-engine-host=$host',
        );
        return 0;
      }
      return bazel.run(<String>[
        'run',
        '--config=$config',
        installTarget,
        '--',
        bazel.buildDirectoryFor(plan.build),
      ]);
    }
    return bazel.run(<String>[
      'build',
      '--config=$config',
      for (final String pattern in commandLineTargets) Bazel.labelFor(TargetPattern.parse(pattern)),
    ]);
  }
}
