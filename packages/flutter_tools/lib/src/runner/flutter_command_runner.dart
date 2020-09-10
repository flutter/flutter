// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:completion/completion.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../globals.dart' as globals;
import '../tester/flutter_tester.dart';

const String kFlutterRootEnvironmentVariableName = 'FLUTTER_ROOT'; // should point to //flutter/ (root of flutter/flutter repo)
const String kFlutterEngineEnvironmentVariableName = 'FLUTTER_ENGINE'; // should point to //engine/src/ (root of flutter/engine repo)
const String kSnapshotFileName = 'flutter_tools.snapshot'; // in //flutter/bin/cache/
const String kFlutterToolsScriptFileName = 'flutter_tools.dart'; // in //flutter/packages/flutter_tools/bin/
const String kFlutterEnginePackageName = 'sky_engine';

class FlutterCommandRunner extends CommandRunner<void> {
  FlutterCommandRunner({ bool verboseHelp = false }) : super(
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
        help: 'Noisy logging, including all shell commands executed.\n'
              'If used with --help, shows hidden options.');
    argParser.addFlag('quiet',
        negatable: false,
        hide: !verboseHelp,
        help: 'Reduce the amount of output from some commands.');
    argParser.addFlag('wrap',
        negatable: true,
        hide: !verboseHelp,
        help: 'Toggles output word wrapping, regardless of whether or not the output is a terminal.',
        defaultsTo: true);
    argParser.addOption('wrap-column',
        hide: !verboseHelp,
        help: 'Sets the output wrap column. If not set, uses the width of the terminal. No '
            'wrapping occurs if not writing to a terminal. Use --no-wrap to turn off wrapping '
            'when connected to a terminal.',
        defaultsTo: null);
    argParser.addOption('device-id',
        abbr: 'd',
        help: 'Target device id or name (prefixes allowed).');
    argParser.addFlag('version',
        negatable: false,
        help: 'Reports the version of this tool.');
    argParser.addFlag('machine',
        negatable: false,
        hide: !verboseHelp,
        help: 'When used with the --version flag, outputs the information using JSON.');
    argParser.addFlag('color',
        negatable: true,
        hide: !verboseHelp,
        help: 'Whether to use terminal colors (requires support for ANSI escape sequences).',
        defaultsTo: true);
    argParser.addFlag('version-check',
        negatable: true,
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Allow Flutter to check for updates when this command runs.');
    argParser.addFlag('suppress-analytics',
        negatable: false,
        help: 'Suppress analytics reporting when this command runs.');

    String packagesHelp;
    bool showPackagesCommand;
    if (globals.fs.isFileSync(kPackagesFileName)) {
      packagesHelp = '(defaults to "$kPackagesFileName")';
      showPackagesCommand = verboseHelp;
    } else {
      packagesHelp = '(required, since the current directory does not contain a "$kPackagesFileName" file)';
      showPackagesCommand = true;
    }
    argParser.addOption('packages',
        hide: !showPackagesCommand,
        help: 'Path to your ".packages" file.\n$packagesHelp');

    argParser.addOption('flutter-root',
        hide: !verboseHelp,
        help: 'The root directory of the Flutter repository.\n'
              'Defaults to \$$kFlutterRootEnvironmentVariableName if set, otherwise uses the parent '
              'of the directory that the "flutter" script itself is in.');

    if (verboseHelp) {
      argParser.addSeparator('Local build selection options (not normally required):');
    }

    argParser.addOption('local-engine-src-path',
        hide: !verboseHelp,
        help: 'Path to your engine src directory, if you are building Flutter locally.\n'
              'Defaults to \$$kFlutterEngineEnvironmentVariableName if set, otherwise defaults to '
              'the path given in your pubspec.yaml dependency_overrides for $kFlutterEnginePackageName, '
              'if any, or, failing that, tries to guess at the location based on the value of the '
              '--flutter-root option.');

    argParser.addOption('local-engine',
        hide: !verboseHelp,
        help: 'Name of a build output within the engine out directory, if you are building Flutter locally.\n'
              'Use this to select a specific version of the engine if you have built multiple engine targets.\n'
              'This path is relative to --local-engine-src-path/out.');

    if (verboseHelp) {
      argParser.addSeparator('Options for testing the "flutter" tool itself:');
    }
    argParser.addFlag('show-test-device',
        negatable: false,
        hide: !verboseHelp,
        help: "List the special 'flutter-tester' device in device listings. "
              'This headless device is used to\ntest Flutter tooling.');
  }

  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = ArgParser(
    allowTrailingOptions: false,
    usageLineLength: globals.outputPreferences.wrapText ? globals.outputPreferences.wrapColumn : null,
  );

  @override
  String get usageFooter {
    return wrapText('Run "flutter help -v" for verbose help output, including less commonly used options.',
      columnWidth: globals.outputPreferences.wrapColumn,
      shouldWrap: globals.outputPreferences.wrapText,
    );
  }

  @override
  String get usage {
    final String usageWithoutDescription = super.usage.substring(description.length + 2);
    final String prefix = wrapText(description,
      shouldWrap: globals.outputPreferences.wrapText,
      columnWidth: globals.outputPreferences.wrapColumn,
    );
    return '$prefix\n\n$usageWithoutDescription';
  }

  static String get defaultFlutterRoot {
    if (globals.platform.environment.containsKey(kFlutterRootEnvironmentVariableName)) {
      return globals.platform.environment[kFlutterRootEnvironmentVariableName];
    }
    try {
      if (globals.platform.script.scheme == 'data') {
        return '../..'; // we're running as a test
      }

      if (globals.platform.script.scheme == 'package') {
        final String packageConfigPath = Uri.parse(globals.platform.packageConfig).toFilePath();
        return globals.fs.path.dirname(globals.fs.path.dirname(globals.fs.path.dirname(packageConfigPath)));
      }

      final String script = globals.platform.script.toFilePath();
      if (globals.fs.path.basename(script) == kSnapshotFileName) {
        return globals.fs.path.dirname(globals.fs.path.dirname(globals.fs.path.dirname(script)));
      }
      if (globals.fs.path.basename(script) == kFlutterToolsScriptFileName) {
        return globals.fs.path.dirname(globals.fs.path.dirname(globals.fs.path.dirname(globals.fs.path.dirname(script))));
      }

      // If run from a bare script within the repo.
      if (script.contains('flutter/packages/')) {
        return script.substring(0, script.indexOf('flutter/packages/') + 8);
      }
      if (script.contains('flutter/examples/')) {
        return script.substring(0, script.indexOf('flutter/examples/') + 8);
      }
    } on Exception catch (error) {
      // we don't have a logger at the time this is run
      // (which is why we don't use printTrace here)
      print(userMessages.runnerNoRoot('$error'));
    }
    return '.';
  }

  @override
  ArgResults parse(Iterable<String> args) {
    try {
      // This is where the CommandRunner would call argParser.parse(args). We
      // override this function so we can call tryArgsCompletion instead, so the
      // completion package can interrogate the argParser, and as part of that,
      // it calls argParser.parse(args) itself and returns the result.
      return tryArgsCompletion(args.toList(), argParser);
    } on ArgParserException catch (error) {
      if (error.commands.isEmpty) {
        usageException(error.message);
      }

      Command<void> command = commands[error.commands.first];
      for (final String commandName in error.commands.skip(1)) {
        command = command.subcommands[commandName];
      }

      command.usageException(error.message);
      return null;
    }
  }

  @override
  Future<void> run(Iterable<String> args) {
    // Have an invocation of 'build' print out it's sub-commands.
    // TODO(ianh): Move this to the Build command itself somehow.
    if (args.length == 1 && args.first == 'build') {
      args = <String>['build', '-h'];
    }

    return super.run(args);
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final Map<Type, dynamic> contextOverrides = <Type, dynamic>{};

    // Don't set wrapColumns unless the user said to: if it's set, then all
    // wrapping will occur at this width explicitly, and won't adapt if the
    // terminal size changes during a run.
    int wrapColumn;
    if (topLevelResults.wasParsed('wrap-column')) {
      try {
        wrapColumn = int.parse(topLevelResults['wrap-column'] as String);
        if (wrapColumn < 0) {
          throwToolExit(userMessages.runnerWrapColumnInvalid(topLevelResults['wrap-column']));
        }
      } on FormatException {
        throwToolExit(userMessages.runnerWrapColumnParseError(topLevelResults['wrap-column']));
      }
    }

    // If we're not writing to a terminal with a defined width, then don't wrap
    // anything, unless the user explicitly said to.
    final bool useWrapping = topLevelResults.wasParsed('wrap')
        ? topLevelResults['wrap'] as bool
        : globals.stdio.terminalColumns != null && topLevelResults['wrap'] as bool;
    contextOverrides[OutputPreferences] = OutputPreferences(
      wrapText: useWrapping,
      showColor: topLevelResults['color'] as bool,
      wrapColumn: wrapColumn,
    );

    if (topLevelResults['show-test-device'] as bool ||
        topLevelResults['device-id'] == FlutterTesterDevices.kTesterDeviceId) {
      FlutterTesterDevices.showFlutterTesterDevice = true;
    }

    // We must set Cache.flutterRoot early because other features use it (e.g.
    // enginePath's initializer uses it).
    final String flutterRoot = topLevelResults['flutter-root'] as String ?? defaultFlutterRoot;
    Cache.flutterRoot = globals.fs.path.normalize(globals.fs.path.absolute(flutterRoot));

    // Set up the tooling configuration.
    final String enginePath = await _findEnginePath(topLevelResults);
    if (enginePath != null) {
      contextOverrides.addAll(<Type, dynamic>{
        Artifacts: Artifacts.getLocalEngine(_findEngineBuildPath(topLevelResults, enginePath)),
      });
    }

    await context.run<void>(
      overrides: contextOverrides.map<Type, Generator>((Type type, dynamic value) {
        return MapEntry<Type, Generator>(type, () => value);
      }),
      body: () async {
        globals.logger.quiet = topLevelResults['quiet'] as bool;

        if (globals.platform.environment['FLUTTER_ALREADY_LOCKED'] != 'true') {
          await Cache.lock();
        }

        if (topLevelResults['suppress-analytics'] as bool) {
          globals.flutterUsage.suppressAnalytics = true;
        }

        try {
          await globals.flutterVersion.ensureVersionFile();
        } on FileSystemException catch (e) {
          globals.printError('Failed to write the version file to the artifact cache: "$e".');
          globals.printError('Please ensure you have permissions in the artifact cache directory.');
          throwToolExit('Failed to write the version file');
        }
        final bool machineFlag = topLevelResults['machine'] as bool;
        if (topLevelResults.command?.name != 'upgrade' && topLevelResults['version-check'] as bool && !machineFlag) {
          await globals.flutterVersion.checkFlutterVersionFreshness();
        }

        if (topLevelResults.wasParsed('packages')) {
          globalPackagesPath = globals.fs.path.normalize(globals.fs.path.absolute(topLevelResults['packages'] as String));
        }

        // See if the user specified a specific device.
        globals.deviceManager.specifiedDeviceId = topLevelResults['device-id'] as String;

        if (topLevelResults['version'] as bool) {
          globals.flutterUsage.sendCommand('version');
          globals.flutterVersion.fetchTagsAndUpdate();
          String status;
          if (machineFlag) {
            final Map<String, Object> jsonOut = globals.flutterVersion.toJson();
            if (jsonOut != null) {
              jsonOut['flutterRoot'] = Cache.flutterRoot;
            }
            status = const JsonEncoder.withIndent('  ').convert(jsonOut);
          } else {
            status = globals.flutterVersion.toString();
          }
          globals.printStatus(status);
          return;
        }

        if (machineFlag) {
          throwToolExit('The --machine flag is only valid with the --version flag.', exitCode: 2);
        }
        await super.runCommand(topLevelResults);
      },
    );
  }

  String _tryEnginePath(String enginePath) {
    if (globals.fs.isDirectorySync(globals.fs.path.join(enginePath, 'out'))) {
      return enginePath;
    }
    return null;
  }

  Future<String> _findEnginePath(ArgResults globalResults) async {
    String engineSourcePath = globalResults['local-engine-src-path'] as String
      ?? globals.platform.environment[kFlutterEngineEnvironmentVariableName];

    if (engineSourcePath == null && globalResults['local-engine'] != null) {
      try {
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          globals.fs.file(globalPackagesPath),
          logger: globals.logger,
          throwOnError: false,
        );
        Uri engineUri = packageConfig[kFlutterEnginePackageName]?.packageUriRoot;
        // Skip if sky_engine is the self-contained one.
        if (engineUri != null && globals.fs.identicalSync(globals.fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'pkg', kFlutterEnginePackageName, 'lib'), engineUri.path)) {
          engineUri = null;
        }
        // If sky_engine is specified and the engineSourcePath not set, try to determine the engineSourcePath by sky_engine setting.
        // A typical engineUri looks like: file://flutter-engine-local-path/src/out/host_debug_unopt/gen/dart-pkg/sky_engine/lib/
        if (engineUri?.path != null) {
          engineSourcePath = globals.fs.directory(engineUri.path)?.parent?.parent?.parent?.parent?.parent?.parent?.path;
          if (engineSourcePath != null && (engineSourcePath == globals.fs.path.dirname(engineSourcePath) || engineSourcePath.isEmpty)) {
            engineSourcePath = null;
            throwToolExit(userMessages.runnerNoEngineSrcDir(kFlutterEnginePackageName, kFlutterEngineEnvironmentVariableName),
              exitCode: 2);
          }
        }
      } on FileSystemException {
        engineSourcePath = null;
      } on FormatException {
        engineSourcePath = null;
      }
      // If engineSourcePath is still not set, try to determine it by flutter root.
      engineSourcePath ??= _tryEnginePath(globals.fs.path.join(globals.fs.directory(Cache.flutterRoot).parent.path, 'engine', 'src'));
    }

    if (engineSourcePath != null && _tryEnginePath(engineSourcePath) == null) {
      throwToolExit(userMessages.runnerNoEngineBuildDirInPath(engineSourcePath),
        exitCode: 2);
    }

    return engineSourcePath;
  }

  String _getHostEngineBasename(String localEngineBasename) {
    // Determine the host engine directory associated with the local engine:
    // Strip '_sim_' since there are no host simulator builds.
    String tmpBasename = localEngineBasename.replaceFirst('_sim_', '_');
    tmpBasename = tmpBasename.substring(tmpBasename.indexOf('_') + 1);
    // Strip suffix for various archs.
    final List<String> suffixes = <String>['_arm', '_arm64', '_x86', '_x64'];
    for (final String suffix in suffixes) {
      tmpBasename = tmpBasename.replaceFirst(RegExp('$suffix\$'), '');
    }
    return 'host_' + tmpBasename;
  }

  EngineBuildPaths _findEngineBuildPath(ArgResults globalResults, String enginePath) {
    String localEngine;
    if (globalResults['local-engine'] != null) {
      localEngine = globalResults['local-engine'] as String;
    } else {
      throwToolExit(userMessages.runnerLocalEngineRequired, exitCode: 2);
    }

    final String engineBuildPath = globals.fs.path.normalize(globals.fs.path.join(enginePath, 'out', localEngine));
    if (!globals.fs.isDirectorySync(engineBuildPath)) {
      throwToolExit(userMessages.runnerNoEngineBuild(engineBuildPath), exitCode: 2);
    }

    final String basename = globals.fs.path.basename(engineBuildPath);
    final String hostBasename = _getHostEngineBasename(basename);
    final String engineHostBuildPath = globals.fs.path.normalize(globals.fs.path.join(globals.fs.path.dirname(engineBuildPath), hostBasename));
    if (!globals.fs.isDirectorySync(engineHostBuildPath)) {
      throwToolExit(userMessages.runnerNoEngineBuild(engineHostBuildPath), exitCode: 2);
    }

    return EngineBuildPaths(targetEngine: engineBuildPath, hostEngine: engineHostBuildPath);
  }

  @visibleForTesting
  static void initFlutterRoot() {
    Cache.flutterRoot ??= defaultFlutterRoot;
  }

  /// Get the root directories of the repo - the directories containing Dart packages.
  List<String> getRepoRoots() {
    final String root = globals.fs.path.absolute(Cache.flutterRoot);
    // not bin, and not the root
    return <String>['dev', 'examples', 'packages'].map<String>((String item) {
      return globals.fs.path.join(root, item);
    }).toList();
  }

  /// Get all pub packages in the Flutter repo.
  List<Directory> getRepoPackages() {
    return getRepoRoots()
      .expand<String>((String root) => _gatherProjectPaths(root))
      .map<Directory>((String dir) => globals.fs.directory(dir))
      .toList();
  }

  static List<String> _gatherProjectPaths(String rootPath) {
    if (globals.fs.isFileSync(globals.fs.path.join(rootPath, '.dartignore'))) {
      return <String>[];
    }


    final List<String> projectPaths = globals.fs.directory(rootPath)
      .listSync(followLinks: false)
      .expand((FileSystemEntity entity) {
        if (entity is Directory && !globals.fs.path.split(entity.path).contains('.dart_tool')) {
          return _gatherProjectPaths(entity.path);
        }
        return <String>[];
      })
      .toList();

    if (globals.fs.isFileSync(globals.fs.path.join(rootPath, 'pubspec.yaml'))) {
      projectPaths.add(rootPath);
    }

    return projectPaths;
  }
}
