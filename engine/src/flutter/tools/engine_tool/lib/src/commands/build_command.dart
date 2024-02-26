// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import '../logger.dart';
import 'command.dart';
import 'flags.dart';

// TODO(johnmccutchan): Should BuildConfig be BuilderConfig and GlobalBuild be BuildConfig?
// TODO(johnmccutchan): List all available build targets and allow the user
// to specify which one(s) we should build on the cli.
// TODO(johnmccutchan): Can we show a progress indicator like 'running gn...'?

/// The root 'build' command.
final class BuildCommand extends CommandBase {
  /// Constructs the 'build' command.
  BuildCommand({
    required super.environment,
    required Map<String, BuildConfig> configs,
  }) {
    builds = runnableBuilds(environment, configs);
    // Add options here that are common to all queries.
    argParser.addOption(
      configFlag,
      abbr: 'c',
      defaultsTo: 'host_debug',
      help: 'Specify the build config to use',
      allowed: <String>[
        for (final GlobalBuild config in runnableBuilds(environment, configs))
          config.name,
      ],
      allowedHelp: <String, String>{
        for (final GlobalBuild config in runnableBuilds(environment, configs))
          config.name: config.gn.join(' '),
      },
    );
  }

  /// List of compatible builds.
  late final List<GlobalBuild> builds;

  @override
  String get name => 'build';

  @override
  String get description => 'Builds the engine';

  @override
  Future<int> run() async {
    final String configName = argResults![configFlag] as String;
    final GlobalBuild? build = builds
        .where((GlobalBuild build) => build.name == configName)
        .firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }
    final GlobalBuildRunner buildRunner = GlobalBuildRunner(
      platform: environment.platform,
      processRunner: environment.processRunner,
      abi: environment.abi,
      engineSrcDir: environment.engine.srcDir,
      build: build,
      runTests: false,
    );

    Spinner? spinner;
    void handler(RunnerEvent event) {
      switch (event) {
        case RunnerStart():
          environment.logger.status('$event     ', newline: false);
          spinner = environment.logger.startSpinner();
        case RunnerProgress(done: true):
          spinner?.finish();
          spinner = null;
          environment.logger.clearLine();
          environment.logger.status(event);
        case RunnerProgress(done: false): {
          spinner?.finish();
          spinner = null;
          final String percent = '${event.percent.toStringAsFixed(1)}%';
          final String fraction = '(${event.completed}/${event.total})';
          final String prefix = '[${event.name}] $percent $fraction ';
          final String what = event.what;
          environment.logger.clearLine();
          environment.logger.status('$prefix$what', newline: false, fit: true);
        }
        default:
          spinner?.finish();
          spinner = null;
          environment.logger.status(event);
      }
    }

    final bool buildResult = await buildRunner.run(handler);
    return buildResult ? 0 : 1;
  }
}
