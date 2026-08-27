// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/java.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../context/android_context.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../experimental/config.dart';
import '../experimental/extension_arg_parser.dart';
import '../experimental/extension_manager.dart';
import '../features.dart';
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';

class ConfigCommand extends FlutterCommand with ExtensionArgParserMixin {
  ConfigCommand({
    required AndroidContext androidContext,
    required ToolContext toolContext,
    required FeatureFlags featureFlags,
    bool verboseHelp = false,
    ExtensionManager? extensionManager,
  }) : _androidContext = androidContext,
       _featureFlags = featureFlags,
       _extensionManager = extensionManager,
       _verboseHelp = verboseHelp,
       super(toolContext: toolContext);

  final AndroidContext _androidContext;
  final FeatureFlags _featureFlags;
  final ExtensionManager? _extensionManager;
  final bool _verboseHelp;

  ToolContext get _toolContext => toolContext!;

  var _extensionSettingsGroups = const <ExtensionSettingsGroup>[];

  @override
  ArgParser createBaseArgParser() {
    final ArgParser parser = super.createBaseArgParser();
    parser.addFlag('list', help: 'List all settings and their current values.', negatable: false);
    parser.addFlag(
      'analytics',
      hide: !_verboseHelp,
      help:
          'Enable or disable reporting anonymously tool usage statistics and crash reports.\n'
          '(An alias for "--${FlutterGlobalOptions.kEnableAnalyticsFlag}" '
          'and "--${FlutterGlobalOptions.kDisableAnalyticsFlag}" top level flags.)',
    );
    parser.addFlag(
      'clear-ios-signing-settings',
      negatable: false,
      aliases: <String>['clear-ios-signing-cert'],
      help:
          'Clear the saved development certificate or provisioning profile choice used to sign apps for iOS device deployment.',
    );
    parser.addFlag(
      'select-ios-signing-settings',
      negatable: false,
      help:
          'Complete prompt to select and save code signing settings used to sign apps for iOS device deployment.',
    );
    parser.addOption('android-sdk', help: 'The Android SDK directory.');
    parser.addOption(
      'android-studio-dir',
      help:
          'The Android Studio installation directory. If unset, flutter will search for valid installations at well-known locations.',
    );
    parser.addOption(
      'jdk-dir',
      help:
          'The Java Development Kit (JDK) installation directory. '
          'If unset, flutter will search for one in the following order:\n'
          '    1) the JDK bundled with the latest installation of Android Studio,\n'
          '    2) the JDK found at the directory found in the JAVA_HOME environment variable, and\n'
          "    3) the directory containing the java binary found in the user's path.",
    );
    parser.addOption(
      'build-dir',
      help: 'The relative path to override a projects build directory.',
      valueHelp: 'out/',
    );
    parser.addFlag(
      FlutterGlobalOptions.kMachineFlag,
      negatable: false,
      help: 'Outputs in a machine readable structured JSON format.',
      hide: !_verboseHelp,
    );
    for (final Feature feature in _featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      final String channel = _toolContext.flutterVersion.channel;
      parser.addFlag(
        configSetting,
        help: feature.generateHelpMessage(),
        defaultsTo: feature.getSettingForChannel(channel).enabledByDefault,
      );
    }
    parser.addFlag(
      'clear-features',
      help: 'Remove all configured features and restore them to the default values.',
      negatable: false,
    );
    return parser;
  }

  Future<ExtensionConfiguration?> get _activeExtensionConfig async {
    if (_extensionManager case final extensionManager?) {
      await extensionManager.ensureInitialized();
      final List<ConfigurationExtension> extensions = extensionManager.configurationExtensions;
      if (extensions.isNotEmpty) {
        return ExtensionConfiguration(extensions: extensions, logger: _toolContext.logger);
      }
    }
    return null;
  }

  @override
  Future<void> initializeDynamicOptions() async {
    if (await _activeExtensionConfig case final activeConfig?) {
      _extensionSettingsGroups = await activeConfig.fetchExtensionSettings();
      if (_extensionSettingsGroups.isNotEmpty) {
        rebuildDynamicArgParser();
      }
    }
  }

  @override
  ArgParser buildDynamicArgParser(ArgParser dynamicParser) {
    for (final ExtensionSettingsGroup(:featureFlags, :configOptions) in _extensionSettingsGroups) {
      for (final FeatureFlag(:name, :help, :enabledByDefault) in featureFlags) {
        if (!dynamicParser.options.containsKey(name)) {
          dynamicParser.addFlag(name, help: help, defaultsTo: enabledByDefault);
        } else {
          _toolContext.logger.printTrace(
            'Extension feature flag "$name" conflicts with an existing option and was skipped.',
          );
        }
      }
      for (final ConfigOption(:name, :help, :value) in configOptions) {
        if (!dynamicParser.options.containsKey(name)) {
          dynamicParser.addOption(name, help: help, defaultsTo: value);
        } else {
          _toolContext.logger.printTrace(
            'Extension config option "$name" conflicts with an existing option and was skipped.',
          );
        }
      }
    }
    return dynamicParser;
  }

  @override
  final name = 'config';

  @override
  final description =
      'Configure Flutter settings.\n\n'
      'To remove a setting, configure it to an empty string.\n\n'
      'The Flutter tool anonymously reports feature usage statistics and basic crash reports to help improve '
      "Flutter tools over time. See Google's privacy policy: https://www.google.com/intl/en/policies/privacy/";

  @override
  final category = FlutterCommandCategory.sdk;

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
    final Logger logger = _toolContext.logger;
    final Config config = _toolContext.config;
    final FileSystem fs = _toolContext.fs;

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
      logger.printStatus(await settingsText);
      return FlutterCommandResult.success();
    }

    if (outputMachineFormat) {
      await handleMachine();
      return FlutterCommandResult.success();
    }

    if (boolArg('clear-features')) {
      for (final Feature feature in _featureFlags.allFeatures) {
        final String? configSetting = feature.configSetting;
        if (configSetting != null) {
          config.removeValue(configSetting);
        }
      }
      final ExtensionConfiguration? activeConfig = await _activeExtensionConfig;
      final List<ExtensionSettingsGroup> groups = _extensionSettingsGroups.isNotEmpty
          ? _extensionSettingsGroups
          : await activeConfig?.fetchExtensionSettings() ?? const <ExtensionSettingsGroup>[];
      for (final ExtensionSettingsGroup(:featureFlags) in groups) {
        for (final FeatureFlag(:name) in featureFlags) {
          config.removeValue(name);
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
      _updateConfig('android-sdk', stringArg('android-sdk'));
    }

    if (argResults!.wasParsed('android-studio-dir')) {
      _updateConfig('android-studio-dir', stringArg('android-studio-dir'));
    }

    if (argResults!.wasParsed('jdk-dir')) {
      _updateConfig('jdk-dir', stringArg('jdk-dir'));
    }

    if (argResults!.wasParsed('clear-ios-signing-settings')) {
      XcodeCodeSigningSettings.resetSettings(config, logger);
    }

    if (argResults!.wasParsed('select-ios-signing-settings')) {
      final settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: _toolContext.platform,
        processUtils: _toolContext.processUtils,
        fileSystem: fs,
        fileSystemUtils: _toolContext.fileSystemUtils,
        terminal: _toolContext.terminal,
        plistParser: PlistParser(
          fileSystem: fs,
          logger: logger,
          processManager: _toolContext.processManager,
        ),
      );

      await settings.selectSettings();
    }

    if (argResults!.wasParsed('build-dir')) {
      final String buildDir = stringArg('build-dir')!;
      if (fs.path.isAbsolute(buildDir)) {
        throwToolExit('build-dir should be a relative path');
      }
      _updateConfig('build-dir', buildDir);
    }

    for (final Feature feature in _featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      if (argResults!.wasParsed(configSetting)) {
        final bool keyValue = boolArg(configSetting);
        config.setValue(configSetting, keyValue);
        logger.printStatus('Setting "$configSetting" value to "$keyValue".');
        if (!keyValue && feature.warningMessageOnDisable != null) {
          logger.printWarning(feature.warningMessageOnDisable!);
        }
      }
    }

    for (final ExtensionSettingsGroup(:featureFlags, :configOptions) in _extensionSettingsGroups) {
      for (final FeatureFlag(:name) in featureFlags) {
        if (argResults!.wasParsed(name)) {
          final bool keyValue = boolArg(name);
          config.setValue(name, keyValue);
          logger.printStatus('Setting "$name" value to "$keyValue".');
        }
      }
      for (final ConfigOption(:name) in configOptions) {
        if (argResults!.wasParsed(name)) {
          _updateConfig(name, stringArg(name));
        }
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
    final Config config = _toolContext.config;
    final Logger logger = _toolContext.logger;
    // Get all the current values.
    final results = <String, Object?>{
      for (final String key in config.keys) key: config.getValue(key),
    };

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

  void _updateConfig(String keyName, String? keyValue) {
    final Config config = _toolContext.config;
    final Logger logger = _toolContext.logger;
    if (keyValue == null || keyValue.isEmpty) {
      config.removeValue(keyName);
      logger.printStatus('Removing "$keyName" value.');
    } else {
      config.setValue(keyName, keyValue);
      logger.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }

  /// List all config settings. for feature flags, include whether they are available.
  Future<String> get settingsText async {
    final Config config = _toolContext.config;
    final featuresByName = <String, Feature>{
      for (final feature in _featureFlags.allFeatures)
        if (feature.configSetting case final configSetting?) configSetting: feature,
    };
    final String channel = _toolContext.flutterVersion.channel;
    final keys = <String>{
      ..._featureFlags.allFeatures.map((Feature e) => e.configSetting).whereType<String>(),
      ...config.keys,
    };
    final Iterable<String> settings = keys.map<String>((String key) {
      Object? value = config.getValue(key);
      value ??= '(Not set)';
      final buffer = StringBuffer('  $key: $value');
      if (featuresByName[key] case final feature?) {
        final FeatureChannelSetting setting = feature.getSettingForChannel(channel);
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

    final ExtensionConfiguration? activeConfig = await _activeExtensionConfig;
    final List<ExtensionSettingsGroup> groups = _extensionSettingsGroups.isNotEmpty
        ? _extensionSettingsGroups
        : (await activeConfig?.fetchExtensionSettings()) ?? const <ExtensionSettingsGroup>[];
    if (groups.any((ExtensionSettingsGroup g) => g.isNotEmpty)) {
      buffer.writeln('\nExtension Settings:');
      for (final ExtensionSettingsGroup(:title, :featureFlags, :configOptions, :isEmpty)
          in groups) {
        if (isEmpty) {
          continue;
        }
        buffer.writeln('  $title:');
        for (final FeatureFlag(:name, :enabledByDefault) in featureFlags) {
          final Object val = config.getValue(name) ?? enabledByDefault;
          buffer.writeln('    $name: $val');
        }
        for (final ConfigOption(:name, :value) in configOptions) {
          final Object val = config.getValue(name) ?? value ?? '(Not set)';
          buffer.writeln('    $name: $val');
        }
      }
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
