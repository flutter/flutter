// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import '../runner/flutter_command.dart';
import '../usage.dart';

class ConfigCommand extends FlutterCommand {
  ConfigCommand() {
    argParser.addFlag('analytics',
      negatable: true,
      help: 'Enable or disable reporting anonymously tool usage statistics and crash reports.');
    argParser.addOption('gradle-dir', help: 'The gradle install directory.');
    argParser.addOption('android-studio-dir', help: 'The Android Studio install directory.');
  }

  @override
  final String name = 'config';

  @override
  final String description =
    'Configure Flutter settings.\n\n'
    'The Flutter tool anonymously reports feature usage statistics and basic crash reports to help improve\n'
    'Flutter tools over time. See Google\'s privacy policy: https://www.google.com/intl/en/policies/privacy/';

  @override
  final List<String> aliases = <String>['configure'];

  @override
  String get usageFooter {
    // List all config settings.
    String values = config.keys.map((String key) {
      return '  $key: ${config.getValue(key)}';
    }).join('\n');
    if (values.isNotEmpty)
      values = '\nSettings:\n$values\n\n';
    return
      '$values'
      'Analytics reporting is currently ${flutterUsage.enabled ? 'enabled' : 'disabled'}.';
  }

  /// Return null to disable tracking of the `config` command.
  @override
  Future<String> get usagePath => null;

  @override
  Future<Null> runCommand() async {
    if (argResults.wasParsed('analytics')) {
      final bool value = argResults['analytics'];
      flutterUsage.enabled = value;
      printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');
    }

    if (argResults.wasParsed('gradle-dir'))
      _updateConfig('gradle-dir', argResults['gradle-dir']);

    if (argResults.wasParsed('android-studio-dir'))
      _updateConfig('android-studio-dir', argResults['android-studio-dir']);

    if (argResults.arguments.isEmpty)
      printStatus(usage);
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
