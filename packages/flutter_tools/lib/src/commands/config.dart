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
import '../convert.dart';
import '../experimental/config.dart';
import '../experimental/extension_arg_parser.dart';
import '../experimental/extension_manager.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../ios/code_signing.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';

class ConfigCommand extends FlutterCommand with ExtensionArgParserMixin {
  ConfigCommand({bool verboseHelp = false, ExtensionManager? extensionManager})
    : _verboseHelp = verboseHelp,
      _extensionManager = extensionManager;

  final bool _verboseHelp;

  List<ExtensionSettingsGroup> _extensionSettingsGroups = const <ExtensionSettingsGroup>[];
  List<FeatureFlag> _extensionFeatureFlags = const <FeatureFlag>[];
  List<ConfigOption> _extensionConfigOptions = const <ConfigOption>[];

  @override
  void populateBaseArgParser(ArgParser parser) {
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
    addMachineOutputFlag(verboseHelp: _verboseHelp);
    for (final Feature feature in featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      final String channel = globals.flutterVersion.channel;
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
  }

  final ExtensionManager? _extensionManager;

  Future<ExtensionConfiguration?> get _activeExtensionConfig async {
    if (_extensionManager case final extensionManager?) {
      await extensionManager.ensureInitialized();
      final List<ConfigurationExtension> extensions = extensionManager.configurationExtensions;
      if (extensions.isNotEmpty) {
        return ExtensionConfiguration(extensions: extensions, logger: globals.logger);
      }
    }
    return null;
  }

  @override
  Future<void> initializeDynamicOptions() async {
    final ExtensionConfiguration? activeConfig = await _activeExtensionConfig;
    if (activeConfig != null) {
      final List<ExtensionSettingsGroup> groups = await activeConfig.fetchExtensionSettings();
      _extensionSettingsGroups = groups;
      _extensionFeatureFlags = groups.expand((ExtensionSettingsGroup g) => g.featureFlags).toList();
      _extensionConfigOptions = groups
          .expand((ExtensionSettingsGroup g) => g.configOptions)
          .toList();
    }
  }

  @override
  String? get extensionArgParserCacheKey {
    if (_extensionFeatureFlags.isEmpty && _extensionConfigOptions.isEmpty) {
      return null;
    }
    final names = <String>[
      ..._extensionFeatureFlags.map((FeatureFlag f) => f.name),
      ..._extensionConfigOptions.map((ConfigOption o) => o.name),
    ]..sort();
    return names.join(',');
  }

  @override
  ArgParser buildDynamicArgParser(ArgParser baseParser) {
    final ArgParser newParser = ExtensionArgParserMixin.cloneParser(baseParser);
    for (final FeatureFlag flag in _extensionFeatureFlags) {
      if (!newParser.options.containsKey(flag.name)) {
        newParser.addFlag(flag.name, help: flag.help, defaultsTo: flag.enabledByDefault);
      } else {
        globals.printTrace(
          'Extension feature flag "${flag.name}" conflicts with an existing option and was skipped.',
        );
      }
    }
    for (final ConfigOption option in _extensionConfigOptions) {
      if (!newParser.options.containsKey(option.name)) {
        newParser.addOption(option.name, help: option.help, defaultsTo: option.value);
      } else {
        globals.printTrace(
          'Extension config option "${option.name}" conflicts with an existing option and was skipped.',
        );
      }
    }
    return newParser;
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
      globals.printStatus(await settingsText);
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
          globals.config.removeValue(configSetting);
        }
      }
      final ExtensionConfiguration? activeConfig = await _activeExtensionConfig;
      final List<FeatureFlag> flags = _extensionFeatureFlags.isNotEmpty
          ? _extensionFeatureFlags
          : await activeConfig?.fetchFeatureFlags() ?? const <FeatureFlag>[];
      for (final flag in flags) {
        globals.config.removeValue(flag.name);
      }
      globals.printStatus(requireReloadTipText);
      return FlutterCommandResult.success();
    }

    if (argResults!.wasParsed('analytics')) {
      final bool value = boolArg('analytics');
      globals.printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');

      await globals.analytics.setTelemetry(value);
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
      XcodeCodeSigningSettings.resetSettings(globals.config, globals.logger);
    }

    if (argResults!.wasParsed('select-ios-signing-settings')) {
      final settings = XcodeCodeSigningSettings(
        config: globals.config,
        logger: globals.logger,
        platform: globals.platform,
        processUtils: globals.processUtils,
        fileSystem: globals.fs,
        fileSystemUtils: globals.fsUtils,
        terminal: globals.terminal,
        plistParser: globals.plistParser,
      );

      await settings.selectSettings();
    }

    if (argResults!.wasParsed('build-dir')) {
      final String buildDir = stringArg('build-dir')!;
      if (globals.fs.path.isAbsolute(buildDir)) {
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
        globals.config.setValue(configSetting, keyValue);
        globals.printStatus('Setting "$configSetting" value to "$keyValue".');
      }
    }

    for (final FeatureFlag flag in _extensionFeatureFlags) {
      if (argResults!.wasParsed(flag.name)) {
        final bool keyValue = boolArg(flag.name);
        globals.config.setValue(flag.name, keyValue);
        globals.printStatus('Setting "${flag.name}" value to "$keyValue".');
      }
    }

    for (final ConfigOption option in _extensionConfigOptions) {
      if (argResults!.wasParsed(option.name)) {
        _updateConfig(option.name, stringArg(option.name));
      }
    }

    if (argResults == null || argResults!.arguments.isEmpty) {
      globals.printStatus(usage);
    } else {
      globals.printStatus('\n$requireReloadTipText');
    }

    return FlutterCommandResult.success();
  }

  Future<void> handleMachine() async {
    // Get all the current values.
    final results = <String, Object?>{};
    for (final String key in globals.config.keys) {
      results[key] = globals.config.getValue(key);
    }

    // Ensure we send any calculated ones, if overrides don't exist.
    final AndroidStudio? androidStudio = globals.androidStudio;
    if (results['android-studio-dir'] == null && androidStudio != null) {
      results['android-studio-dir'] = androidStudio.directory;
    }
    final AndroidSdk? androidSdk = globals.androidSdk;
    if (results['android-sdk'] == null && androidSdk != null) {
      results['android-sdk'] = androidSdk.directory.path;
    }
    final Java? java = globals.java;
    if (results['jdk-dir'] == null && java != null) {
      results['jdk-dir'] = java.javaHome;
    }

    globals.printStatus(const JsonEncoder.withIndent('  ').convert(results));
  }

  void _updateConfig(String keyName, String? keyValue) {
    if (keyValue == null || keyValue.isEmpty) {
      globals.config.removeValue(keyName);
      globals.printStatus('Removing "$keyName" value.');
    } else {
      globals.config.setValue(keyName, keyValue);
      globals.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }

  /// List all config settings. for feature flags, include whether they are available.
  Future<String> get settingsText async {
    final featuresByName = <String, Feature>{};
    final String channel = globals.flutterVersion.channel;
    for (final Feature feature in featureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting != null) {
        featuresByName[configSetting] = feature;
      }
    }
    final keys = <String>{
      ...featureFlags.allFeatures.map((Feature e) => e.configSetting).whereType<String>(),
      ...globals.config.keys,
    };
    final Iterable<String> settings = keys.map<String>((String key) {
      Object? value = globals.config.getValue(key);
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

    final ExtensionConfiguration? activeConfig = await _activeExtensionConfig;
    final List<ExtensionSettingsGroup> groups = _extensionSettingsGroups.isNotEmpty
        ? _extensionSettingsGroups
        : (await activeConfig?.fetchExtensionSettings()) ?? const <ExtensionSettingsGroup>[];
    if (groups.isNotEmpty) {
      if (groups.any(
        (ExtensionSettingsGroup g) => g.featureFlags.isNotEmpty || g.configOptions.isNotEmpty,
      )) {
        buffer.writeln('\nExtension Settings:');
        for (final group in groups) {
          if (group.featureFlags.isEmpty && group.configOptions.isEmpty) {
            continue;
          }
          buffer.writeln('  ${group.title}:');
          for (final FeatureFlag flag in group.featureFlags) {
            final Object val = globals.config.getValue(flag.name) ?? flag.enabledByDefault;
            buffer.writeln('    ${flag.name}: $val');
          }
          for (final ConfigOption option in group.configOptions) {
            final Object val = globals.config.getValue(option.name) ?? option.value ?? '(Not set)';
            buffer.writeln('    ${option.name}: $val');
          }
        }
      }
    }

    return buffer.toString();
  }

  /// List the status of the analytics reporting.
  String get analyticsUsage {
    return 'Analytics reporting is currently ${globals.analytics.telemetryEnabled ? 'enabled' : 'disabled'}.';
  }

  /// Raising the reload tip for setting changes.
  final requireReloadTipText =
      'You may need to restart any open editors for them to read new settings.';
}
