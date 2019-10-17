// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../codegen.dart';
import '../dart/pub.dart';
import '../devfs.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../test/coverage_collector.dart';
import '../test/event_printer.dart';
import '../test/runner.dart';
import '../test/watcher.dart';

class TestCommand extends FastFlutterCommand {
  TestCommand({ bool verboseHelp = false }) {
    requiresPubspecYaml();
    usesPubOption();
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
        defaultsTo: math.max<int>(1, platform.numberOfProcessors - 2).toString(),
        help: 'The number of concurrent test processes to run.',
        valueHelp: 'jobs',
      )
      ..addFlag('test-assets',
        defaultsTo: true,
        negatable: true,
        help: 'Whether to build the assets bundle for testing.\n'
              'Consider using --no-test-assets if assets are not required.',
      )
      ..addOption('platform',
        allowed: const <String>['tester', 'chrome'],
        defaultsTo: 'tester',
        help: 'The platform to run the unit tests on. Defaults to "tester".',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    final Set<DevelopmentArtifact> results = <DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    };
    if (argResults['platform'] == 'chrome') {
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
    await cache.updateAll(await requiredArtifacts);
    if (!fs.isFileSync('pubspec.yaml')) {
      throwToolExit(
        'Error: No pubspec.yaml file found in the current working directory.\n'
        'Run this command from the root of your project. Test files must be '
        'called *_test.dart and must reside in the package\'s \'test\' '
        'directory (or one of its subdirectories).');
    }
    if (shouldRunPub) {
      await pub.get(context: PubContext.getVerifyContext(name), skipPubspecYamlCheck: true);
    }
    final bool buildTestAssets = argResults['test-assets'];
    final List<String> names = argResults['name'];
    final List<String> plainNames = argResults['plain-name'];
    final FlutterProject flutterProject = FlutterProject.current();

    if (buildTestAssets && flutterProject.manifest.assets.isNotEmpty) {
      await _buildTestAsset();
    }

    Iterable<String> files = argResults.rest.map<String>((String testPath) => fs.path.absolute(testPath)).toList();

    final bool startPaused = argResults['start-paused'];
    if (startPaused && files.length != 1) {
      throwToolExit(
        'When using --start-paused, you must specify a single test file to run.',
        exitCode: 1,
      );
    }

    final int jobs = int.tryParse(argResults['concurrency']);
    if (jobs == null || jobs <= 0 || !jobs.isFinite) {
      throwToolExit(
        'Could not parse -j/--concurrency argument. It must be an integer greater than zero.'
      );
    }

    Directory workDir;
    if (files.isEmpty) {
      // We don't scan the entire package, only the test/ subdirectory, so that
      // files with names like like "hit_test.dart" don't get run.
      workDir = fs.directory('test');
      if (!workDir.existsSync()) {
        throwToolExit('Test directory "${workDir.path}" not found.');
      }
      files = _findTests(workDir).toList();
      if (files.isEmpty) {
        throwToolExit(
            'Test directory "${workDir.path}" does not appear to contain any test files.\n'
            'Test files must be in that directory and end with the pattern "_test.dart".'
        );
      }
    } else {
      files = <String>[
        for (String path in files)
          if (fs.isDirectorySync(path))
            ..._findTests(fs.directory(path))
          else
            path,
      ];
    }

    CoverageCollector collector;
    if (argResults['coverage'] || argResults['merge-coverage']) {
      final String projectName = FlutterProject.current().manifest.appName;
      collector = CoverageCollector(
        libraryPredicate: (String libraryName) => libraryName.contains(projectName),
      );
    }

    final bool machine = argResults['machine'];
    if (collector != null && machine) {
      throwToolExit("The test command doesn't support --machine and coverage together");
    }

    TestWatcher watcher;
    if (collector != null) {
      watcher = collector;
    } else if (machine) {
      watcher = EventPrinter();
    }

    Cache.releaseLockEarly();

    // Run builders once before all tests.
    if (flutterProject.hasBuilders) {
      final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
      codegenDaemon.startBuild();
      await for (CodegenStatus status in codegenDaemon.buildResults) {
        if (status == CodegenStatus.Succeeded) {
          break;
        }
        if (status == CodegenStatus.Failed) {
          throwToolExit('Code generation failed.');
        }
      }
    }

    final bool disableServiceAuthCodes =
      argResults['disable-service-auth-codes'];

    final int result = await runTests(
      files,
      workDir: workDir,
      names: names,
      plainNames: plainNames,
      watcher: watcher,
      enableObservatory: collector != null || startPaused,
      startPaused: startPaused,
      disableServiceAuthCodes: disableServiceAuthCodes,
      ipv6: argResults['ipv6'],
      machine: machine,
      buildMode: BuildMode.debug,
      trackWidgetCreation: argResults['track-widget-creation'],
      updateGoldens: argResults['update-goldens'],
      concurrency: jobs,
      buildTestAssets: buildTestAssets,
      flutterProject: flutterProject,
      web: argResults['platform'] == 'chrome',
    );

    if (collector != null) {
      final bool collectionResult = await collector.collectCoverageData(
        argResults['coverage-path'],
        mergeCoverageData: argResults['merge-coverage'],
      );
      if (!collectionResult) {
        throwToolExit(null);
      }
    }

    if (result != 0) {
      throwToolExit(null);
    }
    return const FlutterCommandResult(ExitStatus.success);
  }

  Future<void> _buildTestAsset() async {
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    final int build = await assetBundle.build();
    if (build != 0) {
      throwToolExit('Error: Failed to build asset bundle');
    }
    if (_needRebuild(assetBundle.entries)) {
      await writeBundle(fs.directory(fs.path.join('build', 'unit_test_assets')),
          assetBundle.entries);
    }
  }

  bool _needRebuild(Map<String, DevFSContent> entries) {
    final File manifest = fs.file(fs.path.join('build', 'unit_test_assets', 'AssetManifest.json'));
    if (!manifest.existsSync()) {
      return true;
    }
    final DateTime lastModified = manifest.lastModifiedSync();
    final File pub = fs.file('pubspec.yaml');
    if (pub.lastModifiedSync().isAfter(lastModified)) {
      return true;
    }

    for (DevFSFileContent entry in entries.values.whereType<DevFSFileContent>()) {
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
      fs.isFileSync(entity.path))
      .map((FileSystemEntity entity) => fs.path.absolute(entity.path));
}
