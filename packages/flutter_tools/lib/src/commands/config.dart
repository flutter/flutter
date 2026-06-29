// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/java.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../context/android_context.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../features.dart';
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';

class ConfigCommand extends FlutterCommand {
  ConfigCommand({
    required AndroidContext androidContext,
    required ToolContext toolContext,
    bool verboseHelp = false,
  }) : _androidContext = androidContext,
       super(toolContext: toolContext) {
    argParser.addFlag(
      'list',
      help: 'List all settings and their current values.',
      negatable: false,
    );
    argParser.addFlag(
      'analytics',
      hide: !verboseHelp,
      help:
          'Enable or disable reporting anonymously tool usage statistics and crash reports.\n'
          '(An alias for "--${FlutterGlobalOptions.kEnableAnalyticsFlag}" '
          'and "--${FlutterGlobalOptions.kDisableAnalyticsFlag}" top level flags.)',
    );
    argParser.addFlag(
      'clear-ios-signing-settings',
      negatable: false,
      aliases: <String>['clear-ios-signing-cert'],
      help:
          'Clear the saved development certificate or provisioning profile choice used to sign apps for iOS device deployment.',
    );
    argParser.addFlag(
      'select-ios-signing-settings',
      negatable: false,
      help:
          'Complete prompt to select and save code signing settings used to sign apps for iOS device deployment.',
    );
    argParser.addOption('android-sdk', help: 'The Android SDK directory.');
    argParser.addOption(
      'android-studio-dir',
      help:
          'The Android Studio installation directory. If unset, flutter will search for valid installations at well-known locations.',
    );
    argParser.addOption(
      'jdk-dir',
      help:
          'The Java Development Kit (JDK) installation directory. '
          'If unset, flutter will search for one in the following order:\n'
          '    1) the JDK bundled with the latest installation of Android Studio,\n'
          '    2) the JDK found at the directory found in the JAVA_HOME environment variable, and\n'
          "    3) the directory containing the java binary found in the user's path.",
    );
    argParser.addOption(
      'build-dir',
      help: 'The relative path to override a projects build directory.',
      valueHelp: 'out/',
    );
    addMachineOutputFlag(verboseHelp: verboseHelp);
    for (final Feature feature in featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      final String channel = flutterVersion.channel;
      argParser.addFlag(
        configSetting,
        help: feature.generateHelpMessage(),
        defaultsTo: feature.getSettingForChannel(channel).enabledByDefault,
      );
    }
    argParser.addFlag(
      'clear-features',
      help: 'Remove all configured features and restore them to the default values.',
      negatable: false,
    );
  }

  final AndroidContext _androidContext;

  @override
  final name = 'config';

  @override
  final description =
      'Configure Flutter settings.\n\n'
      'To remove a setting, configure it to an empty string.\n\n'
      'The Flutter tool anonymously reports feature usage statistics and basic crash reports to help improve '
      "Flutter tools over time. See Google's privacy policy: https://www.google.com/intl/en/policies/privacy/";

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  final aliases = <String>['configure'];

  @override
  bool get shouldUpdateCache => false;

  @override
  String get usageFooter => '\n$analyticsUsage';

  /// Return null to disable analytics recording of the `config` command.
  @override
  Future<String?> get usagePath async => null;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> rest = argResults!.rest;
    if (rest.isNotEmpty) {
      throwToolExit(
        exitCode: 2,
        'error: flutter config: Too many arguments.\n'
        '\n'
        'If a value has a space in it, enclose in quotes on the command line\n'
        'to make a single argument.  For example:\n'
        '    flutter config --android-studio-dir "/opt/Android Studio"',
      );
    }

    if (boolArg('list')) {
      logger.printStatus(settingsText);
      return FlutterCommandResult.success();
    }

    if (outputMachineFormat) {
      await handleMachine();
      return FlutterCommandResult.success();
    }

    if (boolArg('clear-features')) {
      for (final Feature feature in featureFlags.allFeatures) {
        final String? configSetting = feature.configSetting;
        if (configSetting != null) {
          config.removeValue(configSetting);
        }
      }
      logger.printStatus(requireReloadTipText);
      return FlutterCommandResult.success();
    }

    if (argResults!.wasParsed('analytics')) {
      final bool value = boolArg('analytics');
      logger.printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');

      await analytics.setTelemetry(value);
    }

    if (argResults!.wasParsed('android-sdk')) {
      _updateConfig('android-sdk', stringArg('android-sdk')!);
    }

    if (argResults!.wasParsed('android-studio-dir')) {
      _updateConfig('android-studio-dir', stringArg('android-studio-dir')!);
    }

    if (argResults!.wasParsed('jdk-dir')) {
      _updateConfig('jdk-dir', stringArg('jdk-dir')!);
    }

    if (argResults!.wasParsed('clear-ios-signing-settings')) {
      XcodeCodeSigningSettings.resetSettings(config, logger);
    }

    if (argResults!.wasParsed('select-ios-signing-settings')) {
      final settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: platform,
        processUtils: processUtils,
        fileSystem: fileSystem,
        fileSystemUtils: FileSystemUtils(fileSystem: fileSystem, platform: platform),
        terminal: terminal,
        plistParser: PlistParser(
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
        ),
      );

      await settings.selectSettings();
    }

    if (argResults!.wasParsed('build-dir')) {
      final String buildDir = stringArg('build-dir')!;
      if (fileSystem.path.isAbsolute(buildDir)) {
        throwToolExit('build-dir should be a relative path');
      }
      _updateConfig('build-dir', buildDir);
    }

    for (final Feature feature in featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      if (argResults!.wasParsed(configSetting)) {
        final bool keyValue = boolArg(configSetting);
        config.setValue(configSetting, keyValue);
        logger.printStatus('Setting "$configSetting" value to "$keyValue".');
      }
    }

    if (argResults == null || argResults!.arguments.isEmpty) {
      logger.printStatus(usage);
    } else {
      logger.printStatus('\n$requireReloadTipText');
    }

    return FlutterCommandResult.success();
  }

  Future<void> handleMachine() async {
    // Get all the current values.
    final results = <String, Object?>{};
    for (final String key in config.keys) {
      results[key] = config.getValue(key);
    }

    // Ensure we send any calculated ones, if overrides don't exist.
    final AndroidStudio? androidStudio = _androidContext.androidStudio;
    if (results['android-studio-dir'] == null && androidStudio != null) {
      results['android-studio-dir'] = androidStudio.directory;
    }
    final AndroidSdk? androidSdk = _androidContext.androidSdk;
    if (results['android-sdk'] == null && androidSdk != null) {
      results['android-sdk'] = androidSdk.directory.path;
    }
    final Java? java = _androidContext.java;
    if (results['jdk-dir'] == null && java != null) {
      results['jdk-dir'] = java.javaHome;
    }

    logger.printStatus(const JsonEncoder.withIndent('  ').convert(results));
  }

  void _updateConfig(String keyName, String keyValue) {
    if (keyValue.isEmpty) {
      config.removeValue(keyName);
      logger.printStatus('Removing "$keyName" value.');
    } else {
      config.setValue(keyName, keyValue);
      logger.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }

  /// List all config settings. for feature flags, include whether they are available.
  String get settingsText {
    final featuresByName = <String, Feature>{};
    final String channel = flutterVersion.channel;
    for (final Feature feature in featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting != null) {
        featuresByName[configSetting] = feature;
      }
    }
    final keys = <String>{
      ...featureFlags.allFeatures.map((Feature e) => e.configSetting).whereType<String>(),
      ...config.keys,
    };
    final Iterable<String> settings = keys.map<String>((String key) {
      Object? value = config.getValue(key);
      value ??= '(Not set)';
      final buffer = StringBuffer('  $key: $value');
      if (featuresByName.containsKey(key)) {
        final FeatureChannelSetting setting = featuresByName[key]!.getSettingForChannel(channel);
        if (!setting.available) {
          buffer.write(' (Unavailable)');
        }
      }
      return buffer.toString();
    });
    final buffer = StringBuffer();
    buffer.writeln('All Settings:');
    if (settings.isEmpty) {
      buffer.writeln('  No configs have been configured.');
    } else {
      buffer.writeln(settings.join('\n'));
    }
    return buffer.toString();
  }

  /// List the status of the analytics reporting.
  String get analyticsUsage {
    return 'Analytics reporting is currently ${analytics.telemetryEnabled ? 'enabled' : 'disabled'}.';
  }

  /// Raising the reload tip for setting changes.
  final requireReloadTipText =
      'You may need to restart any open editors for them to read new settings.';
}
