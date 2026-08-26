// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/args.dart';
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
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
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
    fakeJava = fakes.FakeJava(javaHome: 'path/to/jdk');
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
    ExtensionManager? extensionManager,
  }) {
    final FileSystem fs = fileSystem ?? MemoryFileSystem.test();
    final Logger resolvedLogger = logger ?? BufferLogger.test();
    final Platform resolvedPlatform = platform ?? FakePlatform();
    final ProcessManager resolvedProcessManager = processManager ?? FakeProcessManager.any();
    return ConfigCommand(
      verboseHelp: verboseHelp,
      featureFlags: featureFlags ?? TestFeatureFlags(),
      analytics: analytics ?? fakeAnalytics,
      extensionManager: extensionManager,
      androidContext: FakeAndroidContext(
        androidSdk: androidSdk,
        androidStudio: androidStudio,
        java: java,
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
            ProcessUtils(logger: resolvedLogger, processManager: resolvedProcessManager),
        terminal: terminal ?? AnsiTerminal(stdio: FakeStdio(), platform: resolvedPlatform),
      ),
    );
  }

  group('config', () {
    testWithoutContext('machine flag displays values in json format', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
        androidStudio: fakeAndroidStudio,
        androidSdk: fakeAndroidSdk,
        java: fakeJava,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--machine']);

      expect(
        json.decode(logger.statusText),
        equals(<String, Object?>{
          'android-studio-dir': 'path/to/android/studio',
          'android-sdk': 'path/to/android/sdk',
          'jdk-dir': 'path/to/jdk',
        }),
      );
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('machine flag outputs empty json when tools are not found', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--machine']);

      expect(json.decode(logger.statusText), equals(<String, Object?>{}));
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('machine flag includes custom values in output', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
        androidStudio: fakeAndroidStudio,
        androidSdk: fakeAndroidSdk,
        java: fakeJava,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      config.setValue('android-studio-dir', 'dummy/dir/to/android/studio');
      config.setValue('android-sdk', 'dummy/dir/to/android/sdk');
      config.setValue('jdk-dir', 'dummy/dir/to/jdk');

      await commandRunner.run(<String>['config', '--machine']);

      expect(
        json.decode(logger.statusText),
        equals(<String, Object?>{
          'android-studio-dir': 'dummy/dir/to/android/studio',
          'android-sdk': 'dummy/dir/to/android/sdk',
          'jdk-dir': 'dummy/dir/to/jdk',
        }),
      );
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

      await commandRunner.run(<String>['config', '--clear-features']);

      expect(config.getValue('enable-android'), null);
      expect(config.getValue('enable-ios'), null);
      expect(config.getValue('enable-web'), null);
      expect(config.getValue('enable-linux-desktop'), null);
      expect(config.getValue('enable-windows-desktop'), null);
      expect(config.getValue('enable-macos-desktop'), null);

      expect(
        logger.statusText,
        contains('You may need to restart any open editors for them to read new settings.'),
      );
      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    testWithoutContext('displays notice when setting is changed', () async {
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

    testWithoutContext('warns when Swift Package Manager is disabled', () async {
      final ConfigCommand configCommand = createConfigCommand(
        config: config,
        logger: logger,
        fileSystem: fs,
        flutterVersion: fakeFlutterVersion,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--no-enable-swift-package-manager']);

      expect(logger.warningText, contains(kSwiftPackageManagerDisabledWarning));
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

    testWithoutContext(
      'custom configuration options and feature flags are registered in parser',
      () async {
        final mockExtension = FakeConfigurationExtension(
          title: 'My Extension',
          featureFlags: <FeatureFlag>[
            const FeatureFlag(
              name: 'my-ext-feature',
              help: 'My extension feature help',
              enabledByDefault: true,
            ),
          ],
          configOptions: <ConfigOption>[
            const ConfigOption(
              name: 'my-ext-option',
              help: 'My extension option help',
              value: 'default-value',
            ),
          ],
        );
        final fakeExtensionManager = FakeExtensionManager(
          extensions: <ConfigurationExtension>[mockExtension],
        );

        final ConfigCommand configCommand = createConfigCommand(
          config: config,
          logger: logger,
          fileSystem: fs,
          flutterVersion: fakeFlutterVersion,
          extensionManager: fakeExtensionManager,
          featureFlags: fakes.TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        createTestCommandRunner(configCommand);

        await configCommand.initializeDynamicOptions();
        final ArgParser parser = configCommand.argParser;

        expect(parser.options, contains('my-ext-feature'));
        expect(parser.options, contains('my-ext-option'));

        expect(parser.options['my-ext-feature']!.isFlag, true);
        expect(parser.options['my-ext-feature']!.help, 'My extension feature help');
        expect(parser.options['my-ext-feature']!.defaultsTo, true);

        expect(parser.options['my-ext-option']!.isFlag, false);
        expect(parser.options['my-ext-option']!.help, 'My extension option help');
        expect(parser.options['my-ext-option']!.defaultsTo, 'default-value');
      },
    );

    testWithoutContext(
      'custom configuration options and feature flags can be set/cleared via runCommand',
      () async {
        final mockExtension = FakeConfigurationExtension(
          title: 'My Extension',
          featureFlags: <FeatureFlag>[
            const FeatureFlag(name: 'my-ext-feature', help: 'My extension feature help'),
          ],
          configOptions: <ConfigOption>[
            const ConfigOption(name: 'my-ext-option', help: 'My extension option help'),
          ],
        );
        final fakeExtensionManager = FakeExtensionManager(
          extensions: <ConfigurationExtension>[mockExtension],
        );

        final ConfigCommand configCommand = createConfigCommand(
          config: config,
          logger: logger,
          fileSystem: fs,
          flutterVersion: fakeFlutterVersion,
          extensionManager: fakeExtensionManager,
          featureFlags: fakes.TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await configCommand.initializeDynamicOptions();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--my-ext-feature', '--my-ext-option=my-value']);

        expect(config.getValue('my-ext-feature'), true);
        expect(config.getValue('my-ext-option'), 'my-value');

        // Test disabling flag
        await commandRunner.run(<String>['config', '--no-my-ext-feature']);
        expect(config.getValue('my-ext-feature'), false);

        await commandRunner.run(<String>['config', '--clear-features']);
        expect(config.getValue('my-ext-feature'), null);

        await commandRunner.run(<String>['config', '--my-ext-option=']);
        expect(config.getValue('my-ext-option'), null);
      },
    );

    testWithoutContext(
      'conflicting extension options and feature flags are skipped without throwing',
      () async {
        final mockExtension = FakeConfigurationExtension(
          title: 'Conflicting Extension',
          featureFlags: <FeatureFlag>[
            const FeatureFlag(name: 'analytics', help: 'Conflicting analytics flag'),
          ],
          configOptions: <ConfigOption>[
            const ConfigOption(name: 'android-sdk', help: 'Conflicting android-sdk option'),
          ],
        );
        final fakeExtensionManager = FakeExtensionManager(
          extensions: <ConfigurationExtension>[mockExtension],
        );

        final ConfigCommand configCommand = createConfigCommand(
          config: config,
          logger: logger,
          fileSystem: fs,
          flutterVersion: fakeFlutterVersion,
          extensionManager: fakeExtensionManager,
          featureFlags: fakes.TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await configCommand.initializeDynamicOptions();
        final ArgParser parser = configCommand.argParser;

        expect(parser.options.containsKey('analytics'), isTrue);
        expect(parser.options.containsKey('android-sdk'), isTrue);
      },
    );
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

class FakeExtensionManager extends Fake implements ExtensionManager {
  FakeExtensionManager({this.extensions = const <ConfigurationExtension>[]});

  final List<ConfigurationExtension> extensions;

  @override
  List<ConfigurationExtension> get configurationExtensions => extensions;

  @override
  Future<void> ensureInitialized() async {}
}

class FakeConfigurationExtension extends Fake implements ConfigurationExtension {
  FakeConfigurationExtension({
    required this.title,
    required this.featureFlags,
    required this.configOptions,
  });

  @override
  final String title;
  final List<FeatureFlag> featureFlags;
  final List<ConfigOption> configOptions;

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async => featureFlags;

  @override
  Future<List<ConfigOption>> getConfigurations() async => configOptions;
}
