// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../device.dart';
import '../globals.dart';
import '../usage.dart';
import '../version.dart';
import '../vmservice.dart';

const String kFlutterRootEnvironmentVariableName = 'FLUTTER_ROOT'; // should point to //flutter/ (root of flutter/flutter repo)
const String kFlutterEngineEnvironmentVariableName = 'FLUTTER_ENGINE'; // should point to //engine/src/ (root of flutter/engine repo)
const String kSnapshotFileName = 'flutter_tools.snapshot'; // in //flutter/bin/cache/
const String kFlutterToolsScriptFileName = 'flutter_tools.dart'; // in //flutter/packages/flutter_tools/bin/
const String kFlutterEnginePackageName = 'sky_engine';

class FlutterCommandRunner extends CommandRunner<Null> {
  FlutterCommandRunner({ bool verboseHelp: false }) : super(
    'flutter',
    'Manage your Flutter app development.\n'
      '\n'
      'Common commands:\n'
      '\n'
      '  flutter create <output directory>\n'
      '    Create a new Flutter project in the specified directory.\n'
      '\n'
      '  flutter run [options]\n'
      '    Run your Flutter application on an attached device or in an emulator.',
  ) {
    argParser.addFlag('verbose',
        abbr: 'v',
        negatable: false,
        help: 'Noisy logging, including all shell commands executed.');
    argParser.addFlag('quiet',
        negatable: false,
        hide: !verboseHelp,
        help: 'Reduce the amount of output from some commands.');
    argParser.addOption('device-id',
        abbr: 'd',
        help: 'Target device id or name (prefixes allowed).');
    argParser.addFlag('version',
        negatable: false,
        help: 'Reports the version of this tool.');
    argParser.addFlag('color',
        negatable: true,
        hide: !verboseHelp,
        help: 'Whether to use terminal colors.');
    argParser.addFlag('suppress-analytics',
        negatable: false,
        hide: !verboseHelp,
        help: 'Suppress analytics reporting when this command runs.');
    argParser.addFlag('bug-report',
        negatable: false,
        help:
            'Captures a bug report file to submit to the Flutter team '
            '(contains local paths, device\nidentifiers, and log snippets).');

    String packagesHelp;
    if (fs.isFileSync(kPackagesFileName))
      packagesHelp = '\n(defaults to "$kPackagesFileName")';
    else
      packagesHelp = '\n(required, since the current directory does not contain a "$kPackagesFileName" file)';
    argParser.addOption('packages',
        hide: !verboseHelp,
        help: 'Path to your ".packages" file.$packagesHelp');
    argParser.addOption('flutter-root',
        help: 'The root directory of the Flutter repository (uses \$$kFlutterRootEnvironmentVariableName if set).');

    if (verboseHelp)
      argParser.addSeparator('Local build selection options (not normally required):');

    argParser.addOption('local-engine-src-path',
        hide: !verboseHelp,
        help:
            'Path to your engine src directory, if you are building Flutter locally.\n'
            'Defaults to \$$kFlutterEngineEnvironmentVariableName if set, otherwise defaults to the path given in your pubspec.yaml\n'
            'dependency_overrides for $kFlutterEnginePackageName, if any, or, failing that, tries to guess at the location\n'
            'based on the value of the --flutter-root option.');

    argParser.addOption('local-engine',
        hide: !verboseHelp,
        help:
            'Name of a build output within the engine out directory, if you are building Flutter locally.\n'
            'Use this to select a specific version of the engine if you have built multiple engine targets.\n'
            'This path is relative to --local-engine-src-path/out.');
    argParser.addOption('record-to',
        hide: true,
        help:
            'Enables recording of process invocations (including stdout and stderr of all such invocations),\n'
            'and file system access (reads and writes).\n'
            'Serializes that recording to a directory with the path specified in this flag. If the\n'
            'directory does not already exist, it will be created.');
    argParser.addOption('replay-from',
        hide: true,
        help:
            'Enables mocking of process invocations by replaying their stdout, stderr, and exit code from\n'
            'the specified recording (obtained via --record-to). The path specified in this flag must refer\n'
            'to a directory that holds serialized process invocations structured according to the output of\n'
            '--record-to.');
  }

  @override
  String get usageFooter {
    return 'Run "flutter help -v" for verbose help output, including less commonly used options.';
  }

  static String get _defaultFlutterRoot {
    if (platform.environment.containsKey(kFlutterRootEnvironmentVariableName))
      return platform.environment[kFlutterRootEnvironmentVariableName];
    try {
      if (platform.script.scheme == 'data')
        return '../..'; // we're running as a test
      final String script = platform.script.toFilePath();
      if (fs.path.basename(script) == kSnapshotFileName)
        return fs.path.dirname(fs.path.dirname(fs.path.dirname(script)));
      if (fs.path.basename(script) == kFlutterToolsScriptFileName)
        return fs.path.dirname(fs.path.dirname(fs.path.dirname(fs.path.dirname(script))));

      // If run from a bare script within the repo.
      if (script.contains('flutter/packages/'))
        return script.substring(0, script.indexOf('flutter/packages/') + 8);
      if (script.contains('flutter/examples/'))
        return script.substring(0, script.indexOf('flutter/examples/') + 8);
    } catch (error) {
      // we don't have a logger at the time this is run
      // (which is why we don't use printTrace here)
      print('Unable to locate flutter root: $error');
    }
    return '.';
  }

  @override
  Future<Null> run(Iterable<String> args) {
    // Have an invocation of 'build' print out it's sub-commands.
    if (args.length == 1 && args.first == 'build')
      args = <String>['build', '-h'];

    return super.run(args);
  }

  @override
  Future<Null> runCommand(ArgResults globalResults) async {
    // Check for verbose.
    if (globalResults['verbose']) {
      // Override the logger.
      context.setVariable(Logger, new VerboseLogger(context[Logger]));
    }

    String recordTo = globalResults['record-to'];
    String replayFrom = globalResults['replay-from'];

    if (globalResults['bug-report']) {
      // --bug-report implies --record-to=<tmp_path>
      final Directory tmp = await const LocalFileSystem()
          .systemTempDirectory
          .createTemp('flutter_tools_');
      recordTo = tmp.path;

      // Record the arguments that were used to invoke this runner.
      final File manifest = tmp.childFile('MANIFEST.txt');
      final StringBuffer buffer = new StringBuffer()
        ..writeln('# arguments')
        ..writeln(globalResults.arguments)
        ..writeln()
        ..writeln('# rest')
        ..writeln(globalResults.rest);
      await manifest.writeAsString(buffer.toString(), flush: true);

      // ZIP the recording up once the recording has been serialized.
      addShutdownHook(() async {
        final File zipFile = getUniqueFile(fs.currentDirectory, 'bugreport', 'zip');
        os.zip(tmp, zipFile);
        printStatus(
            'Bug report written to ${zipFile.basename}.\n'
            'Note that this bug report contains local paths, device '
            'identifiers, and log snippets.');
      }, ShutdownStage.POST_PROCESS_RECORDING);
      addShutdownHook(() => tmp.delete(recursive: true), ShutdownStage.CLEANUP);
    }

    assert(recordTo == null || replayFrom == null);

    if (recordTo != null) {
      recordTo = recordTo.trim();
      if (recordTo.isEmpty)
        throwToolExit('record-to location not specified');
      enableRecordingProcessManager(recordTo);
      enableRecordingFileSystem(recordTo);
      await enableRecordingPlatform(recordTo);
      VMService.enableRecordingConnection(recordTo);
    }

    if (replayFrom != null) {
      replayFrom = replayFrom.trim();
      if (replayFrom.isEmpty)
        throwToolExit('replay-from location not specified');
      await enableReplayProcessManager(replayFrom);
      enableReplayFileSystem(replayFrom);
      await enableReplayPlatform(replayFrom);
      VMService.enableReplayConnection(replayFrom);
    }

    logger.quiet = globalResults['quiet'];

    if (globalResults.wasParsed('color'))
      logger.supportsColor = globalResults['color'];

    // We must set Cache.flutterRoot early because other features use it (e.g.
    // enginePath's initializer uses it).
    final String flutterRoot = globalResults['flutter-root'] ?? _defaultFlutterRoot;
    Cache.flutterRoot = fs.path.normalize(fs.path.absolute(flutterRoot));

    if (platform.environment['FLUTTER_ALREADY_LOCKED'] != 'true')
      await Cache.lock();

    if (globalResults['suppress-analytics'])
      flutterUsage.suppressAnalytics = true;

    _checkFlutterCopy();
    await FlutterVersion.instance.checkFlutterVersionFreshness();

    if (globalResults.wasParsed('packages'))
      PackageMap.globalPackagesPath = fs.path.normalize(fs.path.absolute(globalResults['packages']));

    // See if the user specified a specific device.
    deviceManager.specifiedDeviceId = globalResults['device-id'];

    // Set up the tooling configuration.
    final String enginePath = _findEnginePath(globalResults);
    if (enginePath != null) {
      Artifacts.useLocalEngine(enginePath, _findEngineBuildPath(globalResults, enginePath));
    }

    // The Android SDK could already have been set by tests.
    context.putIfAbsent(AndroidSdk, AndroidSdk.locateAndroidSdk);

    if (globalResults['version']) {
      flutterUsage.sendCommand('version');
      printStatus(FlutterVersion.instance.toString());
      return;
    }

    await super.runCommand(globalResults);
  }

  String _tryEnginePath(String enginePath) {
    if (fs.isDirectorySync(fs.path.join(enginePath, 'out')))
      return enginePath;
    return null;
  }

  String _findEnginePath(ArgResults globalResults) {
    String engineSourcePath = globalResults['local-engine-src-path'] ?? platform.environment[kFlutterEngineEnvironmentVariableName];

    if (engineSourcePath == null && globalResults['local-engine'] != null) {
      try {
        final Uri engineUri = new PackageMap(PackageMap.globalPackagesPath).map[kFlutterEnginePackageName];
        if (engineUri != null) {
          engineSourcePath = fs.path.dirname(fs.path.dirname(fs.path.dirname(fs.path.dirname(engineUri.path))));
          final bool dirExists = fs.isDirectorySync(fs.path.join(engineSourcePath, 'out'));
          if (engineSourcePath == '/' || engineSourcePath.isEmpty || !dirExists)
            engineSourcePath = null;
        }
      } on FileSystemException {
        engineSourcePath = null;
      } on FormatException {
        engineSourcePath = null;
      }

      engineSourcePath ??= _tryEnginePath(fs.path.join(Cache.flutterRoot, '../engine/src'));

      if (engineSourcePath == null) {
        printError('Unable to detect local Flutter engine build directory.\n'
            'Either specify a dependency_override for the $kFlutterEnginePackageName package in your pubspec.yaml and\n'
            'ensure --package-root is set if necessary, or set the \$$kFlutterEngineEnvironmentVariableName environment variable, or\n'
            'use --local-engine-src-path to specify the path to the root of your flutter/engine repository.');
        throw new ProcessExit(2);
      }
    }

    if (engineSourcePath != null && _tryEnginePath(engineSourcePath) == null) {
      printError('Unable to detect a Flutter engine build directory in $engineSourcePath.\n'
          'Please ensure that $engineSourcePath is a Flutter engine \'src\' directory and that\n'
          'you have compiled the engine in that directory, which should produce an \'out\' directory');
      throw new ProcessExit(2);
    }

    return engineSourcePath;
  }

  String _findEngineBuildPath(ArgResults globalResults, String enginePath) {
    String localEngine;
    if (globalResults['local-engine'] != null) {
      localEngine = globalResults['local-engine'];
    } else {
      printError('You must specify --local-engine if you are using a locally built engine.');
      throw new ProcessExit(2);
    }

    final String engineBuildPath = fs.path.normalize(fs.path.join(enginePath, 'out', localEngine));
    if (!fs.isDirectorySync(engineBuildPath)) {
      printError('No Flutter engine build found at $engineBuildPath.');
      throw new ProcessExit(2);
    }

    return engineBuildPath;
  }

  static void initFlutterRoot() {
    Cache.flutterRoot ??= _defaultFlutterRoot;
  }

  /// Get all pub packages in the Flutter repo.
  List<Directory> getRepoPackages() {
    return _gatherProjectPaths(fs.path.absolute(Cache.flutterRoot))
      .map((String dir) => fs.directory(dir))
      .toList();
  }

  static List<String> _gatherProjectPaths(String rootPath) {
    if (fs.isFileSync(fs.path.join(rootPath, '.dartignore')))
      return <String>[];

    if (fs.isFileSync(fs.path.join(rootPath, 'pubspec.yaml')))
      return <String>[rootPath];

    return fs.directory(rootPath)
      .listSync(followLinks: false)
      .expand((FileSystemEntity entity) {
        return entity is Directory ? _gatherProjectPaths(entity.path) : <String>[];
      })
      .toList();
  }

  /// Get the entry-points we want to analyze in the Flutter repo.
  List<Directory> getRepoAnalysisEntryPoints() {
    final String rootPath = fs.path.absolute(Cache.flutterRoot);
    final List<Directory> result = <Directory>[
      // not bin, and not the root
      fs.directory(fs.path.join(rootPath, 'dev')),
      fs.directory(fs.path.join(rootPath, 'examples')),
    ];
    // And since analyzer refuses to look at paths that end in "packages/":
    result.addAll(
      _gatherProjectPaths(fs.path.join(rootPath, 'packages'))
      .map<Directory>((String path) => fs.directory(path))
    );
    return result;
  }

  void _checkFlutterCopy() {
    // If the current directory is contained by a flutter repo, check that it's
    // the same flutter that is currently running.
    String directory = fs.path.normalize(fs.path.absolute(fs.currentDirectory.path));

    // Check if the cwd is a flutter dir.
    while (directory.isNotEmpty) {
      if (_isDirectoryFlutterRepo(directory)) {
        if (!_compareResolvedPaths(directory, Cache.flutterRoot)) {
          printError(
            'Warning: the \'flutter\' tool you are currently running is not the one from the current directory:\n'
            '  running Flutter  : ${Cache.flutterRoot}\n'
            '  current directory: $directory\n'
            'This can happen when you have multiple copies of flutter installed. Please check your system path to verify\n'
            'that you\'re running the expected version (run \'flutter --version\' to see which flutter is on your path).\n'
          );
        }

        break;
      }

      final String parent = fs.path.dirname(directory);
      if (parent == directory)
        break;
      directory = parent;
    }

    // Check that the flutter running is that same as the one referenced in the pubspec.
    if (fs.isFileSync(kPackagesFileName)) {
      final PackageMap packageMap = new PackageMap(kPackagesFileName);
      final Uri flutterUri = packageMap.map['flutter'];

      if (flutterUri != null && (flutterUri.scheme == 'file' || flutterUri.scheme == '')) {
        // .../flutter/packages/flutter/lib
        final Uri rootUri = flutterUri.resolve('../../..');
        final String flutterPath = fs.path.normalize(fs.file(rootUri).absolute.path);

        if (!fs.isDirectorySync(flutterPath)) {
          printError(
            'Warning! This package referenced a Flutter repository via the .packages file that is\n'
            'no longer available. The repository from which the \'flutter\' tool is currently\n'
            'executing will be used instead.\n'
            '  running Flutter tool: ${Cache.flutterRoot}\n'
            '  previous reference  : $flutterPath\n'
            'This can happen if you deleted or moved your copy of the Flutter repository, or\n'
            'if it was on a volume that is no longer mounted or has been mounted at a\n'
            'different location. Please check your system path to verify that you are running\n'
            'the expected version (run \'flutter --version\' to see which flutter is on your path).\n'
          );
        } else if (!_compareResolvedPaths(flutterPath, Cache.flutterRoot)) {
          printError(
            'Warning! The \'flutter\' tool you are currently running is from a different Flutter\n'
            'repository than the one last used by this package. The repository from which the\n'
            '\'flutter\' tool is currently executing will be used instead.\n'
            '  running Flutter tool: ${Cache.flutterRoot}\n'
            '  previous reference  : $flutterPath\n'
            'This can happen when you have multiple copies of flutter installed. Please check\n'
            'your system path to verify that you are running the expected version (run\n'
            '\'flutter --version\' to see which flutter is on your path).\n'
          );
        }
      }
    }
  }

  // Check if `bin/flutter` and `bin/cache/engine.stamp` exist.
  bool _isDirectoryFlutterRepo(String directory) {
    return
      fs.isFileSync(fs.path.join(directory, 'bin/flutter')) &&
      fs.isFileSync(fs.path.join(directory, 'bin/cache/engine.stamp'));
  }
}

bool _compareResolvedPaths(String path1, String path2) {
  path1 = fs.directory(fs.path.absolute(path1)).resolveSymbolicLinksSync();
  path2 = fs.directory(fs.path.absolute(path2)).resolveSymbolicLinksSync();

  return path1 == path2;
}
