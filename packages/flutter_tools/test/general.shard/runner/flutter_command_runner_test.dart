// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/experimental/extension_arg_parser.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';
import 'utils.dart';

const _kFlutterRoot = '/flutter/flutter';
const _kProjectRoot = '/project';

void main() {
  group('FlutterCommandRunner', () {
    late MemoryFileSystem fileSystem;
    late Platform platform;
    late FakeAnalytics fakeAnalytics;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fileSystem.directory(_kFlutterRoot).createSync(recursive: true);
      fileSystem.directory(_kProjectRoot).createSync(recursive: true);
      fileSystem.currentDirectory = _kProjectRoot;
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );

      platform = FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
        version: '1 2 3 4 5',
      );
    });

    group('run', () {
      testUsingContext(
        'checks that Flutter installation is up-to-date',
        () async {
          final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['dummy']);

          expect(version.didCheckFlutterVersionFreshness, true);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          FlutterVersion: () => FakeFlutterVersion(),
          BotDetector: () => const FakeBotDetector(false),
          OutputPreferences: () => OutputPreferences.test(),
        },
      );

      testUsingContext(
        'does not check that Flutter installation is up-to-date with --machine flag',
        () async {
          final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['dummy', '--machine', '--version']);

          expect(version.didCheckFlutterVersionFreshness, false);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          FlutterVersion: () => FakeFlutterVersion(),
          OutputPreferences: () => OutputPreferences.test(),
        },
      );

      testUsingContext(
        'does not check that Flutter installation is up-to-date with --machine flag present anywhere',
        () async {
          final runner =
              createTestCommandRunner(_FlutterCommandWithItsOwnMachineFlag(verboseHelp: false))
                  as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['dummy-with-machine', '--machine']);

          expect(version.didCheckFlutterVersionFreshness, false);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          FlutterVersion: () => FakeFlutterVersion(),
          OutputPreferences: () => OutputPreferences.test(),
        },
      );

      testUsingContext(
        'does not check that Flutter installation is up-to-date with CI=true in environment',
        () async {
          final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['dummy', '--version']);

          expect(version.didCheckFlutterVersionFreshness, false);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          BotDetector: () => const FakeBotDetector(true),
        },
        initializeFlutterRoot: false,
      );

      testUsingContext(
        'checks that Flutter installation is up-to-date with CI=true and --machine when explicit --version-check',
        () async {
          final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['dummy', '--version', '--machine', '--version-check']);

          expect(version.didCheckFlutterVersionFreshness, true);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          BotDetector: () => const FakeBotDetector(true),
        },
        initializeFlutterRoot: false,
      );

      testUsingContext(
        'checks that Flutter installation is up-to-date if shell completion to terminal',
        () async {
          final FlutterCommand command = DummyFlutterCommand(name: 'bash-completion');
          final runner = createTestCommandRunner(command) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['bash-completion']);

          expect(version.didCheckFlutterVersionFreshness, true);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          FlutterVersion: () => FakeFlutterVersion(),
          BotDetector: () => const FakeBotDetector(false),
          Stdio: () => FakeStdio(hasFakeTerminal: true),
        },
      );

      testUsingContext(
        'does not check that Flutter installation is up-to-date if redirecting shell completion',
        () async {
          final FlutterCommand command = DummyFlutterCommand(name: 'bash-completion');
          final runner = createTestCommandRunner(command) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['bash-completion']);

          expect(version.didCheckFlutterVersionFreshness, false);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          FlutterVersion: () => FakeFlutterVersion(),
          BotDetector: () => const FakeBotDetector(false),
          Stdio: () => FakeStdio(hasFakeTerminal: false),
        },
      );

      testUsingContext(
        'Fetches tags when --version is used',
        () async {
          final runner =
              createTestCommandRunner(DummyFlutterCommand(), fakeAnalytics) as FlutterCommandRunner;
          final version = globals.flutterVersion as FakeFlutterVersion;

          await runner.run(<String>['--version']);
          expect(version.didFetchTagsAndUpdate, true);
          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.flutterCommandResult(
                commandPath: 'version',
                result: 'success',
                commandHasTerminal: false,
              ),
            ),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          FlutterVersion: () => FakeFlutterVersion(),
          OutputPreferences: () => OutputPreferences.test(),
          Analytics: () => fakeAnalytics,
        },
      );

      // TODO(bkonyi): remove when ready to serve DevTools from DDS.
      group('${FlutterGlobalOptions.kPrintDtd} flag', () {
        testUsingContext(
          'sets DevtoolsLauncher.printDtdUri to false when not present',
          () async {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            await runner.run(<String>[]);
            expect(DevtoolsLauncher.instance!.printDtdUri, false);
          },
          overrides: <Type, Generator>{
            DevtoolsLauncher: () => FakeDevtoolsLauncher()..dtdUri = Uri(),
          },
        );

        testUsingContext(
          'sets DevtoolsLauncher.printDtdUri to true when present',
          () async {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            await runner.run(<String>['--${FlutterGlobalOptions.kPrintDtd}']);
            expect(DevtoolsLauncher.instance!.printDtdUri, true);
          },
          overrides: <Type, Generator>{
            DevtoolsLauncher: () => FakeDevtoolsLauncher()..dtdUri = Uri(),
          },
        );
      });

      testUsingContext(
        "Doesn't crash on invalid package_config.json file",
        () async {
          final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
          fileSystem.file('pubspec.yaml').createSync();
          fileSystem.directory('.dart_tool').childFile('package_config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync('Not a valid package config');

          await runner.run(<String>['dummy']);
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          Platform: () => platform,
          OutputPreferences: () => OutputPreferences.test(),
        },
      );

      group('getRepoPackages', () {
        late String? oldFlutterRoot;

        setUp(() {
          oldFlutterRoot = Cache.flutterRoot;
          Cache.flutterRoot = _kFlutterRoot;
          fileSystem
              .directory(fileSystem.path.join(_kFlutterRoot, 'examples'))
              .createSync(recursive: true);
          fileSystem
              .directory(fileSystem.path.join(_kFlutterRoot, 'packages'))
              .createSync(recursive: true);
          fileSystem
              .directory(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'aatool'))
              .createSync(recursive: true);

          fileSystem
              .file(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'pubspec.yaml'))
              .createSync();
          fileSystem
              .file(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'aatool', 'pubspec.yaml'))
              .createSync();
        });

        tearDown(() {
          Cache.flutterRoot = oldFlutterRoot;
        });

        testUsingContext(
          '',
          () {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            final List<String> packagePaths = runner
                .getRepoPackages()
                .map((Directory d) => d.path)
                .toList();
            expect(packagePaths, <String>[
              fileSystem
                  .directory(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'aatool'))
                  .path,
              fileSystem.directory(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools')).path,
            ]);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Platform: () => platform,
            FlutterVersion: () => FakeFlutterVersion(),
            OutputPreferences: () => OutputPreferences.test(),
          },
        );
      });

      group('wrapping', () {
        testUsingContext(
          'checks that output wrapping is turned on when writing to a terminal',
          () async {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            final fakeCommand = FakeFlutterCommand();
            runner.addCommand(fakeCommand);
            await runner.run(<String>['fake']);
            expect(fakeCommand.preferences.wrapText, isTrue);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Stdio: () => FakeStdio(hasFakeTerminal: true),
            OutputPreferences: () => OutputPreferences.test(),
          },
          initializeFlutterRoot: false,
        );

        testUsingContext(
          'checks that output wrapping is turned off when not writing to a terminal',
          () async {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            final fakeCommand = FakeFlutterCommand();
            runner.addCommand(fakeCommand);
            await runner.run(<String>['fake']);
            expect(fakeCommand.preferences.wrapText, isFalse);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Stdio: () => FakeStdio(hasFakeTerminal: false),
            OutputPreferences: () => OutputPreferences.test(),
          },
          initializeFlutterRoot: false,
        );

        testUsingContext(
          'checks that output wrapping is turned off when set on the command line and writing to a terminal',
          () async {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            final fakeCommand = FakeFlutterCommand();
            runner.addCommand(fakeCommand);
            await runner.run(<String>['--no-wrap', 'fake']);
            expect(fakeCommand.preferences.wrapText, isFalse);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Stdio: () => FakeStdio(hasFakeTerminal: true),
            OutputPreferences: () => OutputPreferences.test(),
          },
          initializeFlutterRoot: false,
        );

        testUsingContext(
          'checks that output wrapping is turned on when set on the command line, but not writing to a terminal',
          () async {
            final runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
            final fakeCommand = FakeFlutterCommand();
            runner.addCommand(fakeCommand);
            await runner.run(<String>['--wrap', 'fake']);
            expect(fakeCommand.preferences.wrapText, isTrue);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Stdio: () => FakeStdio(hasFakeTerminal: false),
            OutputPreferences: () => OutputPreferences.test(),
          },
          initializeFlutterRoot: false,
        );
      });

      group('dynamic options initialization', () {
        testUsingContext(
          'initializes dynamic options when command is invoked directly',
          () async {
            final dynamicCommand = _FakeDynamicFlutterCommand();
            final runner = createTestCommandRunner(dynamicCommand) as FlutterCommandRunner;

            await runner.run(<String>['dynamic-cmd']);

            expect(dynamicCommand.didInitializeDynamicOptions, isTrue);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Platform: () => platform,
            FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
          },
        );

        testUsingContext(
          'initializes dynamic options when global flags precede command',
          () async {
            final dynamicCommand = _FakeDynamicFlutterCommand();
            final runner = createTestCommandRunner(dynamicCommand) as FlutterCommandRunner;

            await runner.run(<String>['--verbose', 'dynamic-cmd']);

            expect(dynamicCommand.didInitializeDynamicOptions, isTrue);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Platform: () => platform,
            FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
          },
        );

        testUsingContext(
          'initializes dynamic options when options with separate values precede command',
          () async {
            final dynamicCommand = _FakeDynamicFlutterCommand();
            final runner = createTestCommandRunner(dynamicCommand) as FlutterCommandRunner;

            await runner.run(<String>['-d', 'dummy-device', 'dynamic-cmd']);

            expect(dynamicCommand.didInitializeDynamicOptions, isTrue);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Platform: () => platform,
            FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
          },
        );

        testUsingContext(
          'initializes dynamic options when help command precedes dynamic command',
          () async {
            final dynamicCommand = _FakeDynamicFlutterCommand();
            final runner = createTestCommandRunner(dynamicCommand) as FlutterCommandRunner;

            await runner.run(<String>['help', '--verbose', 'dynamic-cmd']);

            expect(dynamicCommand.didInitializeDynamicOptions, isTrue);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Platform: () => platform,
            FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
          },
        );

        testUsingContext(
          'does not initialize dynamic options when tool extensions feature flag is disabled',
          () async {
            final dynamicCommand = _FakeDynamicFlutterCommand();
            final runner = createTestCommandRunner(dynamicCommand) as FlutterCommandRunner;

            await runner.run(<String>['dynamic-cmd']);

            expect(dynamicCommand.didInitializeDynamicOptions, isFalse);
          },
          overrides: <Type, Generator>{
            FileSystem: () => fileSystem,
            ProcessManager: () => FakeProcessManager.any(),
            Platform: () => platform,
            FeatureFlags: () => TestFeatureFlags(),
          },
        );
      });
    });
  });
}

class FakeFlutterCommand extends FlutterCommand {
  late OutputPreferences preferences;

  @override
  Future<FlutterCommandResult> runCommand() {
    preferences = globals.outputPreferences;
    return Future<FlutterCommandResult>.value(const FlutterCommandResult(ExitStatus.success));
  }

  @override
  String get description => '';

  @override
  String get name => 'fake';
}

class FakeStdio extends Stdio {
  FakeStdio({required this.hasFakeTerminal});

  final bool hasFakeTerminal;

  @override
  bool get hasTerminal => hasFakeTerminal;

  @override
  int? get terminalColumns => hasFakeTerminal ? 80 : null;

  @override
  int? get terminalLines => hasFakeTerminal ? 24 : null;
  @override
  bool get supportsAnsiEscapes => hasFakeTerminal;
}

final class _FlutterCommandWithItsOwnMachineFlag extends FlutterCommand {
  _FlutterCommandWithItsOwnMachineFlag({required bool verboseHelp}) {
    addMachineOutputFlag(verboseHelp: verboseHelp);
  }

  @override
  String get name => 'dummy-with-machine';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }

  @override
  String get description => 'does nothing, this time with --machine';
}

final class _FakeDynamicFlutterCommand extends FlutterCommand with ExtensionArgParserMixin {
  _FakeDynamicFlutterCommand();

  @override
  String get name => 'dynamic-cmd';

  @override
  String get description => 'A fake command with dynamic extension options';

  bool didInitializeDynamicOptions = false;

  @override
  Future<void> initializeDynamicOptions() async {
    didInitializeDynamicOptions = true;
  }

  @override
  String? get extensionArgParserCacheKey => 'dummy-cache-key';

  @override
  ArgParser buildDynamicArgParser(ArgParser dynamicParser) {
    dynamicParser.addFlag('dynamic-flag', help: 'A dynamically added flag');
    return dynamicParser;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}
