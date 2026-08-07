import 'package:unified_analytics/unified_analytics.dart';

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
    FeatureFlags? featureFlags,
    Analytics? analytics,
    bool verboseHelp = false,
  }) : _androidContext = androidContext,
       _toolContext = toolContext,
       _featureFlags = featureFlags,
       _analytics = analytics,
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
    for (final Feature feature in _effectiveFeatureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      final String channel = _toolContext.flutterVersion.channel;
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
  final ToolContext _toolContext;
  final FeatureFlags? _featureFlags;
  final Analytics? _analytics;

  FeatureFlags get _effectiveFeatureFlags {
    if (_featureFlags != null) {
      return _featureFlags;
    }
    try {
      return featureFlags;
    } on UnsupportedError {
      return const _DefaultFeatureFlags();
    }
  }

  Analytics get _effectiveAnalytics => _analytics ?? analytics;

  @override
  final name = 'config';

  @override
  final description =
      'Configure Flutter settings.\n\n'
      'To remove a setting, configure it to an empty string.\n\n'
      'The Flutter tool logs metric data on some Flutter executions for internal usage analysis. '
      'The data is anonymized before being sent to Google and no personal information is '
      'collected. To prevent reporting of the data to Google, disable telemetry with '
      '"flutter config --no-analytics".';

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
  void printUsage() {
    _toolContext.logger.printStatus(usage);
  }

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
      _toolContext.logger.printStatus(settingsText);
      return FlutterCommandResult.success();
    }

    if (outputMachineFormat) {
      await handleMachine();
      return FlutterCommandResult.success();
    }

    if (boolArg('clear-features')) {
      for (final Feature feature in _effectiveFeatureFlags.allFeatures) {
        final String? configSetting = feature.configSetting;
        if (configSetting != null) {
          _toolContext.config.removeValue(configSetting);
        }
      }
      _toolContext.logger.printStatus(requireReloadTipText);
      return FlutterCommandResult.success();
    }

    if (argResults!.wasParsed('analytics')) {
      final bool value = boolArg('analytics');
      _toolContext.logger.printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');

      await _effectiveAnalytics.setTelemetry(value);
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
      XcodeCodeSigningSettings.resetSettings(_toolContext.config, _toolContext.logger);
    }

    if (argResults!.wasParsed('select-ios-signing-settings')) {
      final settings = XcodeCodeSigningSettings(
        config: _toolContext.config,
        logger: _toolContext.logger,
        platform: _toolContext.platform,
        processUtils: _toolContext.processUtils,
        fileSystem: _toolContext.fs,
        fileSystemUtils: FileSystemUtils(
          fileSystem: _toolContext.fs,
          platform: _toolContext.platform,
        ),
        terminal: _toolContext.terminal,
        plistParser: PlistParser(
          fileSystem: _toolContext.fs,
          logger: _toolContext.logger,
          processManager: _toolContext.processManager,
        ),
      );

      await settings.selectSettings();
    }

    if (argResults!.wasParsed('build-dir')) {
      final String buildDir = stringArg('build-dir')!;
      if (_toolContext.fs.path.isAbsolute(buildDir)) {
        throwToolExit('build-dir should be a relative path');
      }
      _updateConfig('build-dir', buildDir);
    }

    for (final Feature feature in _effectiveFeatureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting == null) {
        continue;
      }
      if (argResults!.wasParsed(configSetting)) {
        final bool keyValue = boolArg(configSetting);
        _toolContext.config.setValue(configSetting, keyValue);
        _toolContext.logger.printStatus('Setting "$configSetting" value to "$keyValue".');
      }
    }

    if (argResults == null || argResults!.arguments.isEmpty) {
      _toolContext.logger.printStatus(usage);
    } else {
      _toolContext.logger.printStatus('\n$requireReloadTipText');
    }

    return FlutterCommandResult.success();
  }

  Future<void> handleMachine() async {
    // Get all the current values.
    final results = <String, Object?>{};
    for (final String key in _toolContext.config.keys) {
      results[key] = _toolContext.config.getValue(key);
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

    _toolContext.logger.printStatus(const JsonEncoder.withIndent('  ').convert(results));
  }

  void _updateConfig(String keyName, String keyValue) {
    if (keyValue.isEmpty) {
      _toolContext.config.removeValue(keyName);
      _toolContext.logger.printStatus('Removing "$keyName" value.');
    } else {
      _toolContext.config.setValue(keyName, keyValue);
      _toolContext.logger.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }

  /// List all config settings. for feature flags, include whether they are available.
  String get settingsText {
    final featuresByName = <String, Feature>{};
    final String channel = _toolContext.flutterVersion.channel;
    for (final Feature feature in _effectiveFeatureFlags.allFeatures) {
      final String? configSetting = feature.configSetting;
      if (configSetting != null) {
        featuresByName[configSetting] = feature;
      }
    }
    final keys = <String>{
      ..._effectiveFeatureFlags.allFeatures.map((Feature e) => e.configSetting).whereType<String>(),
      ..._toolContext.config.keys,
    };
    final Iterable<String> settings = keys.map<String>((String key) {
      Object? value = _toolContext.config.getValue(key);
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
    return 'Analytics reporting is currently ${_effectiveAnalytics.telemetryEnabled ? 'enabled' : 'disabled'}.';
  }

  /// Raising the reload tip for setting changes.
  final requireReloadTipText =
      'You may need to restart any open editors for them to read new settings.';
}

class _DefaultFeatureFlags extends FeatureFlags {
  const _DefaultFeatureFlags();

  @override
  bool isEnabled(Feature feature) => false;
  @override
  bool get isLinuxEnabled => false;
  @override
  bool get isMacOSEnabled => false;
  @override
  bool get isWindowsEnabled => false;
  @override
  bool get isWebEnabled => false;
  @override
  bool get isAndroidEnabled => false;
  @override
  bool get isIOSEnabled => false;
  @override
  bool get isFuchsiaEnabled => false;
  @override
  bool get areCustomDevicesEnabled => false;
  @override
  bool get isCliAnimationEnabled => false;
  @override
  bool get isNativeAssetsEnabled => false;
  @override
  bool get isDartDataAssetsEnabled => false;
  @override
  bool get isRecordUseEnabled => false;
  @override
  bool get isSwiftPackageManagerEnabled => false;
  @override
  bool get isOmitLegacyVersionFileEnabled => false;
  @override
  bool get isWindowingEnabled => false;
  @override
  bool get isAccessibilityEvaluationsEnabled => false;
  @override
  bool get isLLDBDebuggingEnabled => false;
  @override
  bool get isUISceneMigrationEnabled => false;
  @override
  bool get isRiscv64SupportEnabled => false;
  @override
  bool get isMacOSArm64OnlyEnabled => false;
}
