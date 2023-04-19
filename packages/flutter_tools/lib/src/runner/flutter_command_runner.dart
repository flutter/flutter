// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:completion/completion.dart';
import 'package:file/file.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../tester/flutter_tester.dart';
import '../web/web_device.dart';

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
              'If used with "--help", shows hidden options. '
              'If used with "flutter doctor", shows additional diagnostic information. '
              '(Use "-vv" to force verbose logging in those cases.)');
    argParser.addFlag('prefixed-errors',
        negatable: false,
        help: 'Causes lines sent to stderr to be prefixed with "ERROR:".',
        hide: !verboseHelp);
    argParser.addFlag('quiet',
        negatable: false,
        hide: !verboseHelp,
        help: 'Reduce the amount of output from some commands.');
    argParser.addFlag('wrap',
        hide: !verboseHelp,
        help: 'Toggles output word wrapping, regardless of whether or not the output is a terminal.',
        defaultsTo: true);
    argParser.addOption('wrap-column',
        hide: !verboseHelp,
        help: 'Sets the output wrap column. If not set, uses the width of the terminal. No '
              'wrapping occurs if not writing to a terminal. Use "--no-wrap" to turn off wrapping '
              'when connected to a terminal.');
    argParser.addOption('device-id',
        abbr: 'd',
        help: 'Target device id or name (prefixes allowed).');
    argParser.addFlag('version',
        negatable: false,
        help: 'Reports the version of this tool.');
    argParser.addFlag('machine',
        negatable: false,
        hide: !verboseHelp,
        help: 'When used with the "--version" flag, outputs the information using JSON.');
    argParser.addFlag('color',
        hide: !verboseHelp,
        help: 'Whether to use terminal colors (requires support for ANSI escape sequences).',
        defaultsTo: true);
    argParser.addFlag('version-check',
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Allow Flutter to check for updates when this command runs.');
    argParser.addFlag('suppress-analytics',
        negatable: false,
        help: 'Suppress analytics reporting when this command runs.');
    argParser.addFlag('disable-telemetry',
        negatable: false,
        help: 'Disable telemetry reporting when this command runs.');
    argParser.addOption('packages',
        hide: !verboseHelp,
        help: 'Path to your "package_config.json" file.');
    if (verboseHelp) {
      argParser.addSeparator('Local build selection options (not normally required):');
    }

    argParser.addOption('local-engine-src-path',
        hide: !verboseHelp,
        help: 'Path to your engine src directory, if you are building Flutter locally.\n'
              'Defaults to \$$kFlutterEngineEnvironmentVariableName if set, otherwise defaults to '
              'the path given in your pubspec.yaml dependency_overrides for $kFlutterEnginePackageName, '
              'if any.');

    argParser.addOption('local-engine',
        hide: !verboseHelp,
        help: 'Name of a build output within the engine out directory, if you are building Flutter locally.\n'
              'Use this to select a specific version of the engine if you have built multiple engine targets.\n'
              'This path is relative to "--local-engine-src-path" (see above).');

    argParser.addOption('local-web-sdk',
        hide: !verboseHelp,
        help: 'Name of a build output within the engine out directory, if you are building Flutter locally.\n'
              'Use this to select a specific version of the web sdk if you have built multiple engine targets.\n'
              'This path is relative to "--local-engine-src-path" (see above).');

    if (verboseHelp) {
      argParser.addSeparator('Options for testing the "flutter" tool itself:');
    }
    argParser.addFlag('show-test-device',
        negatable: false,
        hide: !verboseHelp,
        help: 'List the special "flutter-tester" device in device listings. '
              'This headless device is used to test Flutter tooling.');
    argParser.addFlag('show-web-server-device',
        negatable: false,
        hide: !verboseHelp,
        help: 'List the special "web-server" device in device listings.',
    );
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

      Command<void>? command = commands[error.commands.first];
      for (final String commandName in error.commands.skip(1)) {
        command = command?.subcommands[commandName];
      }

      command!.usageException(error.message);
    }
  }

  @override
  Future<void> run(Iterable<String> args) {
    // Have an invocation of 'build' print out it's sub-commands.
    // TODO(ianh): Move this to the Build command itself somehow.
    if (args.length == 1) {
      if (args.first == 'build') {
        args = <String>['build', '-h'];
      } else if (args.first == 'custom-devices') {
        args = <String>['custom-devices', '-h'];
      }
    }

    return super.run(args);
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final Map<Type, Object?> contextOverrides = <Type, Object?>{};

    // If the disable-telemetry flag has been passed, return out
    if (topLevelResults.wasParsed('disable-telemetry')) {
      return;
    }

    // Don't set wrapColumns unless the user said to: if it's set, then all
    // wrapping will occur at this width explicitly, and won't adapt if the
    // terminal size changes during a run.
    int? wrapColumn;
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
      showColor: topLevelResults['color'] as bool?,
      wrapColumn: wrapColumn,
    );

    if (((topLevelResults['show-test-device'] as bool?) ?? false)
        || topLevelResults['device-id'] == FlutterTesterDevices.kTesterDeviceId) {
      FlutterTesterDevices.showFlutterTesterDevice = true;
    }
    if (((topLevelResults['show-web-server-device'] as bool?) ?? false)
        || topLevelResults['device-id'] == WebServerDevice.kWebServerDeviceId) {
      WebServerDevice.showWebServerDevice = true;
    }

    // Set up the tooling configuration.
    final EngineBuildPaths? engineBuildPaths = await globals.localEngineLocator?.findEnginePath(
      engineSourcePath: topLevelResults['local-engine-src-path'] as String?,
      localEngine: topLevelResults['local-engine'] as String?,
      localWebSdk: topLevelResults['local-web-sdk'] as String?,
      packagePath: topLevelResults['packages'] as String?,
    );
    if (engineBuildPaths != null) {
      contextOverrides.addAll(<Type, Object?>{
        Artifacts: Artifacts.getLocalEngine(engineBuildPaths),
      });
    }

    await context.run<void>(
      overrides: contextOverrides.map<Type, Generator>((Type type, Object? value) {
        return MapEntry<Type, Generator>(type, () => value);
      }),
      body: () async {
        globals.logger.quiet = (topLevelResults['quiet'] as bool?) ?? false;

        if (globals.platform.environment['FLUTTER_ALREADY_LOCKED'] != 'true') {
          await globals.cache.lock();
        }

        if ((topLevelResults['suppress-analytics'] as bool?) ?? false) {
          globals.flutterUsage.suppressAnalytics = true;
        }

        globals.flutterVersion.ensureVersionFile();
        final bool machineFlag = topLevelResults['machine'] as bool? ?? false;
        final bool ci = await globals.botDetector.isRunningOnBot;
        final bool redirectedCompletion = !globals.stdio.hasTerminal &&
            (topLevelResults.command?.name ?? '').endsWith('-completion');
        final bool isMachine = machineFlag || ci || redirectedCompletion;
        final bool versionCheckFlag = topLevelResults['version-check'] as bool? ?? false;
        final bool explicitVersionCheckPassed = topLevelResults.wasParsed('version-check') && versionCheckFlag;

        if (topLevelResults.command?.name != 'upgrade' &&
            (explicitVersionCheckPassed || (versionCheckFlag && !isMachine))) {
          await globals.flutterVersion.checkFlutterVersionFreshness();
        }

        // See if the user specified a specific device.
        final String? specifiedDeviceId = topLevelResults['device-id'] as String?;
        if (specifiedDeviceId != null) {
          globals.deviceManager?.specifiedDeviceId = specifiedDeviceId;
        }

        if ((topLevelResults['version'] as bool?) ?? false) {
          globals.flutterUsage.sendCommand('version');
          globals.flutterVersion.fetchTagsAndUpdate();
          String status;
          if (machineFlag) {
            final Map<String, Object> jsonOut = globals.flutterVersion.toJson();
            jsonOut['flutterRoot'] = Cache.flutterRoot!;
            status = const JsonEncoder.withIndent('  ').convert(jsonOut);
          } else {
            status = globals.flutterVersion.toString();
          }
          globals.printStatus(status);
          return;
        }
        if (machineFlag && topLevelResults.command?.name != 'analyze') {
          throwToolExit('The "--machine" flag is only valid with the "--version" flag or the "analyze --suggestions" command.', exitCode: 2);
        }
        await super.runCommand(topLevelResults);
      },
    );
  }

  /// Get the root directories of the repo - the directories containing Dart packages.
  List<String> getRepoRoots() {
    final String root = globals.fs.path.absolute(Cache.flutterRoot!);
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
