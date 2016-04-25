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
      help:
        'Enable or disable reporting anonymously tool usage statistics and basic crash reports\n'
        'to Google Analytics. See our privacy policy: www.google.com/intl/en/policies/privacy.');
  }

  @override
  final String name = 'config';

  @override
  final String description = 'Configure Flutter settings.';

  @override
  final List<String> aliases = <String>['configure'];

  @override
  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    if (argResults.wasParsed('analytics')) {
      bool value = argResults['analytics'];
      flutterUsage.enable = value;
      printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');
    } else {
      printStatus(usage);
    }

    return 0;
  }
}
