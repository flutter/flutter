// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/java.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../context/android_context.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../experimental/config.dart';
import '../experimental/extension_arg_parser.dart';
import '../experimental/extension_manager.dart';
import '../features.dart';
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
import '../reporting/unified_analytics.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';
import '../version.dart';

class ConfigCommand extends FlutterCommand with ExtensionArgParserMixin {
  ConfigCommand({
    required this._androidContext,
    required ToolContext super.toolContext,
    required this.featureFlags,
    this._verboseHelp = false,
    this._extensionManager,
  }) : _toolContext = toolContext;

  final AndroidContext _androidContext;
  final ToolContext _toolContext;
  final FeatureFlags featureFlags;
  final ExtensionManager? _extensionManager;
  final bool _verboseHelp;

  @override
  ToolContext get toolContext => _toolContext;

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
      help: 'Clear the saved development certificate or provisioning profile choice used to sign apps for iOS device deployment.',
    );
    parser.addFlag(
      'select-ios-signing-settings',
      negatable: false,
      help: 'Complete prompt to select and save code signing settings used to sign apps for iOS device deployment.',
    );
    parser.addOption('android-sdk', help: 'The Android SDK directory.');
    parser.addOption(
      'android-studio-dir',
      help: 'The Android Studio installation directory. If unset, flutter will search for valid installations at well-known locations.',
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
    for (final Feature feature in featureFlags.allFeatures) {
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
    if (!featureFlags.isToolExtensionsEnabled) {
      return null;
    }
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

  static String _formatCollisionConflict(String extensionId, String? existingOwner) {
    if (existingOwner == null) {
      return 'conflicts with an existing option';
    }
    if (existingOwner == extensionId) {
      return 'conflicts with an existing option in "$extensionId"';
    }
    return 'conflicts with an existing option registered by extension "$existingOwner"';
  }

  Set<String> _builtInOptionNames(ArgParser parser) {
    return <String>{
      for (final Option option in parser.options.values) ...<String>[
        option.name,
        ...option.aliases,
      ],
      if (runner case final CommandRunner<void> commandRunner)
        for (final Option option in commandRunner.argParser.options.values) ...<String>[
          option.name,
          ...option.aliases,
        ],
    };
  }

  @override
  ArgParser buildDynamicArgParser(ArgParser dynamicParser) {
    final Logger logger = _toolContext.logger;
    // Maps registered option/alias names to their owning extension identifier,
    // or `null` for built-in ConfigCommand / global FlutterCommandRunner options.
    final optionOwners = <String, String?>{
      for (final String name in _builtInOptionNames(dynamicParser)) name: null,
    };
    for (final ExtensionSettingsGroup(
          :title,
          :extensionName,
          :displayTitle,
          :featureFlags,
          :configOptions,
          :configActions,
        )
        in _extensionSettingsGroups) {
      final String extensionId = extensionName ?? title;
      var addedSeparator = false;
      void ensureSeparator() {
        if (!addedSeparator) {
          dynamicParser.addSeparator(displayTitle);
          addedSeparator = true;
        }
      }

      bool claimName(String kind, String name) {
        if (!optionOwners.containsKey(name)) {
          optionOwners[name] = extensionId;
          return true;
        }
        final String reason = _formatCollisionConflict(extensionId, optionOwners[name]);
        logger.printWarning('Extension "$extensionId" $kind "--$name" $reason and was skipped.');
        return false;
      }

      List<String> claimAliases(String kind, String name, List<String> aliases) {
        final availableAliases = <String>[];
        for (final alias in aliases) {
          if (!optionOwners.containsKey(alias)) {
            optionOwners[alias] = extensionId;
            availableAliases.add(alias);
          } else {
            final String reason = _formatCollisionConflict(extensionId, optionOwners[alias]);
            logger.printWarning(
              'Extension "$extensionId" $kind alias "--$alias" for "--$name" $reason and was skipped.',
            );
          }
        }
        return availableAliases;
      }

      for (final FeatureFlag(:name, :help, :enabledByDefault) in featureFlags) {
        if (claimName('feature flag', name)) {
          ensureSeparator();
          dynamicParser.addFlag(name, help: help, defaultsTo: enabledByDefault);
        }
      }
      for (final ConfigOption(:name, :help, :value, :aliases) in configOptions) {
        if (claimName('config option', name)) {
          final List<String> availableAliases = claimAliases('config option', name, aliases);
          ensureSeparator();
          dynamicParser.addOption(name, help: help, defaultsTo: value, aliases: availableAliases);
        }
      }
      for (final ConfigAction(:name, :help, :aliases) in configActions) {
        if (claimName('config action', name)) {
          final List<String> availableAliases = claimAliases('config action', name, aliases);
          ensureSeparator();
          dynamicParser.addFlag(name, help: help, aliases: availableAliases, negatable: false);
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
      for (final Feature feature in featureFlags.allFeatures) {
        final String? configSetting = feature.configSetting;
        if (configSetting != null) {
          config.removeValue(configSetting);
        }
      }
      final ExtensionConfiguration? activeConfig = await _activeExtensionConfig;
      final List<ExtensionSettingsGroup> groups = _extensionSettingsGroups.isNotEmpty
          ? _extensionSettingsGroups
          : await activeConfig?.fetchExtensionSettings() ?? const <ExtensionSettingsGroup>[];
      for (final ExtensionSettingsGroup(:extensionName, :featureFlags) in groups) {
        for (final FeatureFlag(:name, :settingName) in featureFlags) {
          ExtensionConfiguration.removeSettingValue(
            config,
            settingName,
            extensionName: extensionName,
          );
          if (settingName != name) {
            ExtensionConfiguration.removeSettingValue(config, name, extensionName: extensionName);
          }
        }
      }
      logger.printStatus(requireReloadTipText);
      return FlutterCommandResult.success();
    }

    if (argResults!.wasParsed('analytics')) {
      final bool value = boolArg('analytics');
      if (isDashAnalyticsSuppressionRequested(_toolContext.platform.environment)) {
        // `analytics` is a no-op, so `setTelemetry` would silently do nothing.
        logger.printWarning(dashSuppressedTelemetryChangeMessage(enable: value));
      } else {
        logger.printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');

        await analytics.setTelemetry(value);
      }
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
        plistParser: PlistParser(
          fileSystem: fs,
          logger: logger,
          processManager: _toolContext.processManager,
        ),
        toolContext: _toolContext,
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

    for (final Feature feature in featureFlags.allFeatures) {
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

    ExtensionConfiguration? activeExtensionConfig;
    final Set<String> claimedOptionNames = _builtInOptionNames(baseArgParser);
    for (final ExtensionSettingsGroup group in _extensionSettingsGroups) {
      final ExtensionSettingsGroup(
        :ConfigurationExtension? extension,
        :String? extensionName,
        :List<FeatureFlag> featureFlags,
        :List<ConfigOption> configOptions,
        :List<ConfigAction> configActions,
      ) = group;
      for (final FeatureFlag(:name, :settingName) in featureFlags) {
        if (!claimedOptionNames.add(name)) {
          continue;
        }
        if (argResults!.options.contains(name) && argResults!.wasParsed(name)) {
          final bool keyValue = boolArg(name);
          ExtensionConfiguration.setSettingValue(
            config,
            settingName,
            keyValue,
            extensionName: extensionName,
          );
          logger.printStatus('Setting "$name" value to "$keyValue".');
        }
      }
      for (final ConfigOption(:name, :aliases) in configOptions) {
        if (!claimedOptionNames.add(name)) {
          continue;
        }
        claimedOptionNames.addAll(aliases);
        if (argResults!.options.contains(name) && argResults!.wasParsed(name)) {
          _updateExtensionConfig(
            name,
            stringArg(name),
            extensionName: extensionName,
            aliases: aliases,
          );
        }
      }
      for (final action in configActions) {
        if (!claimedOptionNames.add(action.name)) {
          continue;
        }
        claimedOptionNames.addAll(action.aliases);
        if (argResults!.options.contains(action.name) &&
            argResults!.wasParsed(action.name) &&
            boolArg(action.name) &&
            extension != null) {
          activeExtensionConfig ??= await _activeExtensionConfig;
          if (activeExtensionConfig == null) {
            continue;
          }
          final Map<String, String?> currentSettings = ExtensionConfiguration.collectActionSettings(
            config,
            group,
          );
          try {
            final Map<String, String?> updates = await activeExtensionConfig.runConfigAction(
              extension: extension,
              action: action,
              currentSettings: currentSettings,
            );
            final aliasesByOptionName = <String, List<String>>{
              for (final ConfigOption(:name, :aliases) in configOptions) name: aliases,
            };
            final featureFlagSettingNames = <String>{
              for (final FeatureFlag(:settingName) in featureFlags) settingName,
            };
            for (final MapEntry(:key, :value) in updates.entries) {
              final List<String> aliases = aliasesByOptionName[key] ?? const <String>[];
              if (value == null) {
                ExtensionConfiguration.removeSettingValue(
                  config,
                  key,
                  extensionName: extensionName,
                  aliases: aliases,
                );
                logger.printStatus('Removing "$key" value.');
              } else if (featureFlagSettingNames.contains(key)) {
                final bool boolValue = switch (value.toLowerCase()) {
                  'true' => true,
                  'false' => false,
                  _ => throw ToolExtensionException(
                    'Extension "${extensionName ?? group.title}" config action "${action.name}" '
                    'returned non-boolean value "$value" for feature flag "$key".',
                  ),
                };
                ExtensionConfiguration.setSettingValue(
                  config,
                  key,
                  boolValue,
                  extensionName: extensionName,
                  aliases: aliases,
                );
                logger.printStatus('Setting "$key" value to "$boolValue".');
              } else {
                ExtensionConfiguration.setSettingValue(
                  config,
                  key,
                  value,
                  extensionName: extensionName,
                  aliases: aliases,
                );
                logger.printStatus('Setting "$key" value to "$value".');
              }
            }
          } on ToolExtensionException catch (error) {
            throwToolExit(error.message);
          }
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
    final ToolContext(:Config config, :Logger logger) = _toolContext;
    if (keyValue == null || keyValue.isEmpty) {
      config.removeValue(keyName);
      logger.printStatus('Removing "$keyName" value.');
    } else {
      config.setValue(keyName, keyValue);
      logger.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }

  void _updateExtensionConfig(
    String keyName,
    String? keyValue, {
    String? extensionName,
    List<String> aliases = const <String>[],
  }) {
    final ToolContext(:Config config, :Logger logger) = _toolContext;
    if (keyValue == null || keyValue.isEmpty) {
      ExtensionConfiguration.removeSettingValue(
        config,
        keyName,
        extensionName: extensionName,
        aliases: aliases,
      );
      logger.printStatus('Removing "$keyName" value.');
    } else {
      ExtensionConfiguration.setSettingValue(
        config,
        keyName,
        keyValue,
        extensionName: extensionName,
        aliases: aliases,
      );
      logger.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }

  /// List all config settings. for feature flags, include whether they are available.
  Future<String> get settingsText async {
    final ToolContext(:Config config, :FlutterVersion flutterVersion, :Platform platform) =
        _toolContext;
    final Map<String, String> environment = platform.environment;
    final featuresByName = <String, Feature>{
      for (final feature in featureFlags.allFeatures) ?feature.configSetting: feature,
    };
    final String channel = flutterVersion.channel;
    final keys = <String>{
      ...featureFlags.allFeatures.map((Feature e) => e.configSetting).whereType<String>(),
      for (final String key in config.keys)
        if (key != ExtensionConfiguration.extensionsSettingsKey) key,
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
    if (groups.any((ExtensionSettingsGroup g) => g.hasDisplayableSettings)) {
      buffer.writeln('\nExtension Settings:');
      for (final group in groups) {
        if (!group.hasDisplayableSettings) {
          continue;
        }
        final ExtensionSettingsGroup(
          :String displayTitle,
          :String? extensionName,
          :List<FeatureFlag> featureFlags,
          :List<ConfigOption> configOptions,
          :List<String> actionOnlySettingsKeys,
        ) = group;
        buffer.writeln('  $displayTitle:');
        for (final flag in featureFlags) {
          final bool val = ExtensionConfiguration.resolveFeatureFlagValue(
            config,
            flag,
            environment: environment,
            extensionName: extensionName,
          );
          buffer.writeln('    ${flag.name}: $val');
        }
        for (final option in configOptions) {
          final String val =
              ExtensionConfiguration.resolveConfigOptionValue(
                config,
                option,
                environment: environment,
                extensionName: extensionName,
              ) ??
              '(Not set)';
          buffer.writeln('    ${option.name}: $val');
        }
        for (final key in actionOnlySettingsKeys) {
          final Object val =
              ExtensionConfiguration.lookupSettingValue(
                config,
                key,
                extensionName: extensionName,
              ) ??
              '(Not set)';
          buffer.writeln('    $key: $val');
        }
      }
    }

    final activeExtensionNames = <String>{for (final group in groups) ?group.extensionName};
    final Map<String, Map<String, Object?>> inactiveSettings =
        ExtensionConfiguration.inactiveSavedExtensionSettings(
          config,
          activeExtensionNames: activeExtensionNames,
        );
    if (inactiveSettings.isNotEmpty) {
      buffer.writeln('\nSaved Extension Settings (inactive outside project):');
      for (final MapEntry(key: packageName, value: pkgSettings) in inactiveSettings.entries) {
        buffer.writeln('  $packageName:');
        for (final MapEntry(:key, :value) in pkgSettings.entries) {
          buffer.writeln('    $key: $value');
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
