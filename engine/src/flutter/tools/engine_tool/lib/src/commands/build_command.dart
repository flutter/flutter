// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import '../gn_utils.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'build' command.
final class BuildCommand extends CommandBase {
  /// Constructs the 'build' command.
  BuildCommand({
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
    argParser.addFlag(
      rbeFlag,
      defaultsTo: true,
      help: 'RBE is enabled by default when available. Use --no-rbe to '
          'disable it.',
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
et build //flutter/fml/...             # Build all targets in `//flutter/fml/`
et build //flutter/fml:fml_benchmarks  # Build a specific target in `//flutter/fml/`
''';

  @override
  Future<int> run() async {
    final String configName = argResults![configFlag] as String;
    final bool useRbe = argResults![rbeFlag] as bool;
    final bool useLto = argResults![ltoFlag] as bool;
    final String demangledName = demangleConfigName(environment, configName);
    final Build? build =
        builds.where((Build build) => build.name == demangledName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }

    final List<String> extraGnArgs = <String>[
      if (!useRbe) '--no-rbe',
      if (useLto) '--lto',
      if (!useLto) '--no-lto',
    ];

    final List<BuildTarget>? selectedTargets = await targetsFromCommandLine(
      environment,
      build,
      argResults!.rest,
    );
    if (selectedTargets == null) {
      // The user typed something wrong and targetsFromCommandLine has already
      // logged the error message.
      return 1;
    }

    // Chop off the '//' prefix.
    final List<String> ninjaTargets = selectedTargets.map<String>(
      (BuildTarget target) => target.label.substring('//'.length),
    ).toList();

    return runBuild(
      environment,
      build,
      extraGnArgs: extraGnArgs,
      targets: ninjaTargets,
    );
  }
}
