// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart' as fakes;
import '../../src/test_flutter_command_runner.dart';

void main() {
  late Java fakeJava;
  late FakeAndroidStudio fakeAndroidStudio;
  late FakeAndroidSdk fakeAndroidSdk;
  late FakeFlutterVersion fakeFlutterVersion;
  late FakeAnalytics fakeAnalytics;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fakeJava = fakes.FakeJava();
    fakeAndroidStudio = FakeAndroidStudio();
    fakeAndroidSdk = FakeAndroidSdk();
    fakeFlutterVersion = FakeFlutterVersion();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: MemoryFileSystem.test(),
      fakeFlutterVersion: fakes.FakeFlutterVersion(),
    );
  });

  group('config', () {
    testUsingContext('prints all settings with --list', () async {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--list']);
      expect(
        testLogger.statusText,
        'All Settings:\n'
        '${featureFlags.allFeatures.where((Feature e) => e.configSetting != null).map((Feature e) => '  ${e.configSetting}: (Not set)').join('\n')}'
        '\n\n',
      );
    });

    testUsingContext('prints default values with --help', () async {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--help']);
      expect(testLogger.statusText, contains('(defaults to on)'));
    });

    testUsingContext('throws error on excess arguments', () {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(
        () => commandRunner.run(<String>[
          'config',
          '--android-studio-dir=/opt/My',
          'Android',
          'Studio',
        ]),
        throwsToolExit(),
      );
      expect(fakeAnalytics.sentEvents, isEmpty);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext(
      'machine flag',
      () async {
        final ConfigCommand command = createConfigCommand();
        await command.handleMachine();

        expect(testLogger.statusText, isNotEmpty);
        final dynamic jsonObject = json.decode(testLogger.statusText);
        expect(jsonObject, const TypeMatcher<Map<String, dynamic>>());
        if (jsonObject is Map<String, dynamic>) {
          expect(jsonObject['android-studio-dir'], fakeAndroidStudio.directory);
          expect(jsonObject['android-sdk'], fakeAndroidSdk.directory.path);
          expect(jsonObject['jdk-dir'], fakeJava.javaHome);
        }
        expect(fakeAnalytics.sentEvents, isEmpty);
      },
      overrides: <Type, Generator>{
        AndroidStudio: () => fakeAndroidStudio,
        AndroidSdk: () => fakeAndroidSdk,
        Java: () => fakeJava,
        Analytics: () => fakeAnalytics,
      },
    );

    testUsingContext('Can set build-dir', () async {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--build-dir=foo']);

      expect(getBuildDirectory(), 'foo');
      expect(fakeAnalytics.sentEvents, isEmpty);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext('throws error on absolute path to build-dir', () async {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(() => commandRunner.run(<String>['config', '--build-dir=/foo']), throwsToolExit());
      expect(fakeAnalytics.sentEvents, isEmpty);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext(
      'allows setting and removing feature flags',
      () async {
        final ConfigCommand configCommand = createConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>[
          'config',
          '--enable-android',
          '--enable-ios',
          '--enable-web',
          '--enable-linux-desktop',
          '--enable-windows-desktop',
          '--enable-macos-desktop',
        ]);

        expect(globals.config.getValue('enable-android'), true);
        expect(globals.config.getValue('enable-ios'), true);
        expect(globals.config.getValue('enable-web'), true);
        expect(globals.config.getValue('enable-linux-desktop'), true);
        expect(globals.config.getValue('enable-windows-desktop'), true);
        expect(globals.config.getValue('enable-macos-desktop'), true);

        await commandRunner.run(<String>['config', '--clear-features']);

        expect(globals.config.getValue('enable-android'), null);
        expect(globals.config.getValue('enable-ios'), null);
        expect(globals.config.getValue('enable-web'), null);
        expect(globals.config.getValue('enable-linux-desktop'), null);
        expect(globals.config.getValue('enable-windows-desktop'), null);
        expect(globals.config.getValue('enable-macos-desktop'), null);

        await commandRunner.run(<String>[
          'config',
          '--no-enable-android',
          '--no-enable-ios',
          '--no-enable-web',
          '--no-enable-linux-desktop',
          '--no-enable-windows-desktop',
          '--no-enable-macos-desktop',
        ]);

        expect(globals.config.getValue('enable-android'), false);
        expect(globals.config.getValue('enable-ios'), false);
        expect(globals.config.getValue('enable-web'), false);
        expect(globals.config.getValue('enable-linux-desktop'), false);
        expect(globals.config.getValue('enable-windows-desktop'), false);
        expect(globals.config.getValue('enable-macos-desktop'), false);
        expect(fakeAnalytics.sentEvents, isEmpty);
      },
      overrides: <Type, Generator>{
        AndroidStudio: () => fakeAndroidStudio,
        AndroidSdk: () => fakeAndroidSdk,
        Analytics: () => fakeAnalytics,
      },
    );

    testUsingContext('warns the user to reload IDE', () async {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--enable-web']);

      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('You may need to restart any open editors'),
      );
    });

    testUsingContext(
      'displays which config settings are available on stable',
      () async {
        fakeFlutterVersion.channel = 'stable';
        final ConfigCommand configCommand = createConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>[
          'config',
          '--enable-web',
          '--enable-linux-desktop',
          '--enable-windows-desktop',
          '--enable-macos-desktop',
        ]);

        await commandRunner.run(<String>['config', '--list']);

        expect(testLogger.statusText, containsIgnoringWhitespace('enable-web: true'));
        expect(testLogger.statusText, containsIgnoringWhitespace('enable-linux-desktop: true'));
        expect(testLogger.statusText, containsIgnoringWhitespace('enable-windows-desktop: true'));
        expect(testLogger.statusText, containsIgnoringWhitespace('enable-macos-desktop: true'));
        expect(fakeAnalytics.sentEvents, isEmpty);
      },
      overrides: <Type, Generator>{
        AndroidStudio: () => fakeAndroidStudio,
        AndroidSdk: () => fakeAndroidSdk,
        FlutterVersion: () => fakeFlutterVersion,
        Analytics: () => fakeAnalytics,
      },
    );

    testUsingContext('analytics flag enables/disables analytics', () async {
      final ConfigCommand configCommand = createConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(fakeAnalytics.telemetryEnabled, true);

      await commandRunner.run(<String>['config', '--no-analytics']);
      expect(fakeAnalytics.telemetryEnabled, false);

      await commandRunner.run(<String>['config', '--analytics']);
      expect(fakeAnalytics.telemetryEnabled, true);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext('analytics reported with help usages', () async {
      final ConfigCommand configCommand = createConfigCommand();
      createTestCommandRunner(configCommand);

      await fakeAnalytics.setTelemetry(false);
      expect(
        configCommand.usage,
        containsIgnoringWhitespace('Analytics reporting is currently disabled'),
      );

      await fakeAnalytics.setTelemetry(true);
      expect(
        configCommand.usage,
        containsIgnoringWhitespace('Analytics reporting is currently enabled'),
      );
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext('resolves dependencies from injected ToolContext on write', () async {
      final fakeInjectedConfig = Config.test(name: 'injected');
      final fakeInjectedLogger = BufferLogger.test();

      final ConfigCommand configCommand = createConfigCommand(
        config: fakeInjectedConfig,
        logger: fakeInjectedLogger,
      );

      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--enable-web']);

      expect(fakeInjectedConfig.getValue('enable-web'), true);
      expect(globals.config.getValue('enable-web'), isNull);

      expect(fakeInjectedLogger.statusText, contains('Setting "enable-web" value to "true"'));
      expect(testLogger.statusText, isNot(contains('Setting "enable-web" value to "true"')));
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext('resolves dependencies from injected ToolContext on read', () async {
      final fakeLocalConfig = FakeConfig();
      final fakeLocalLogger = BufferLogger.test();
      final ConfigCommand configCommand = createConfigCommand(
        config: fakeLocalConfig,
        logger: fakeLocalLogger,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--list']);

      expect(fakeLocalLogger.statusText, contains('All Settings:'));
      expect(fakeLocalConfig.keysQueried, isTrue);
    });
  });
}

class FakeAndroidStudio extends Fake implements AndroidStudio, Comparable<AndroidStudio> {
  @override
  String get directory => 'path/to/android/studio';

  @override
  String? get javaPath => 'path/to/android/studio/jbr';
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  Directory get directory => globals.fs.directory('path/to/android/sdk');
}

class FakeFlutterVersion extends Fake implements FlutterVersion {
  @override
  String channel = 'stable';

  @override
  void ensureVersionFile() {}

  @override
  Future<void> checkFlutterVersionFreshness() async {}
}

ConfigCommand createConfigCommand({
  Config? config,
  Logger? logger,
  Platform? platform,
  FileSystem? fileSystem,
  ProcessManager? processManager,
  ProcessUtils? processUtils,
  Analytics? analytics,
  AnsiTerminal? terminal,
  FlutterVersion? flutterVersion,
  AndroidSdk? androidSdk,
  AndroidStudio? androidStudio,
  Java? java,
}) {
  final FileSystem fs = fileSystem ?? context.get<FileSystem>() ?? globals.fs;
  final Logger resolvedLogger = logger ?? context.get<Logger>() ?? globals.logger;
  final Platform resolvedPlatform = platform ?? context.get<Platform>() ?? globals.platform;
  final ProcessManager resolvedProcessManager =
      processManager ?? context.get<ProcessManager>() ?? globals.processManager;
  return ConfigCommand(
    androidContext: FakeAndroidContext(
      androidSdk: androidSdk ?? context.get<AndroidSdk>() ?? globals.androidSdk,
      androidStudio: androidStudio ?? context.get<AndroidStudio>() ?? globals.androidStudio,
      java: java ?? context.get<Java>() ?? globals.java,
    ),
    toolContext: FakeToolContext(
      config: config ?? context.get<Config>() ?? globals.config,
      logger: resolvedLogger,

      flutterVersion: flutterVersion ?? context.get<FlutterVersion>() ?? globals.flutterVersion,
      platform: resolvedPlatform,
      fs: fs,
      processManager: resolvedProcessManager,
      processUtils: processUtils ?? context.get<ProcessUtils>() ?? globals.processUtils,
      terminal: terminal ?? context.get<AnsiTerminal>() ?? globals.terminal,
    ),
  );
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({
    required this.config,
    required this.logger,
    required this.platform,
    required this.fs,
    required this.processManager,
    required this.processUtils,

    required this.terminal,
    required this.flutterVersion,
  });

  @override
  final Config config;
  @override
  final Logger logger;
  @override
  final Platform platform;
  @override
  final FileSystem fs;
  @override
  final ProcessManager processManager;
  @override
  final ProcessUtils processUtils;

  @override
  final AnsiTerminal terminal;
  @override
  final FlutterVersion flutterVersion;
}

class FakeAndroidContext extends Fake implements AndroidContext {
  FakeAndroidContext({this.androidSdk, this.androidStudio, this.java});

  @override
  final AndroidSdk? androidSdk;
  @override
  final AndroidStudio? androidStudio;
  @override
  final Java? java;
}

class FakeConfig extends Fake implements Config {
  bool keysQueried = false;

  @override
  Iterable<String> get keys {
    keysQueried = true;
    return const <String>[];
  }

  @override
  Object? getValue(String key) => null;
}
