// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/experiments.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';

import '../generate/build.dart';
import 'base_command.dart';

/// A command that watches the file system for updates and rebuilds as
/// appropriate.
class WatchCommand extends BuildRunnerCommand {
  @override
  String get invocation => '${super.invocation} [directories]';

  @override
  String get name => 'watch';

  @override
  String get description =>
      'Builds the specified targets, watching the file system for updates and '
      'rebuilding as appropriate.';

  WatchCommand() {
    argParser.addFlag(usePollingWatcherOption,
        help: 'Use a polling watcher instead of the current platforms default '
            'watcher implementation. This should generally only be used if '
            'you are having problems with the default watcher, as it is '
            'generally less efficient.');
  }

  @override
  WatchOptions readOptions() => WatchOptions.fromParsedArgs(
      argResults, argResults.rest, packageGraph.root.name, this);

  @override
  Future<int> run() {
    var options = readOptions();
    return withEnabledExperiments(
        () => _run(options), options.enableExperiments);
  }

  Future<int> _run(WatchOptions options) async {
    var handler = await watch(
      builderApplications,
      deleteFilesByDefault: options.deleteFilesByDefault,
      enableLowResourcesMode: options.enableLowResourcesMode,
      configKey: options.configKey,
      buildDirs: options.buildDirs,
      outputSymlinksOnly: options.outputSymlinksOnly,
      packageGraph: packageGraph,
      trackPerformance: options.trackPerformance,
      skipBuildScriptCheck: options.skipBuildScriptCheck,
      verbose: options.verbose,
      builderConfigOverrides: options.builderConfigOverrides,
      isReleaseBuild: options.isReleaseBuild,
      logPerformanceDir: options.logPerformanceDir,
      directoryWatcherFactory: options.directoryWatcherFactory,
      buildFilters: options.buildFilters,
    );
    if (handler == null) return ExitCode.config.code;

    final completer = Completer<int>();
    handleBuildResultsStream(handler.buildResults, completer);
    return completer.future;
  }

  /// Listens to [buildResults], handling certain types of errors and completing
  /// [completer] appropriately.
  void handleBuildResultsStream(
      Stream<BuildResult> buildResults, Completer<int> completer) async {
    var subscription = buildResults.listen((result) {
      if (completer.isCompleted) return;
      if (result.status == BuildStatus.failure) {
        if (result.failureType == FailureType.buildScriptChanged) {
          completer.completeError(BuildScriptChangedException());
        } else if (result.failureType == FailureType.buildConfigChanged) {
          completer.completeError(BuildConfigChangedException());
        }
      }
    });
    await subscription.asFuture();
    if (!completer.isCompleted) completer.complete(ExitCode.success.code);
  }
}
