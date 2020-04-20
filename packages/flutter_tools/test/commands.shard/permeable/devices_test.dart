// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';

import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/base/context.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  testUsingContext('devices can display via the --machine flag', () async {
    final BufferLogger logger = context.get<Logger>() as BufferLogger;
    final DevicesCommand command = DevicesCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['devices', '--machine']);

    expect(
      json.decode(logger.statusText),
      contains(
        <String, Object>{
          'name': 'Web Server',
          'id': 'web-server',
          'isSupported': true,
          'targetPlatform': 'web-javascript',
          'emulator': false,
          'sdk': 'Flutter Tools',
          'capabilities': <String, Object>{
            'hotReload': true,
            'hotRestart': true,
            'screenshot': false,
            'fastStart': false,
            'flutterExit': true,
            'hardwareRendering': false,
            'startPaused': true
          }
        }
      ),
    );
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
  });
}
