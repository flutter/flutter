// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../convert.dart';
import '../features.dart';
import '../globals.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class ConfigCommand extends FlutterCommand {
  ConfigCommand({ bool verboseHelp = false }) {
    argParser.addFlag('analytics',
      negatable: true,
      help: 'Enable or disable reporting anonymously tool usage statistics and crash reports.');
    argParser.addFlag('clear-ios-signing-cert',
      negatable: false,
      help: 'Clear the saved development certificate choice used to sign apps for iOS device deployment.');
    argParser.addOption('android-sdk', help: 'The Android SDK directory.');
    argParser.addOption('android-studio-dir', help: 'The Android Studio install directory.');
    argParser.addOption('build-dir', help: 'The relative path to override a projects build directory',
        valueHelp: 'out/');
    argParser.addFlag('machine',
      negatable: false,
      hide: !verboseHelp,
      help: 'Print config values as json.');
    for (Feature feature in allFeatures) {
      if (feature.configSetting == null) {
        continue;
      }
      argParser.addFlag(
        feature.configSetting,
        help: feature.generateHelpMessage(),
        negatable: true,
      );
    }
    argParser.addFlag(
      'clear-features',
      help: 'Remove all configured features and restore them to the default values.',
      negatable: false,
    );
  }

  @override
  final String name = 'config';

  @override
  final String description =
    'Configure Flutter settings.\n\n'
    'To remove a setting, configure it to an empty string.\n\n'
    'The Flutter tool anonymously reports feature usage statistics and basic crash reports to help improve '
    'Flutter tools over time. See Google\'s privacy policy: https://www.google.com/intl/en/policies/privacy/';

  @override
  final List<String> aliases = <String>['configure'];

  @override
  bool get shouldUpdateCache => false;

  @override
  String get usageFooter {
    // List all config settings. for feature flags, include whether they
    // are available.
    final Map<String, Feature> featuresByName = <String, Feature>{};
    final String channel = FlutterVersion.instance.channel;
    for (Feature feature in allFeatures) {
      if (feature.configSetting != null) {
        featuresByName[feature.configSetting] = feature;
      }
    }
    String values = config.keys
        .map<String>((String key) {
          String configFooter = '';
          if (featuresByName.containsKey(key)) {
            final FeatureChannelSetting setting = featuresByName[key].getSettingForChannel(channel);
            if (!setting.available) {
              configFooter = '(Unavailable)';
            }
          }
          return '  $key: ${config.getValue(key)} $configFooter';
        }).join('\n');
    if (values.isEmpty)
      values = '  No settings have been configured.';
    return
      '\nSettings:\n$values\n\n'
      'Analytics reporting is currently ${flutterUsage.enabled ? 'enabled' : 'disabled'}.';
  }

  /// Return null to disable analytics recording of the `config` command.
  @override
  Future<String> get usagePath async => null;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults['machine']) {
      await handleMachine();
      return null;
    }

    if (argResults['clear-features']) {
      for (Feature feature in allFeatures) {
        if (feature.configSetting != null) {
          config.removeValue(feature.configSetting);
        }
      }
      return null;
    }

    if (argResults.wasParsed('analytics')) {
      final bool value = argResults['analytics'];
      flutterUsage.enabled = value;
      printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');
    }

    if (argResults.wasParsed('android-sdk'))
      _updateConfig('android-sdk', argResults['android-sdk']);

    if (argResults.wasParsed('android-studio-dir'))
      _updateConfig('android-studio-dir', argResults['android-studio-dir']);

    if (argResults.wasParsed('clear-ios-signing-cert'))
      _updateConfig('ios-signing-cert', '');

    if (argResults.wasParsed('build-dir')) {
      final String buildDir = argResults['build-dir'];
      if (fs.path.isAbsolute(buildDir)) {
        throwToolExit('build-dir should be a relative path');
      }
      _updateConfig('build-dir', buildDir);
    }

    for (Feature feature in allFeatures) {
      if (feature.configSetting == null) {
        continue;
      }
      if (argResults.wasParsed(feature.configSetting)) {
        final bool keyValue = argResults[feature.configSetting];
        config.setValue(feature.configSetting, keyValue);
        printStatus('Setting "${feature.configSetting}" value to "$keyValue".');
      }
    }

    if (argResults.arguments.isEmpty)
      printStatus(usage);

    return null;
  }

  Future<void> handleMachine() async {
    // Get all the current values.
    final Map<String, dynamic> results = <String, dynamic>{};
    for (String key in config.keys) {
      results[key] = config.getValue(key);
    }

    // Ensure we send any calculated ones, if overrides don't exist.
    if (results['android-studio-dir'] == null && androidStudio != null) {
      results['android-studio-dir'] = androidStudio.directory;
    }
    if (results['android-sdk'] == null && androidSdk != null) {
      results['android-sdk'] = androidSdk.directory;
    }

    printStatus(const JsonEncoder.withIndent('  ').convert(results));
  }

  void _updateConfig(String keyName, String keyValue) {
    if (keyValue.isEmpty) {
      config.removeValue(keyName);
      printStatus('Removing "$keyName" value.');
    } else {
      config.setValue(keyName, keyValue);
      printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }
}
