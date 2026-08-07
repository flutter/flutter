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
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/fakes.dart' as fakes;
import '../../src/test_flutter_command_runner.dart';

void main() {
  late Java fakeJava;
  late FakeAndroidStudio fakeAndroidStudio;
  late FakeAndroidSdk fakeAndroidSdk;
  late FakeFlutterVersion fakeFlutterVersion;
  late FakeAnalytics fakeAnalytics;
  late MemoryFileSystem fs;
  late Config config;
  late BufferLogger logger;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fs = MemoryFileSystem.test();
    config = Config.test(directory: fs.directory('/'));
    logger = BufferLogger.test();
    fakeJava = fakes.FakeJava();
    fakeAndroidStudio = FakeAndroidStudio();
    fakeAndroidSdk = FakeAndroidSdk(fileSystem: fs);
    fakeFlutterVersion = FakeFlutterVersion();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fs,
      fakeFlutterVersion: fakes.FakeFlutterVersion(),
    );
  });

  ConfigCommand createConfigCommand({
    Config? config,
    Logger? logger,
    Platform? platform,
    FileSystem? fileSystem,
    ProcessManager? processManager,
    ProcessUtils? processUtils,
    AnsiTerminal? terminal,
    FlutterVersion? flutterVersion,
    AndroidSdk? androidSdk,
    AndroidStudio? androidStudio,
    Java? java,
    FeatureFlags? featureFlags,
    Analytics? analytics,
    bool verboseHelp = false,
  }) {
    final FileSystem fs = fileSystem ?? MemoryFileSystem.test();
    final Logger resolvedLogger = logger ?? BufferLogger.test();
    final Platform resolvedPlatform = platform ?? FakePlatform();
    final ProcessManager resolvedProcessManager = processManager ?? FakeProcessManager.any();
    return ConfigCommand(
      verboseHelp: verboseHelp,
      featureFlags: featureFlags ?? TestFeatureFlags(),
      analytics: analytics ?? fakeAnalytics,
      androidContext: FakeAndroidContext(
        androidSdk: androidSdk ?? FakeAndroidSdk(fileSystem: fs),
        androidStudio: androidStudio ?? FakeAndroidStudio(),
        java: java ?? fakes.FakeJava(),
      ),
      toolContext: FakeToolContext(
        config: config ?? Config.test(directory: fs.directory('/')),
        logger: resolvedLogger,
        flutterVersion: flutterVersion ?? FakeFlutterVersion(),
        platform: resolvedPlatform,
        fs: fs,
        processManager: resolvedProcessManager,
        processUtils:
            processUtils ??
            ProcessUtils(processManager: resolvedProcessManager, logger: resolvedLogger),
        terminal: terminal ?? AnsiTerminal(stdio: FakeStdio(), platform: resolvedPlatform),
      ),
    );
  }

  group('config', () {
    testWithoutContext('prints all settings with --list', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--list']);
      final String channel = fakeFlutterVersion.channel;
      expect(
        logger.statusText,
        'All Settings:\n'
        '${TestFeatureFlags().allFeatures.where((Feature e) => e.configSetting != null).map((Feature e) {
          final FeatureChannelSetting setting = e.getSettingForChannel(channel);
          if (!setting.available) {
            return '  ${e.configSetting}: (Not set) (Unavailable)';
          }
          return '  ${e.configSetting}: (Not set)';
        }).join('\n')}'
        '\n\n',
      );
    });

    testWithoutContext('prints default values with --help', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--help']);
      expect(logger.statusText, contains('(defaults to on)'));
    });

    testWithoutContext('throws error on excess arguments', () {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
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
    });

    testWithoutContext('machine flag', () async {
      final ConfigCommand command = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
        androidSdk: fakeAndroidSdk,
        androidStudio: fakeAndroidStudio,
        java: fakeJava,
      );
      await command.handleMachine();

      expect(logger.statusText, isNotEmpty);
      final dynamic jsonObject = json.decode(logger.statusText);
      expect(jsonObject, const TypeMatcher<Map<String, dynamic>>());
      if (jsonObject is Map<String, dynamic>) {
        expect(jsonObject['android-studio-dir'], fakeAndroidStudio.directory);
        expect(jsonObject['android-sdk'], fakeAndroidSdk.directory.path);
        expect(jsonObject['jdk-dir'], fakeJava.javaHome);
      }
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('Can set build-dir', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--build-dir=foo']);

      expect(config.getValue('build-dir'), 'foo');
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('throws error on absolute path to build-dir', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(() => commandRunner.run(<String>['config', '--build-dir=/foo']), throwsToolExit());
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('allows setting and removing feature flags', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
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

      expect(config.getValue('enable-android'), true);
      expect(config.getValue('enable-ios'), true);
      expect(config.getValue('enable-web'), true);
      expect(config.getValue('enable-linux-desktop'), true);
      expect(config.getValue('enable-windows-desktop'), true);
      expect(config.getValue('enable-macos-desktop'), true);

      await commandRunner.run(<String>['config', '--clear-features']);

      expect(config.getValue('enable-android'), null);
      expect(config.getValue('enable-ios'), null);
      expect(config.getValue('enable-web'), null);
      expect(config.getValue('enable-linux-desktop'), null);
      expect(config.getValue('enable-windows-desktop'), null);
      expect(config.getValue('enable-macos-desktop'), null);

      await commandRunner.run(<String>[
        'config',
        '--no-enable-android',
        '--no-enable-ios',
        '--no-enable-web',
        '--no-enable-linux-desktop',
        '--no-enable-windows-desktop',
        '--no-enable-macos-desktop',
      ]);

      expect(config.getValue('enable-android'), false);
      expect(config.getValue('enable-ios'), false);
      expect(config.getValue('enable-web'), false);
      expect(config.getValue('enable-linux-desktop'), false);
      expect(config.getValue('enable-windows-desktop'), false);
      expect(config.getValue('enable-macos-desktop'), false);
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('warns the user to reload IDE', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--enable-web']);

      expect(
        logger.statusText,
        containsIgnoringWhitespace('You may need to restart any open editors'),
      );
    });

    testWithoutContext('displays which config settings are available on stable', () async {
      fakeFlutterVersion.channel = 'stable';
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>[
        'config',
        '--enable-web',
        '--enable-linux-desktop',
        '--enable-windows-desktop',
        '--enable-macos-desktop',
      ]);

      await commandRunner.run(<String>['config', '--list']);

      expect(logger.statusText, containsIgnoringWhitespace('enable-web: true'));
      expect(logger.statusText, containsIgnoringWhitespace('enable-linux-desktop: true'));
      expect(logger.statusText, containsIgnoringWhitespace('enable-windows-desktop: true'));
      expect(logger.statusText, containsIgnoringWhitespace('enable-macos-desktop: true'));
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('analytics flag enables/disables analytics', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(fakeAnalytics.telemetryEnabled, true);

      await commandRunner.run(<String>['config', '--no-analytics']);
      expect(fakeAnalytics.telemetryEnabled, false);

      await commandRunner.run(<String>['config', '--analytics']);
      expect(fakeAnalytics.telemetryEnabled, true);
    });

    testWithoutContext('analytics reported with help usages', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
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
    });

    testWithoutContext('resolves dependencies from injected ToolContext on write', () async {
      final fakeInjectedConfig = Config.test(name: 'injected', directory: fs.directory('/'));
      final fakeInjectedLogger = BufferLogger.test();

      final ConfigCommand configCommand = createConfigCommand(
        config: fakeInjectedConfig,
        logger: fakeInjectedLogger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );

      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--enable-web']);

      expect(fakeInjectedConfig.getValue('enable-web'), true);
      expect(config.getValue('enable-web'), isNull);

      expect(fakeInjectedLogger.statusText, contains('Setting "enable-web" value to "true"'));
      expect(logger.statusText, isNot(contains('Setting "enable-web" value to "true"')));
    });

    testWithoutContext('resolves dependencies from injected ToolContext on read', () async {
      final fakeLocalConfig = FakeConfig();
      final fakeLocalLogger = BufferLogger.test();
      final ConfigCommand configCommand = createConfigCommand(
        config: fakeLocalConfig,
        logger: fakeLocalLogger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
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
  FakeAndroidSdk({required this.fileSystem});

  final FileSystem fileSystem;

  @override
  Directory get directory => fileSystem.directory('path/to/android/sdk');
}

class FakeFlutterVersion extends Fake implements FlutterVersion {
  @override
  String channel = 'stable';

  @override
  void ensureVersionFile() {}

  @override
  Future<void> checkFlutterVersionFreshness() async {}
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
