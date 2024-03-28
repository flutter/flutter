// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:engine_build_configs/engine_build_configs.dart';

import 'package:path/path.dart' as p;

import '../build_utils.dart';
import '../gn_utils.dart';
import 'command.dart';
import 'flags.dart';

// ignore: public_member_api_docs
final class QueryCommand extends CommandBase {
  // ignore: public_member_api_docs
  QueryCommand({
    required super.environment,
    required this.configs,
  }) {
    // Add options here that are common to all queries.
    argParser
      ..addFlag(
        allFlag,
        abbr: 'a',
        help: 'List all results, even when not relevant on this platform',
        negatable: false,
      )
      ..addOption(
        builderFlag,
        abbr: 'b',
        help: 'Restrict the query to a single builder.',
        allowed: <String>[
          for (final MapEntry<String, BuilderConfig> entry in configs.entries)
            if (entry.value.canRunOn(environment.platform)) entry.key,
        ],
        allowedHelp: <String, String>{
          // TODO(zanderso): Add human readable descriptions to the json files.
          for (final MapEntry<String, BuilderConfig> entry in configs.entries)
            if (entry.value.canRunOn(environment.platform))
              entry.key: entry.value.path,
        },
      );

    addSubcommand(QueryBuildersCommand(
      environment: environment,
      configs: configs,
    ));
    addSubcommand(QueryTestsCommand(
      environment: environment,
      configs: configs,
    ));
  }

  /// Build configurations loaded from the engine from under ci/builders.
  final Map<String, BuilderConfig> configs;

  @override
  String get name => 'query';

  @override
  String get description => 'Provides information about build configurations '
      'and tests.';
}

/// The 'query builders' command.
final class QueryBuildersCommand extends CommandBase {
  /// Constructs the 'query builders' command.
  QueryBuildersCommand({
    required super.environment,
    required this.configs,
  });

  /// Build configurations loaded from the engine from under ci/builders.
  final Map<String, BuilderConfig> configs;

  @override
  String get name => 'builders';

  @override
  String get description => 'Provides information about CI builder '
      'configurations';

  @override
  Future<int> run() async {
    // Loop through all configs, and log those that are compatible with the
    // current platform.
    final bool all = parent!.argResults![allFlag]! as bool;
    final String? builderName = parent!.argResults![builderFlag] as String?;
    final bool verbose = globalResults![verboseFlag]! as bool;
    if (!verbose) {
      environment.logger.status(
        'Add --verbose to see detailed information about each builder',
      );
      environment.logger.status('');
    }
    for (final String key in configs.keys) {
      if (builderName != null && key != builderName) {
        continue;
      }

      final BuilderConfig config = configs[key]!;
      if (!config.canRunOn(environment.platform) && !all) {
        continue;
      }

      environment.logger.status('"$key" builder:');
      for (final Build build in config.builds) {
        if (!build.canRunOn(environment.platform) && !all) {
          continue;
        }
        environment.logger.status('"${build.name}" config', indent: 3);
        if (!verbose) {
          continue;
        }
        environment.logger.status('gn flags:', indent: 6);
        for (final String flag in build.gn) {
          environment.logger.status(flag, indent: 9);
        }
        if (build.ninja.targets.isNotEmpty) {
          environment.logger.status('ninja targets:', indent: 6);
          for (final String target in build.ninja.targets) {
            environment.logger.status(target, indent: 9);
          }
        }
      }
    }
    return 0;
  }
}

/// The query tests command.
final class QueryTestsCommand extends CommandBase {
  /// Constructs the 'query tests' command.
  QueryTestsCommand({
    required super.environment,
    required this.configs,
  }) {
    builds = runnableBuilds(environment, configs);
    debugCheckBuilds(builds);
    addConfigOption(argParser, runnableBuilds(environment, configs));
  }

  /// Build configurations loaded from the engine from under ci/builders.
  final Map<String, BuilderConfig> configs;

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'tests';

  @override
  String get description => 'Provides information about test targets';

  @override
  Future<int> run() async {
    final String configName = argResults![configFlag] as String;
    final Build? build =
        builds.where((Build build) => build.name == configName).firstOrNull;
    if (build == null) {
      environment.logger.error('Could not find config $configName');
      return 1;
    }
    final Map<String, TestTarget> targets = await findTestTargets(environment,
        Directory(p.join(environment.engine.outDir.path, build.ninja.config)));
    for (final TestTarget target in targets.values) {
      environment.logger.status(target.label);
    }
    return 0;
  }
}
