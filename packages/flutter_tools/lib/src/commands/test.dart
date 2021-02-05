// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../devfs.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../test/coverage_collector.dart';
import '../test/event_printer.dart';
import '../test/runner.dart';
import '../test/test_wrapper.dart';
import '../test/watcher.dart';

class TestCommand extends FlutterCommand {
  TestCommand({
    bool verboseHelp = false,
    this.testWrapper = const TestWrapper(),
    this.testRunner = const FlutterTestRunner(),
  }) : assert(testWrapper != null) {
    requiresPubspecYaml();
    usesPubOption();
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    usesDartDefineOption();
    usesWebRendererOption();
    argParser
      ..addMultiOption('name',
        help: 'A regular expression matching substrings of the names of tests to run.',
        valueHelp: 'regexp',
        splitCommas: false,
      )
      ..addMultiOption('plain-name',
        help: 'A plain-text substring of the names of tests to run.',
        valueHelp: 'substring',
        splitCommas: false,
      )
      ..addOption('tags',
        abbr: 't',
        help: 'Run only tests associated with tags',
      )
      ..addOption('exclude-tags',
        abbr: 'x',
        help: 'Run only tests WITHOUT given tags',
      )
      ..addFlag('start-paused',
        defaultsTo: false,
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.\n'
              'You must specify a single test file to run, explicitly.\n'
              'Instructions for connecting with a debugger are printed to the '
              'console once the test has started.',
      )
      ..addFlag('disable-service-auth-codes',
        hide: !verboseHelp,
        defaultsTo: false,
        negatable: false,
        help: 'No longer require an authentication code to connect to the VM '
              'service (not recommended).',
      )
      ..addFlag('coverage',
        defaultsTo: false,
        negatable: false,
        help: 'Whether to collect coverage information.',
      )
      ..addFlag('merge-coverage',
        defaultsTo: false,
        negatable: false,
        help: 'Whether to merge coverage data with "coverage/lcov.base.info".\n'
              'Implies collecting coverage data. (Requires lcov)',
      )
      ..addFlag('ipv6',
        negatable: false,
        hide: true,
        help: 'Whether to use IPv6 for the test harness server socket.',
      )
      ..addOption('coverage-path',
        defaultsTo: 'coverage/lcov.info',
        help: 'Where to store coverage information (if coverage is enabled).',
      )
      ..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input\n'
              'and provide output and progress in machine friendly format.',
      )
      ..addFlag('update-goldens',
        negatable: false,
        help: 'Whether matchesGoldenFile() calls within your test methods should '
              'update the golden files rather than test for an existing match.',
      )
      ..addOption('concurrency',
        abbr: 'j',
        defaultsTo: math.max<int>(1, globals.platform.numberOfProcessors - 2).toString(),
        help: 'The number of concurrent test processes to run.',
        valueHelp: 'jobs',
      )
      ..addFlag('test-assets',
        defaultsTo: true,
        negatable: true,
        help: 'Whether to build the assets bundle for testing.\n'
              'Consider using --no-test-assets if assets are not required.',
      )
      // --platform is not supported to be used by Flutter developers. It only
      // exists to test the Flutter framework itself and may be removed entirely
      // in the future. Developers should either use plain `flutter test`, or
      // `package:integration_test` instead.
      ..addOption('platform',
        allowed: const <String>['tester', 'chrome'],
        hide: true,
        defaultsTo: 'tester',
      )
      ..addOption('test-randomize-ordering-seed',
        help: 'The seed to randomize the execution order of test cases.\n'
              'Must be a 32bit unsigned integer or "random".\n'
              'If "random", pick a random seed to use.\n'
              'If not passed, do not randomize test case execution order.',
      )
      ..addFlag('enable-vmservice',
        defaultsTo: false,
        hide: !verboseHelp,
        help: 'Enables the vmservice without --start-paused. This flag is '
              'intended for use with tests that will use dart:developer to '
              'interact with the vmservice at runtime.\n'
              'This flag is ignored if --start-paused or coverage are requested. '
              'The vmservice will be enabled no matter what in those cases.'
      )
      ..addOption('reporter',
        abbr: 'r',
        defaultsTo: 'compact',
        help: 'Set how to print test results.\n'
        '[compact] (default)         A single line, updated continuously.\n'
        '[expanded]                  A separate line for each update.\n'
        '[json]                      A machine-readable format (see https://dart.dev/go/test-docs/json_reporter.md).\n')
      ..addOption('timeout',
        help: 'The default test timeout. For example: 15s, 2x, none. Defaults to "30s"',
        defaultsTo: '30s',
      );
      addDdsOptions(verboseHelp: verboseHelp);
  }

  /// The interface for starting and configuring the tester.
  final TestWrapper testWrapper;

  /// Interface for running the tester process.
  final FlutterTestRunner testRunner;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    final Set<DevelopmentArtifact> results = <DevelopmentArtifact>{};
    if (stringArg('platform') == 'chrome') {
      results.add(DevelopmentArtifact.web);
    }
    return results;
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run Flutter unit tests for the current project.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!globals.fs.isFileSync('pubspec.yaml')) {
      throwToolExit(
        'Error: No pubspec.yaml file found in the current working directory.\n'
        'Run this command from the root of your project. Test files must be '
        "called *_test.dart and must reside in the package's 'test' "
        'directory (or one of its subdirectories).');
    }
    final FlutterProject flutterProject = FlutterProject.current();
    final bool buildTestAssets = boolArg('test-assets');
    final List<String> names = stringsArg('name');
    final List<String> plainNames = stringsArg('plain-name');
    final String tags = stringArg('tags');
    final String excludeTags = stringArg('exclude-tags');
    final BuildInfo buildInfo = await getBuildInfo(forcedBuildMode: BuildMode.debug);

    if (buildInfo.packageConfig['test_api'] == null) {
      globals.printError(
        '\n'
        'Error: cannot run without a dependency on either "package:flutter_test" or "package:test". '
        'Ensure the following lines are present in your pubspec.yaml:'
        '\n\n'
        'dev_dependencies:\n'
        '  flutter_test:\n'
        '    sdk: flutter\n',
      );
    }

    if (buildTestAssets && flutterProject.manifest.assets.isNotEmpty) {
      await _buildTestAsset();
    }

    List<String> files = argResults.rest.map<String>((String testPath) => globals.fs.path.absolute(testPath)).toList();

    final bool startPaused = boolArg('start-paused');
    if (startPaused && files.length != 1) {
      throwToolExit(
        'When using --start-paused, you must specify a single test file to run.',
        exitCode: 1,
      );
    }

    final int jobs = int.tryParse(stringArg('concurrency'));
    if (jobs == null || jobs <= 0 || !jobs.isFinite) {
      throwToolExit(
        'Could not parse -j/--concurrency argument. It must be an integer greater than zero.'
      );
    }

    if (files.isEmpty) {
      // We don't scan the entire package, only the test/ subdirectory, so that
      // files with names like like "hit_test.dart" don't get run.
      final Directory testDir = globals.fs.directory('test');
      if (!testDir.existsSync()) {
        throwToolExit('Test directory "${testDir.path}" not found.');
      }
      files = _findTests(testDir).toList();
      if (files.isEmpty) {
        throwToolExit(
            'Test directory "${testDir.path}" does not appear to contain any test files.\n'
            'Test files must be in that directory and end with the pattern "_test.dart".'
        );
      }
    } else {
      files = <String>[
        for (String path in files)
          if (globals.fs.isDirectorySync(path))
            ..._findTests(globals.fs.directory(path))
          else
            path,
      ];
    }

    final bool machine = boolArg('machine');
    CoverageCollector collector;
    if (boolArg('coverage') || boolArg('merge-coverage')) {
      final String projectName = flutterProject.manifest.appName;
      collector = CoverageCollector(
        verbose: !machine,
        libraryPredicate: (String libraryName) => libraryName.contains(projectName),
        // TODO(jonahwilliams): file bug for incorrect URI handling on windows
        packagesPath: globals.fs.file(buildInfo.packagesPath)
          .parent.parent.childFile('.packages').path
      );
    }

    TestWatcher watcher;
    if (machine) {
      watcher = EventPrinter(parent: collector);
    } else if (collector != null) {
      watcher = collector;
    }

    final bool disableServiceAuthCodes = boolArg('disable-service-auth-codes');

    final int result = await testRunner.runTests(
      testWrapper,
      files,
      names: names,
      plainNames: plainNames,
      tags: tags,
      excludeTags: excludeTags,
      watcher: watcher,
      enableObservatory: collector != null || startPaused || boolArg('enable-vmservice'),
      startPaused: startPaused,
      disableServiceAuthCodes: disableServiceAuthCodes,
      disableDds: disableDds,
      ipv6: boolArg('ipv6'),
      machine: machine,
      buildInfo: buildInfo,
      updateGoldens: boolArg('update-goldens'),
      concurrency: jobs,
      buildTestAssets: buildTestAssets,
      flutterProject: flutterProject,
      web: stringArg('platform') == 'chrome',
      randomSeed: stringArg('test-randomize-ordering-seed'),
      nullAssertions: boolArg(FlutterOptions.kNullAssertions),
      reporter: stringArg('reporter'),
      timeout: stringArg('timeout'),
    );

    if (collector != null) {
      final bool collectionResult = await collector.collectCoverageData(
        stringArg('coverage-path'),
        mergeCoverageData: boolArg('merge-coverage'),
      );
      if (!collectionResult) {
        throwToolExit(null);
      }
    }

    if (result != 0) {
      throwToolExit(null);
    }
    return FlutterCommandResult.success();
  }

  Future<void> _buildTestAsset() async {
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    final int build = await assetBundle.build(packagesPath: '.packages');
    if (build != 0) {
      throwToolExit('Error: Failed to build asset bundle');
    }
    if (_needRebuild(assetBundle.entries)) {
      await writeBundle(globals.fs.directory(globals.fs.path.join('build', 'unit_test_assets')),
          assetBundle.entries);
    }
  }

  bool _needRebuild(Map<String, DevFSContent> entries) {
    final File manifest = globals.fs.file(globals.fs.path.join('build', 'unit_test_assets', 'AssetManifest.json'));
    if (!manifest.existsSync()) {
      return true;
    }
    final DateTime lastModified = manifest.lastModifiedSync();
    final File pub = globals.fs.file('pubspec.yaml');
    if (pub.lastModifiedSync().isAfter(lastModified)) {
      return true;
    }

    for (final DevFSFileContent entry in entries.values.whereType<DevFSFileContent>()) {
      // Calling isModified to access file stats first in order for isModifiedAfter
      // to work.
      if (entry.isModified && entry.isModifiedAfter(lastModified)) {
        return true;
      }
    }
    return false;
  }
}

Iterable<String> _findTests(Directory directory) {
  return directory.listSync(recursive: true, followLinks: false)
      .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart') &&
      globals.fs.isFileSync(entity.path))
      .map((FileSystemEntity entity) => globals.fs.path.absolute(entity.path));
}
