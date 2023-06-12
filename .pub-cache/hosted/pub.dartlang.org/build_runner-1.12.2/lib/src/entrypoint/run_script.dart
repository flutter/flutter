// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:build/experiments.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../generate/build.dart';
import 'base_command.dart';
import 'options.dart';

class RunCommand extends BuildRunnerCommand {
  @override
  String get name => 'run';

  @override
  String get description => 'Performs a single build, and executes '
      'a Dart script with the given arguments.';

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[build-arguments]')} '
      '<executable> [-- [script-arguments]]';

  @override
  SharedOptions readOptions() {
    // Here we validate that [argResults.rest] is exactly equal to all the
    // arguments after the `--`.

    var separatorPos = argResults.arguments.indexOf('--');

    if (separatorPos >= 0) {
      void throwUsageException() {
        throw UsageException(
            'The `run` command does not support positional args before the '
            '`--` separator which should separate build args from script args.',
            usage);
      }

      var expectedRest = argResults.arguments.skip(separatorPos + 1).toList();

      // Since we expect the first argument to be the name of a script,
      // we should skip it when comparing extra arguments.
      var effectiveRest = argResults.rest.skip(1).toList();

      if (effectiveRest.length != expectedRest.length) {
        throwUsageException();
      }

      for (var i = 0; i < effectiveRest.length; i++) {
        if (expectedRest[i] != effectiveRest[i]) {
          throwUsageException();
        }
      }
    }

    return SharedOptions.fromParsedArgs(
        argResults, [], packageGraph.root.name, this);
  }

  @override
  FutureOr<int> run() {
    var options = readOptions();
    return withEnabledExperiments(
        () => _run(options), options.enableExperiments);
  }

  FutureOr<int> _run(SharedOptions options) async {
    var logSubscription =
        Logger.root.onRecord.listen(stdIOLogListener(verbose: options.verbose));

    try {
      // Ensure that the user passed the name of a file to run.
      if (argResults.rest.isEmpty) {
        logger..severe('Must specify an executable to run.')..severe(usage);
        return ExitCode.usage.code;
      }

      var scriptName = argResults.rest[0];
      var passedArgs = argResults.rest.skip(1).toList();

      // Ensure the extension is .dart.
      if (p.extension(scriptName) != '.dart') {
        logger.severe('$scriptName is not a valid Dart file '
            'and cannot be run in the VM.');
        return ExitCode.usage.code;
      }

      // Create a temporary directory in which to execute the script.
      var tempPath = Directory.systemTemp
          .createTempSync('build_runner_run_script')
          .absolute
          .uri
          .toFilePath();

      // Create two ReceivePorts, so that we can quit when the isolate is done.
      //
      // Define these before starting the isolate, so that we can close
      // them if there is a spawn exception.
      ReceivePort onExit, onError;

      // Use a completer to determine the exit code.
      var exitCodeCompleter = Completer<int>();

      try {
        var buildDirs = (options.buildDirs ?? <BuildDirectory>{})
          ..add(BuildDirectory('',
              outputLocation: OutputLocation(tempPath,
                  useSymlinks: options.outputSymlinksOnly, hoist: false)));
        var result = await build(
          builderApplications,
          deleteFilesByDefault: options.deleteFilesByDefault,
          enableLowResourcesMode: options.enableLowResourcesMode,
          configKey: options.configKey,
          buildDirs: buildDirs,
          packageGraph: packageGraph,
          verbose: options.verbose,
          builderConfigOverrides: options.builderConfigOverrides,
          isReleaseBuild: options.isReleaseBuild,
          trackPerformance: options.trackPerformance,
          skipBuildScriptCheck: options.skipBuildScriptCheck,
          logPerformanceDir: options.logPerformanceDir,
          buildFilters: options.buildFilters,
        );

        if (result.status == BuildStatus.failure) {
          logger.warning('Skipping script run due to build failure');
          return result.failureType.exitCode;
        }

        // Find the path of the script to run.
        var scriptPath = p.join(tempPath, scriptName);
        var packageConfigPath = p.join(tempPath, '.packages');

        onExit = ReceivePort();
        onError = ReceivePort();

        // Cleanup after exit.
        onExit.listen((_) {
          // If no error was thrown, return 0.
          if (!exitCodeCompleter.isCompleted) exitCodeCompleter.complete(0);
        });

        // On an error, kill the isolate, and log the error.
        onError.listen((e) {
          onExit.close();
          onError.close();
          logger.severe('Unhandled error from script: $scriptName', e[0],
              StackTrace.fromString(e[1].toString()));
          if (!exitCodeCompleter.isCompleted) exitCodeCompleter.complete(1);
        });

        await Isolate.spawnUri(
          p.toUri(scriptPath),
          passedArgs,
          null,
          errorsAreFatal: true,
          onExit: onExit.sendPort,
          onError: onError.sendPort,
          packageConfig: p.toUri(packageConfigPath),
        );

        return await exitCodeCompleter.future;
      } on IsolateSpawnException catch (e) {
        logger.severe(
            'Could not spawn isolate. Ensure that your file is in a valid directory (i.e. "bin", "benchmark", "example", "test", "tool").',
            e);
        return ExitCode.ioError.code;
      } finally {
        // Clean up the output dir.
        var dir = Directory(tempPath);
        if (await dir.exists()) await dir.delete(recursive: true);

        onExit?.close();
        onError?.close();
        if (!exitCodeCompleter.isCompleted) {
          exitCodeCompleter.complete(ExitCode.success.code);
        }
      }
    } finally {
      await logSubscription.cancel();
    }
  }
}
