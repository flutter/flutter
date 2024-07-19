// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import '../gn.dart';
import '../label.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'build' command.
final class BuildCommand extends CommandBase {
  /// Constructs the 'build' command.
  BuildCommand({
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
    addConcurrencyOption(argParser);
    argParser.addFlag(
      rbeFlag,
      defaultsTo: environment.hasRbeConfigInTree(),
      help: 'RBE is enabled by default when available.',
    );
    argParser.addFlag(
      ltoFlag,
      help: 'Whether LTO should be enabled for a build. Default is disabled',
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
    final String configName = argResults![configFlag] as String;
    final bool useRbe = argResults![rbeFlag] as bool;
    if (useRbe && !environment.hasRbeConfigInTree()) {
      environment.logger.error('RBE was requested but no RBE config was found');
      return 1;
    }
    final bool useLto = argResults![ltoFlag] as bool;
    final String demangledName = demangleConfigName(environment, configName);
    final Build? build =
        builds.where((Build build) => build.name == demangledName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }

    final String dashJ = argResults![concurrencyFlag] as String;
    final int? concurrency = int.tryParse(dashJ);
    if (concurrency == null || concurrency < 0) {
      environment.logger.error('-j must specify a positive integer.');
      return 1;
    }

    final List<String> extraGnArgs = <String>[
      if (!useRbe) '--no-rbe',
      if (useLto) '--lto' else '--no-lto',
    ];

    final List<String> commandLineTargets = argResults!.rest;
    if (commandLineTargets.isNotEmpty &&
        !await ensureBuildDir(environment, build, enableRbe: useRbe)) {
      return 1;
    }

    // Builds only accept labels as arguments, so convert patterns to labels.
    // TODO(matanlurey): Can be optimized in cases where wildcards are not used.
    final Gn gn = Gn.fromEnvironment(environment);
    final Set<Label> allTargets = <Label>{};
    for (final String pattern in commandLineTargets) {
      final TargetPattern target = TargetPattern.parse(pattern);
      final List<BuildTarget> targets = await gn.desc(
        'out/${build.ninja.config}',
        target,
      );
      allTargets.addAll(targets.map((BuildTarget target) => target.label));
    }

    return runBuild(
      environment,
      build,
      concurrency: concurrency,
      extraGnArgs: extraGnArgs,
      targets: allTargets.toList(),
      enableRbe: useRbe,
    );
  }
}
