// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/base/context.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('devices', () {
    Directory configDir;
    Config config;

    tearDown(() {
      if (configDir != null) {
        tryToDelete(configDir);
        configDir = null;
      }
    });

    setUpAll(() {
      Cache.disableLocking();
      configDir ??= globals.fs.systemTempDirectory.createTempSync(
        'flutter_config_dir_test.',
      );
      config = Config.test(
        Config.kFlutterSettings,
        directory: configDir,
        logger: globals.logger,
      )..setValue('enable-web', true);
    });

    // Test assumes no devices connected.
    // Should return only `web-server` device
    testUsingContext('Test the --machine flag', () async {
      final BufferLogger logger = context.get<Logger>() as BufferLogger;
      final DevicesCommand command = DevicesCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['devices', '--machine']);
      expect(
        json.decode(logger.statusText),
        <Map<String,Object>>[
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
        ]
      );
    },
    overrides: <Type, Generator>{
      DeviceManager: () => DeviceManager(),
      Config: () => config,
      ChromeLauncher: () => _DisabledChromeLauncher(),
    });
  });
}

// Without ChromeLauncher DeviceManager constructor fails with noSuchMethodError
// trying to call canFindChrome on null
// Also, Chrome may have different versions on different machines and
// JSON will not match, because the `sdk` field of the Device contains version number
// Mock the launcher to make it appear that we don't have Chrome.
class _DisabledChromeLauncher implements ChromeLauncher {
  @override
  bool canFindChrome() => false;

  @override
  Future<Chrome> launch(String url, {bool headless = false, int debugPort, bool skipCheck = false, Directory cacheDir})
    => Future<Chrome>.error('Chrome disabled');
}
