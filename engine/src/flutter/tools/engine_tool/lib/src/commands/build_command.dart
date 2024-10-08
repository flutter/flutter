// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

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
  }) {
    builds = BuildPlan.configureArgParser(
      argParser,
      environment,
      configs: configs,
      help: help,
    );
  }

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
    final plan = BuildPlan.fromArgResults(
      argResults!,
      environment,
      builds: builds,
    );

    final commandLineTargets = argResults!.rest;
    if (commandLineTargets.isNotEmpty &&
        !await ensureBuildDir(
          environment,
          plan.build,
          enableRbe: plan.useRbe,
        )) {
      return 1;
    }

    // Builds only accept labels as arguments, so convert patterns to labels.
    // TODO(matanlurey): Can be optimized in cases where wildcards are not used.
    final gn = Gn.fromEnvironment(environment);
    final allTargets = <Label>{};
    for (final pattern in commandLineTargets) {
      final target = TargetPattern.parse(pattern);
      final targets = await gn.desc(
        'out/${plan.build.ninja.config}',
        target,
      );
      allTargets.addAll(targets.map((target) => target.label));
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
}
