// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Directory;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:path/path.dart' as p;

import 'environment.dart';
import 'logger.dart';

/// A function that returns true or false when given a [BuilderConfig] and its
/// name.
typedef ConfigFilter = bool Function(String name, BuilderConfig config);

/// A function that returns true or false when given a [BuilderConfig] name
/// and a [Build].
typedef BuildFilter = bool Function(String configName, Build build);

/// Returns a filtered copy of [input] filtering out configs where test
/// returns false.
Map<String, BuilderConfig> filterBuilderConfigs(
    Map<String, BuilderConfig> input, ConfigFilter test) {
  return <String, BuilderConfig>{
    for (final MapEntry<String, BuilderConfig> entry in input.entries)
      if (test(entry.key, entry.value)) entry.key: entry.value,
  };
}

/// Returns a copy of [input] filtering out configs that are not runnable
/// on the current platform.
Map<String, BuilderConfig> runnableBuilderConfigs(
    Environment env, Map<String, BuilderConfig> input) {
  return filterBuilderConfigs(input, (String name, BuilderConfig config) {
    return config.canRunOn(env.platform);
  });
}

/// Returns a List of [Build] that match test.
List<Build> filterBuilds(Map<String, BuilderConfig> input, BuildFilter test) {
  return <Build>[
    for (final MapEntry<String, BuilderConfig> entry in input.entries)
      for (final Build build in entry.value.builds)
        if (test(entry.key, build)) build,
  ];
}

/// Returns a list of runnable builds.
List<Build> runnableBuilds(Environment env, Map<String, BuilderConfig> input) {
  return filterBuilds(input, (String configName, Build build) {
    return build.canRunOn(env.platform);
  });
}

/// Validates the list of builds.
/// Calls assert.
void debugCheckBuilds(List<Build> builds) {
  final Set<String> names = <String>{};

  for (final Build build in builds) {
    assert(!names.contains(build.name),
        'More than one build has the name ${build.name}');
    names.add(build.name);
  }
}

/// Build the build target in the environment.
Future<int> runBuild(
  Environment environment,
  Build build, {
  List<String> extraGnArgs = const <String>[],
}) async {
  // If RBE config files aren't in the tree, then disable RBE.
  final String rbeConfigPath = p.join(
    environment.engine.srcDir.path,
    'flutter',
    'build',
    'rbe',
  );
  final List<String> gnArgs = <String>[
    ...extraGnArgs,
    if (!io.Directory(rbeConfigPath).existsSync()) '--no-rbe',
  ];

  final BuildRunner buildRunner = BuildRunner(
    platform: environment.platform,
    processRunner: environment.processRunner,
    abi: environment.abi,
    engineSrcDir: environment.engine.srcDir,
    build: build,
    extraGnArgs: gnArgs,
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
      case RunnerProgress(done: false):
        {
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
