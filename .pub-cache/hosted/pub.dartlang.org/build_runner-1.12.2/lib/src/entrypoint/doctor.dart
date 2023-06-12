// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../logging/std_io_logging.dart';
import '../package_graph/build_config_overrides.dart';
import 'base_command.dart';

/// A command that validates the build environment.
class DoctorCommand extends BuildRunnerCommand {
  @override
  String get name => 'doctor';

  @override
  bool get hidden => true;

  @override
  String get description => 'Check for misconfiguration of the build.';

  @override
  Future<int> run() async {
    final options = readOptions();
    final verbose = options.verbose ?? false;
    Logger.root.level = verbose ? Level.ALL : Level.INFO;
    final logSubscription =
        Logger.root.onRecord.listen(stdIOLogListener(verbose: verbose));

    final config = await _loadBuilderDefinitions();

    var isOk = true;
    for (final builderApplication in builderApplications) {
      final builderOk = _checkBuildExtensions(builderApplication, config);
      isOk = isOk && builderOk;
    }

    if (isOk) {
      logger.info('No problems found!\n');
    }
    await logSubscription.cancel();
    return isOk ? ExitCode.success.code : ExitCode.config.code;
  }

  Future<Map<String, BuilderDefinition>> _loadBuilderDefinitions() async {
    final packageGraph = await PackageGraph.forThisPackage();
    final buildConfigOverrides = await findBuildConfigOverrides(
        packageGraph, null, FileBasedAssetReader(packageGraph));
    Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
      if (buildConfigOverrides.containsKey(package.name)) {
        return buildConfigOverrides[package.name];
      }
      try {
        return await BuildConfig.fromBuildConfigDir(package.name,
            package.dependencies.map((n) => n.name), package.path);
      } on ArgumentError catch (e) {
        logger.severe(
            'Failed to parse a `build.yaml` file for ${package.name}', e);
        return BuildConfig.useDefault(
            package.name, package.dependencies.map((n) => n.name));
      }
    }

    final allConfig = await Future.wait(
        packageGraph.allPackages.values.map(_packageBuildConfig));
    final allBuilders = <String, BuilderDefinition>{};
    for (final config in allConfig) {
      allBuilders.addAll(config.builderDefinitions);
    }
    return allBuilders;
  }

  /// Returns true of [builderApplication] has sane build extension
  /// configuration.
  ///
  /// If there are any problems they will be logged and `false` returned.
  bool _checkBuildExtensions(BuilderApplication builderApplication,
      Map<String, BuilderDefinition> config) {
    var phases = builderApplication.buildPhaseFactories
        .map((f) => f(PackageNode(null, null, null, null, isRoot: true),
            BuilderOptions.empty, InputSet.anything, InputSet.anything, true))
        .whereType<InBuildPhase>()
        .toList();
    if (phases.isEmpty) return true;
    if (!config.containsKey(builderApplication.builderKey)) return false;

    var problemFound = false;
    var allowed = Map.of(config[builderApplication.builderKey].buildExtensions);
    for (final phase in phases.whereType<InBuildPhase>()) {
      final extensions = phase.builder.buildExtensions;
      for (final extension in extensions.entries) {
        if (!allowed.containsKey(extension.key)) {
          logger.warning('Builder ${builderApplication.builderKey} '
              'uses input extension ${extension.key} '
              'which is not specified in the `build.yaml`');
          problemFound = true;
          continue;
        }
        final allowedOutputs = List.of(allowed[extension.key]);
        for (final output in extension.value) {
          if (!allowedOutputs.contains(output)) {
            logger.warning('Builder ${builderApplication.builderKey} '
                'outputs $output  from ${extension.key} '
                'which is not specified in the `build.yaml`');
            problemFound = true;
          }
          // Allow subsequent phases to use these outputs as inputs
          if (allowedOutputs.length > 1) {
            allowed.putIfAbsent(output, () => []).addAll(allowedOutputs);
          }
        }
      }
    }
    return !problemFound;
  }
}
