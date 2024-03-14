// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'build' command.
final class BuildCommand extends CommandBase {
  /// Constructs the 'build' command.
  BuildCommand({
    required super.environment,
    required Map<String, BuilderConfig> configs,
  }) {
    builds = runnableBuilds(environment, configs);
    debugCheckBuilds(builds);
    argParser.addOption(
      configFlag,
      abbr: 'c',
      defaultsTo: 'host_debug',
      help: 'Specify the build config to use',
      allowed: <String>[
        for (final Build config in runnableBuilds(environment, configs))
          config.name,
      ],
      allowedHelp: <String, String>{
        for (final Build config in runnableBuilds(environment, configs))
          config.name: config.gn.join(' '),
      },
    );
    argParser.addFlag(
      rbeFlag,
      defaultsTo: true,
      help: 'RBE is enabled by default when available. Use --no-rbe to '
            'disable it.',
    );
  }

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'build';

  @override
  String get description => 'Builds the engine';

  @override
  Future<int> run() async {
    final String configName = argResults![configFlag] as String;
    final bool useRbe = argResults![rbeFlag] as bool;
    final Build? build =
        builds.where((Build build) => build.name == configName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }

    final List<String> extraGnArgs = <String>[
      if (!useRbe) '--no-rbe',
    ];

    // TODO(loic-sharma): Fetch dependencies if needed.
    return runBuild(environment, build, extraGnArgs: extraGnArgs);
  }
}
