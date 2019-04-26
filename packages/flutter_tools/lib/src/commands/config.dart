// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../convert.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../usage.dart';

class ConfigCommand extends FlutterCommand {
  ConfigCommand({ bool verboseHelp = false }) {
    argParser.addFlag('analytics',
      negatable: true,
      help: 'Enable or disable reporting anonymously tool usage statistics and crash reports.');
    argParser.addFlag('clear-ios-signing-cert',
      negatable: false,
      help: 'Clear the saved development certificate choice used to sign apps for iOS device deployment.');
    argParser.addOption('gradle-dir', help: 'The gradle install directory.');
    argParser.addOption('android-sdk', help: 'The Android SDK directory.');
    argParser.addOption('android-studio-dir', help: 'The Android Studio install directory.');
    argParser.addFlag('machine',
      negatable: false,
      hide: !verboseHelp,
      help: 'Print config values as json.');
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
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  String get usageFooter {
    // List all config settings.
    String values = config.keys.map<String>((String key) {
      return '  $key: ${config.getValue(key)}';
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
    if (args.readFlag('machine')) {
      await handleMachine();
      return null;
    }

    if (args.wasParsed('analytics')) {
      final bool value = args.readFlag('analytics');
      flutterUsage.enabled = value;
      printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');
    }

    if (args.wasParsed('gradle-dir'))
      _updateConfig('gradle-dir', args.readOption('gradle-dir'));

    if (args.wasParsed('android-sdk'))
      _updateConfig('android-sdk', args.readOption('android-sdk'));

    if (args.wasParsed('android-studio-dir'))
      _updateConfig('android-studio-dir', args.readOption('android-studio-dir'));

    if (args.wasParsed('clear-ios-signing-cert'))
      _updateConfig('ios-signing-cert', '');

    if (args.arguments.isEmpty)
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
