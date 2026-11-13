// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/isolated/native_assets/test/native_assets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:unified_analytics/unified_analytics.dart';

const _kOptionPackages = 'packages';
const _kOptionShell = 'shell';
const _kOptionTestDirectory = 'test-directory';
const _kOptionSdkRoot = 'sdk-root';
const _kOptionIcudtl = 'icudtl';
const _kOptionTests = 'tests';
const _kOptionCoverageDirectory = 'coverage-directory';
const _kRequiredOptions = <String>[
  _kOptionPackages,
  _kOptionShell,
  _kOptionSdkRoot,
  _kOptionIcudtl,
  _kOptionTests,
];
const _kOptionCoverage = 'coverage';
const _kOptionCoveragePath = 'coverage-path';

Future<void> main(List<String> args) async {
  final shutdownHooks = ShutdownHooks();
  final fs = LocalFileSystem(LocalSignals.instance, Signals.defaultExitSignals, shutdownHooks);
  try {
    final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_fuchsia_tester.');
    final ToolDependencies dependencies = await ToolDependencies.bootstrap(
      analytics: const NoOpAnalytics(),
      flutterRoot: tempDir.path,
      fs: fs,
      shutdownHooks: shutdownHooks,
      templateRenderer: const MustacheTemplateRenderer(),
    );
    await run(args, toolContext: dependencies.toolContext);
  } finally {
    await fs.dispose();
  }
  // TODO(ianh): There's apparently some sort of lost async task keeping the
  // process open. Remove the next line once that's been resolved.
  exit(exitCode);
}

Future<void> run(
  List<String> args, {
  required ToolContext toolContext,
  TestWrapper testWrapper = const TestWrapper(),
}) async {
  final ToolContext(
    :Artifacts artifacts,
    :FileSystem fs,
    :Platform platform,
    :FlutterProjectFactory projectFactory,
  ) = toolContext;

  final parser = ArgParser()
    ..addOption(_kOptionPackages, help: 'The .dart_tool/package_config.json file')
    ..addOption(_kOptionShell, help: 'The flutter_tester binary')
    ..addOption(_kOptionTestDirectory, help: 'Directory containing the tests')
    ..addOption(_kOptionSdkRoot, help: 'Path to the SDK platform files')
    ..addOption(_kOptionIcudtl, help: 'Path to the ICU data file')
    ..addOption(
      _kOptionTests,
      help: 'Path to json file that maps Dart test files to precompiled dill files',
    )
    ..addOption(
      _kOptionCoverageDirectory,
      help: 'The path to the directory that will have coverage collected',
    )
    ..addFlag(_kOptionCoverage, negatable: false, help: 'Whether to collect coverage information.')
    ..addOption(
      _kOptionCoveragePath,
      defaultsTo: 'coverage/lcov.info',
      help: 'Where to store coverage information (if coverage is enabled).',
    );
  final ArgResults argResults = parser.parse(args);
  if (_kRequiredOptions.any((String option) => !argResults.options.contains(option))) {
    throwToolExit('Missing option! All options must be specified.');
  }
  final String flutterTesterBinPath = fs.file(argResults[_kOptionShell]).resolveSymbolicLinksSync();
  if (!fs.isFileSync(flutterTesterBinPath)) {
    throwToolExit('Cannot find Flutter shell at $flutterTesterBinPath');
  }

  final Directory sdkRootSrc = fs.directory(argResults[_kOptionSdkRoot]);
  if (!fs.isDirectorySync(sdkRootSrc.path)) {
    throwToolExit('Cannot find SDK files at ${sdkRootSrc.path}');
  }
  Directory? coverageDirectory;
  final coverageDirectoryPath = argResults[_kOptionCoverageDirectory] as String?;
  if (coverageDirectoryPath != null) {
    if (!fs.isDirectorySync(coverageDirectoryPath)) {
      throwToolExit('Cannot find coverage directory at $coverageDirectoryPath');
    }
    coverageDirectory = fs.directory(coverageDirectoryPath);
  }

  // Put the tester shell where runTests expects it.
  // TODO(garymm): Switch to a Fuchsia-specific Artifacts impl.
  final Link testerDestLink = fs.link(artifacts.getArtifactPath(Artifact.flutterTester));
  testerDestLink.parent.createSync(recursive: true);
  testerDestLink.createSync(fs.path.absolute(flutterTesterBinPath));

  final Directory sdkRootDest = fs.directory(
    artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
  );
  sdkRootDest.createSync(recursive: true);
  for (final FileSystemEntity artifact in sdkRootSrc.listSync()) {
    fs.link(sdkRootDest.childFile(artifact.basename).path).createSync(artifact.path);
  }
  // TODO(tvolkert): Remove once flutter_tester no longer looks for this.
  fs.link(sdkRootDest.childFile('platform.dill').path).createSync('platform_strong.dill');

  Directory? testDirectory;
  CoverageCollector? collector;
  if (argResults[_kOptionCoverage] as bool? ?? false) {
    // If we have a specified coverage directory then accept all libraries by
    // setting libraryNames to null.
    final Set<String>? libraryNames = coverageDirectory != null
        ? null
        : <String>{projectFactory.fromDirectory(fs.currentDirectory).manifest.appName};
    final String packagesPath = fs.path.normalize(
      fs.path.absolute(argResults[_kOptionPackages] as String),
    );
    collector = CoverageCollector(
      libraryNames: libraryNames,
      packagesPath: packagesPath,
      resolver: await CoverageCollector.getResolver(packagesPath),
      toolContext: toolContext,
    );
    if (!argResults.options.contains(_kOptionTestDirectory)) {
      throwToolExit('Use of --coverage requires setting --test-directory');
    }
    testDirectory = fs.directory(argResults[_kOptionTestDirectory]);
  }

  final tests = <String, String>{};
  final jsonList = List<Map<String, Object?>>.from(
    (json.decode(fs.file(argResults[_kOptionTests]).readAsStringSync()) as List<Object?>)
        .cast<Map<String, Object?>>(),
  );
  for (final map in jsonList) {
    final String source = fs.file(map['source']).resolveSymbolicLinksSync();
    final String dill = fs.file(map['dill']).resolveSymbolicLinksSync();
    tests[source] = dill;
  }

  // TODO(dnfield): This should be injected.
  final buildInfo = BuildInfo(
    BuildMode.debug,
    '',
    treeShakeIcons: false,
    packageConfigPath: fs.path.normalize(fs.path.absolute(argResults[_kOptionPackages] as String)),
  );
  final debuggingOptions = DebuggingOptions.enabled(buildInfo);
  final testRunner = FlutterTestRunner(
    analytics: const NoOpAnalytics(),
    templateRenderer: const MustacheTemplateRenderer(),
    toolContext: toolContext,
  );
  exitCode = await testRunner.runTests(
    testWrapper,
    tests.keys.map(Uri.file).toList(),
    TestExecutionSpecification(
      debuggingOptions: debuggingOptions,
      buildInfo: buildInfo,
      watcher: collector,
      enableVmService: collector != null,
      precompiledDillFiles: tests,
      concurrency: math.max(1, platform.numberOfProcessors - 2),
      icudtlPath: fs.path.absolute(argResults[_kOptionIcudtl] as String),
      coverageDirectory: coverageDirectory,
      nativeAssetsBuilder: const TestCompilerNativeAssetsBuilderImpl(),
    ),
  );

  if (collector != null) {
    // collector expects currentDirectory to be the root of the dart
    // package (i.e. contains lib/ and test/ sub-dirs). In some cases,
    // test files may appear to be in the root directory.
    if (coverageDirectory == null) {
      fs.currentDirectory = testDirectory!.parent;
    } else {
      fs.currentDirectory = testDirectory;
    }
    if (!await collector.collectCoverageData(
      argResults[_kOptionCoveragePath] as String?,
      coverageDirectory: coverageDirectory,
    )) {
      throwToolExit('Failed to collect coverage data');
    }
  }
}
