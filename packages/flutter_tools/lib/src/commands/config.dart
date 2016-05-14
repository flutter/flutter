// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import '../runner/flutter_command.dart';

class ConfigCommand extends FlutterCommand {
  ConfigCommand() {
    argParser.addFlag('analytics',
      negatable: true,
      help: 'Enable or disable reporting anonymously tool usage statistics and crash reports.');
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
  String get usageFooter => 'Analytics reporting is currently ${flutterUsage.enabled ? 'enabled' : 'disabled'}.';

  @override
  bool get requiresProjectRoot => false;

  /// Return `null` to disable tracking of the `config` command.
  @override
  String get usagePath => null;

  @override
  Future<int> runInProject() async {
    if (argResults.wasParsed('analytics')) {
      bool value = argResults['analytics'];
      flutterUsage.enabled = value;
      printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');
    } else {
      printStatus(usage);
    }

    return 0;
  }
}
