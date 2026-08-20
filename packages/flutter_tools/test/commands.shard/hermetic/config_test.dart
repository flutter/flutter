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
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
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
      final configCommand = ConfigCommand();
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
      final configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);
      await commandRunner.run(<String>['config', '--help']);
      expect(testLogger.statusText, contains('(defaults to on)'));
    });

    testUsingContext('throws error on excess arguments', () {
      final configCommand = ConfigCommand();
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
        final command = ConfigCommand();
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
      final configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>['config', '--build-dir=foo']);

      expect(getBuildDirectory(), 'foo');
      expect(fakeAnalytics.sentEvents, isEmpty);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext('throws error on absolute path to build-dir', () async {
      final configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(() => commandRunner.run(<String>['config', '--build-dir=/foo']), throwsToolExit());
      expect(fakeAnalytics.sentEvents, isEmpty);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext(
      'allows setting and removing feature flags',
      () async {
        final configCommand = ConfigCommand();
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
      final configCommand = ConfigCommand();
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
        final configCommand = ConfigCommand();
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
      final configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(fakeAnalytics.telemetryEnabled, true);

      await commandRunner.run(<String>['config', '--no-analytics']);
      expect(fakeAnalytics.telemetryEnabled, false);

      await commandRunner.run(<String>['config', '--analytics']);
      expect(fakeAnalytics.telemetryEnabled, true);
    }, overrides: <Type, Generator>{Analytics: () => fakeAnalytics});

    testUsingContext('analytics reported with help usages', () async {
      final configCommand = ConfigCommand();
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

    testUsingContext(
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

        final configCommand = ConfigCommand(extensionManager: fakeExtensionManager);
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
      overrides: <Type, Generator>{
        FeatureFlags: () => fakes.TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
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

        final configCommand = ConfigCommand(extensionManager: fakeExtensionManager);
        await configCommand.initializeDynamicOptions();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--my-ext-feature', '--my-ext-option=my-value']);

        expect(globals.config.getValue('my-ext-feature'), true);
        expect(globals.config.getValue('my-ext-option'), 'my-value');

        // Test disabling flag
        await commandRunner.run(<String>['config', '--no-my-ext-feature']);
        expect(globals.config.getValue('my-ext-feature'), false);

        await commandRunner.run(<String>['config', '--clear-features']);
        expect(globals.config.getValue('my-ext-feature'), null);

        await commandRunner.run(<String>['config', '--my-ext-option=']);
        expect(globals.config.getValue('my-ext-option'), null);
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => fakes.TestFeatureFlags(isToolExtensionsEnabled: true),
        Analytics: () => fakeAnalytics,
      },
    );

    testUsingContext(
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

        final configCommand = ConfigCommand(extensionManager: fakeExtensionManager);
        await configCommand.initializeDynamicOptions();
        final ArgParser parser = configCommand.argParser;

        expect(parser.options.containsKey('analytics'), isTrue);
        expect(parser.options.containsKey('android-sdk'), isTrue);
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => fakes.TestFeatureFlags(isToolExtensionsEnabled: true),
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
  @override
  Directory get directory => globals.fs.directory('path/to/android/sdk');
}

class FakeFlutterVersion extends Fake implements FlutterVersion {
  @override
  late String channel;

  @override
  void ensureVersionFile() {}

  @override
  Future<void> checkFlutterVersionFreshness() async {}
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
