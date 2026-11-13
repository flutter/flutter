// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../native_assets.dart';
import '../project.dart';
import '../web/chrome.dart';
import '../web/memory_fs.dart';
import 'flutter_platform.dart' as loader;
import 'flutter_web_platform.dart';
import 'test_time_recorder.dart';
import 'test_wrapper.dart';
import 'watcher.dart';
import 'web_test_compiler.dart';

/// Immutable specification of test filtering, selection, and sharding options for `package:test`.
@immutable
class TestFilterSpecification {
  const TestFilterSpecification({
    this.names = const <String>[],
    this.plainNames = const <String>[],
    this.tags = const <String>[],
    this.excludeTags = const <String>[],
    this.presets = const <String>[],
    this.runSkipped = false,
    this.shardIndex,
    this.totalShards,
  });

  final List<String> names;
  final List<String> plainNames;
  final List<String> tags;
  final List<String> excludeTags;
  final List<String> presets;
  final bool runSkipped;
  final int? shardIndex;
  final int? totalShards;
}

/// Immutable specification consolidating execution, reporting, and engine parameters
/// for [FlutterTestRunner].
@immutable
class TestExecutionSpecification {
  const TestExecutionSpecification({
    required this.debuggingOptions,
    required this.buildInfo,
    this.filter = const TestFilterSpecification(),
    this.enableVmService = false,
    this.machine = false,
    this.precompiledDillPath,
    this.precompiledDillFiles,
    this.updateGoldens = false,
    this.watcher,
    this.concurrency,
    this.testAssetDirectory,
    this.flutterProject,
    this.icudtlPath,
    this.coverageDirectory,
    this.web = false,
    this.randomSeed,
    this.reporter,
    this.fileReporter,
    this.timeout,
    this.ignoreTimeouts = false,
    this.failFast = false,
    this.integrationTestDevice,
    this.integrationTestUserIdentifier,
    this.testTimeRecorder,
    this.nativeAssetsBuilder,
  });

  final DebuggingOptions debuggingOptions;
  final BuildInfo buildInfo;
  final TestFilterSpecification filter;
  final bool enableVmService;
  final bool machine;
  final String? precompiledDillPath;
  final Map<String, String>? precompiledDillFiles;
  final bool updateGoldens;
  final TestWatcher? watcher;
  final int? concurrency;
  final String? testAssetDirectory;
  final FlutterProject? flutterProject;
  final String? icudtlPath;
  final Directory? coverageDirectory;
  final bool web;
  final String? randomSeed;
  final String? reporter;
  final String? fileReporter;
  final String? timeout;
  final bool ignoreTimeouts;
  final bool failFast;
  final Device? integrationTestDevice;
  final String? integrationTestUserIdentifier;
  final TestTimeRecorder? testTimeRecorder;
  final TestCompilerNativeAssetsBuilder? nativeAssetsBuilder;

  /// Computes the command-line arguments passed to `package:test`.
  List<String> toPackageTestArgs({required bool supportsColor, bool pauseAfterLoad = false}) {
    return <String>[
      if (!supportsColor) '--no-color',
      if (pauseAfterLoad) '--pause-after-load',
      if (machine) ...<String>['-r', 'json'] else if (reporter != null) ...<String>[
        '-r',
        reporter!,
      ],
      if (fileReporter != null) '--file-reporter=$fileReporter',
      if (timeout != null) ...<String>['--timeout', timeout!],
      if (ignoreTimeouts) '--ignore-timeouts',
      if (concurrency != null) '--concurrency=$concurrency',
      for (final String name in filter.names) ...<String>['--name', name],
      for (final String plainName in filter.plainNames) ...<String>['--plain-name', plainName],
      if (randomSeed != null) '--test-randomize-ordering-seed=$randomSeed',
      for (final String tag in filter.tags) ...<String>['--tags', tag],
      for (final String excludeTag in filter.excludeTags) ...<String>['--exclude-tags', excludeTag],
      for (final String preset in filter.presets) ...<String>['--preset', preset],
      if (failFast) '--fail-fast',
      if (filter.runSkipped) '--run-skipped',
      if (filter.totalShards != null) '--total-shards=${filter.totalShards}',
      if (filter.shardIndex != null) '--shard-index=${filter.shardIndex}',
      '--chain-stack-traces',
    ];
  }
}

/// Launching the `flutter_tester` process from the test runner.
interface class FlutterTestRunner {
  const FlutterTestRunner({
    required this._analytics,
    required this._templateRenderer,
    required this._toolContext,
  });

  final Analytics _analytics;
  final TemplateRenderer _templateRenderer;
  final ToolContext _toolContext;

  /// Runs tests using package:test and the Flutter engine.
  Future<int> runTests(
    TestWrapper testWrapper,
    List<Uri> testFiles,
    TestExecutionSpecification spec,
  ) async {
    final ToolContext(
      :Artifacts artifacts,
      :FileSystem fs,
      :Logger logger,
      :OperatingSystemUtils os,
      :Platform platform,
      :ProcessManager processManager,
      :AnsiTerminal terminal,
    ) = _toolContext;

    // Configure package:test to use the Flutter engine for child processes.
    final String flutterTesterBinPath = artifacts.getArtifactPath(Artifact.flutterTester);

    final TestExecutionSpecification(
      :DebuggingOptions debuggingOptions,
      :FlutterProject? flutterProject,
    ) = spec;

    // Compute the command-line arguments for package:test.
    final List<String> testArgs = spec.toPackageTestArgs(
      supportsColor: terminal.supportsColor,
      pauseAfterLoad: debuggingOptions.startPaused,
    );

    if (spec.web) {
      // Unsupported for general Flutter developers.
      // This is only used by the Flutter Framework tests.
      // See: https://github.com/flutter/flutter/pull/65984.
      final String tempBuildDir = fs.systemTempDirectory
          .createTempSync('flutter_test.')
          .absolute
          .uri
          .toFilePath();
      final WebMemoryFS result =
          await WebTestCompiler(analytics: _analytics, toolContext: _toolContext).initialize(
            projectDirectory: flutterProject!.directory,
            testOutputDir: tempBuildDir,
            testFiles: testFiles.map((Uri uri) => uri.toFilePath()).toList(),
            buildInfo: debuggingOptions.buildInfo,
            webRenderer: debuggingOptions.webConfig.renderer,
            useWasm: debuggingOptions.webConfig.useWasm,
          );
      testArgs
        ..add('--platform=chrome')
        ..add('--')
        ..addAll(testFiles.map((Uri uri) => uri.toString()));
      testWrapper.registerPlatformPlugin(<Runtime>[Runtime.chrome], () {
        return FlutterWebPlatform.start(
          flutterProject.directory.path,
          buildDirectory: fs.directory(tempBuildDir),
          buildInfo: debuggingOptions.buildInfo,
          chromiumLauncher: ChromiumLauncher(
            fileSystem: fs,
            platform: platform,
            processManager: processManager,
            operatingSystemUtils: os,
            browserFinder: findChromeExecutable,
            logger: logger,
          ),
          crossOriginIsolation: debuggingOptions.webConfig.crossOriginIsolation,
          flutterProject: flutterProject,
          flutterTesterBinPath: flutterTesterBinPath,
          templateRenderer: _templateRenderer,
          toolContext: _toolContext,
          useWasm: debuggingOptions.webConfig.useWasm,
          webMemoryFS: result,
          webRenderer: debuggingOptions.webConfig.renderer,
          pauseAfterLoad: debuggingOptions.startPaused,
          testTimeRecorder: spec.testTimeRecorder,
          updateGoldens: spec.updateGoldens,
        );
      });
      await testWrapper.main(testArgs);
      return exitCode;
    }

    testArgs
      ..add('--')
      ..addAll(testFiles.map((Uri uri) => uri.toString()));

    final InternetAddressType serverType = debuggingOptions.ipv6
        ? InternetAddressType.IPv6
        : InternetAddressType.IPv4;

    final loader.FlutterPlatform platformInstance = loader.installHook(
      buildInfo: spec.buildInfo,
      debuggingOptions: debuggingOptions,
      flutterTesterBinPath: flutterTesterBinPath,
      templateRenderer: _templateRenderer,
      toolContext: _toolContext,
      enableVmService: spec.enableVmService,
      flutterProject: flutterProject,
      icudtlPath: spec.icudtlPath,
      integrationTestDevice: spec.integrationTestDevice,
      integrationTestUserIdentifier: spec.integrationTestUserIdentifier,
      machine: spec.machine,
      nativeAssetsBuilder: spec.nativeAssetsBuilder,
      precompiledDillFiles: spec.precompiledDillFiles,
      precompiledDillPath: spec.precompiledDillPath,
      projectRootDirectory: fs.currentDirectory.uri,
      serverType: serverType,
      testAssetDirectory: spec.testAssetDirectory,
      testTimeRecorder: spec.testTimeRecorder,
      testWrapper: testWrapper,
      updateGoldens: spec.updateGoldens,
      watcher: spec.watcher,
    );

    try {
      logger.printTrace('running test package with arguments: $testArgs');
      await testWrapper.main(testArgs);

      // test.main() sets dart:io's exitCode global.
      logger.printTrace('test package returned with exit code $exitCode');

      return exitCode;
    } finally {
      await platformInstance.close();
    }
  }
}
