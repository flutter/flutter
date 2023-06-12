// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:async/async.dart';
import 'package:build/experiments.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../generate/build.dart';
import 'base_command.dart';
import 'options.dart';

/// A command that does a single build and then runs tests using the compiled
/// assets.
class TestCommand extends BuildRunnerCommand {
  TestCommand(PackageGraph packageGraph)
      : super(
          // Use symlinks by default, if package:test supports it.
          symlinksDefault:
              _packageTestSupportsSymlinks(packageGraph) && !Platform.isWindows,
        );

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[build-arguments]')} '
      '[-- [test-arguments]]';

  @override
  String get name => 'test';

  @override
  String get description =>
      'Performs a single build of the test directory only and then runs tests '
      'using the compiled assets.';

  @override
  SharedOptions readOptions() {
    // This command doesn't allow specifying directories to build, instead it
    // always builds the `test` directory.
    //
    // Here we validate that [argResults.rest] is exactly equal to all the
    // arguments after the `--`.
    if (argResults.rest.isNotEmpty) {
      void throwUsageException() {
        throw UsageException(
            'The `test` command does not support positional args before the, '
            '`--` separator, which should separate build args from test args.',
            usage);
      }

      var separatorPos = argResults.arguments.indexOf('--');
      if (separatorPos < 0) {
        throwUsageException();
      }
      var expectedRest = argResults.arguments.skip(separatorPos + 1).toList();
      if (argResults.rest.length != expectedRest.length) {
        throwUsageException();
      }
      for (var i = 0; i < argResults.rest.length; i++) {
        if (expectedRest[i] != argResults.rest[i]) {
          throwUsageException();
        }
      }
    }

    return SharedOptions.fromParsedArgs(
        argResults, ['test'], packageGraph.root.name, this);
  }

  @override
  Future<int> run() async {
    SharedOptions options;
    // We always run our tests in a temp dir.
    var tempPath = Directory.systemTemp
        .createTempSync('build_runner_test')
        .absolute
        .uri
        .toFilePath();
    try {
      _ensureBuildTestDependency(packageGraph);
      options = readOptions();
      return withEnabledExperiments(
          () => _run(options, tempPath), options.enableExperiments);
    } on _BuildTestDependencyError catch (e) {
      stdout.writeln(e);
      return ExitCode.config.code;
    } finally {
      // Clean up the output dir.
      await Directory(tempPath).delete(recursive: true);
    }
  }

  Future<int> _run(SharedOptions options, String tempPath) async {
    var buildDirs = (options.buildDirs ?? <BuildDirectory>{})
      // Build test by default.
      ..add(BuildDirectory('test',
          outputLocation: OutputLocation(tempPath,
              useSymlinks: options.outputSymlinksOnly, hoist: false)));

    var result = await build(
      builderApplications,
      deleteFilesByDefault: options.deleteFilesByDefault,
      enableLowResourcesMode: options.enableLowResourcesMode,
      configKey: options.configKey,
      buildDirs: buildDirs,
      outputSymlinksOnly: options.outputSymlinksOnly,
      packageGraph: packageGraph,
      trackPerformance: options.trackPerformance,
      skipBuildScriptCheck: options.skipBuildScriptCheck,
      verbose: options.verbose,
      builderConfigOverrides: options.builderConfigOverrides,
      isReleaseBuild: options.isReleaseBuild,
      logPerformanceDir: options.logPerformanceDir,
      buildFilters: options.buildFilters,
    );

    if (result.status == BuildStatus.failure) {
      stdout.writeln('Skipping tests due to build failure');
      return result.failureType.exitCode;
    }

    return await _runTests(tempPath);
  }

  /// Runs tests using [precompiledPath] as the precompiled test directory.
  Future<int> _runTests(String precompiledPath) async {
    stdout.writeln('Running tests...\n');
    var extraTestArgs = argResults.rest;
    var testProcess = await Process.start(
        pubBinary,
        [
          'run',
          'test',
          '--precompiled',
          precompiledPath,
          ...extraTestArgs,
        ],
        mode: ProcessStartMode.inheritStdio);
    _ensureProcessExit(testProcess);
    return testProcess.exitCode;
  }
}

bool _packageTestSupportsSymlinks(PackageGraph packageGraph) {
  var testPackage = packageGraph['test'];
  if (testPackage == null) return false;
  var pubspecPath = p.join(testPackage.path, 'pubspec.yaml');
  var pubspec = Pubspec.parse(File(pubspecPath).readAsStringSync());
  if (pubspec.version == null) return false;
  return pubspec.version >= Version(1, 3, 0);
}

void _ensureBuildTestDependency(PackageGraph packageGraph) {
  if (!packageGraph.allPackages.containsKey('build_test')) {
    throw _BuildTestDependencyError();
  }
}

void _ensureProcessExit(Process process) {
  var signalsSub = _exitProcessSignals.listen((signal) async {
    stdout.writeln('waiting for subprocess to exit...');
  });
  process.exitCode.then((_) {
    signalsSub?.cancel();
    signalsSub = null;
  });
}

Stream<ProcessSignal> get _exitProcessSignals => Platform.isWindows
    ? ProcessSignal.sigint.watch()
    : StreamGroup.merge(
        [ProcessSignal.sigterm.watch(), ProcessSignal.sigint.watch()]);

class _BuildTestDependencyError extends StateError {
  _BuildTestDependencyError() : super('''
Missing dev dependency on package:build_test, which is required to run tests.

Please update your dev_dependencies section of your pubspec.yaml:

  dev_dependencies:
    build_runner: any
    build_test: any
    # If you need to run web tests, you will also need this dependency.
    build_web_compilers: any
''');
}
