// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

// display_cutout needs a custom driver because cutout manipulations needs to be
// done to a device/emulator in order for the tests to pass.
Future<void> main() async {
  if (!(Platform.isLinux || Platform.isMacOS)) {
    // Not a fundemental limitation, developer shortcut.
    print('This test must be run on a POSIX host. Skipping...');
    return;
  }
  String adbExecutable = 'adb';
  final bool adbExistsOnPath = Process.runSync('which', <String>[adbExecutable]).exitCode == 0;
  if (!adbExistsOnPath) {
    print(r'ADB does not exist on the $PATH. Falling back to $ANDROID_HOME');
    adbExecutable = '${Platform.environment['ANDROID_HOME']}/platform-tools/adb';
    final ProcessResult result = Process.runSync('which', <String>[adbExecutable]);
    final bool adbExistsInAndroidSdk = result.exitCode == 0;
    if (!adbExistsInAndroidSdk) {
      print(r'This test needs ADB to exist on the $PATH or in $ANDROID_HOME');
      exitCode = 1;
      return;
    }
  }
  // Test requires developer settings added in 28 and behavior added in 30
  final ProcessResult checkApiLevel = Process.runSync(adbExecutable, <String>[
    'shell',
    'getprop',
    'ro.build.version.sdk',
  ]);
  final String apiStdout = checkApiLevel.stdout.toString();
  // Api level 30 or higher.
  if (apiStdout.startsWith('2') || apiStdout.startsWith('1') || apiStdout.length == 1) {
    print('This test must be run on api 30 or higher. Skipping...');
    return;
  }
  // Developer settings are required on target device for cutout manipulation.
  bool shouldResetDevSettings = false;
  final ProcessResult checkDevSettingsResult = Process.runSync(adbExecutable, <String>[
    'shell',
    'settings',
    'get',
    'global',
    'development_settings_enabled',
  ]);
  if (checkDevSettingsResult.stdout.toString().startsWith('0')) {
    print('Enabling developer settings...');
    // Developer settings not enabled, enable them and mark that the origional
    // state should be restored after.
    shouldResetDevSettings = true;
    Process.runSync(adbExecutable, <String>[
      'shell',
      'settings',
      'put',
      'global',
      'development_settings_enabled',
      '1',
    ]);
  }
  // Assumption of diplay_cutout_test.dart is that there is a "tall" notch.
  print('Adding Synthetic notch...');
  Process.runSync(adbExecutable, <String>[
    'shell',
    'cmd',
    'overlay',
    'enable',
    'com.android.internal.display.cutout.emulation.tall',
  ]);
  print('Starting test.');
  try {
    final FlutterDriver driver = await FlutterDriver.connect();
    print('Connected');
    final String data = await driver.requestData(null, timeout: const Duration(minutes: 1));
    print('Data recieved');
    await driver.close();
    print('Driver closed');
    final Map<String, dynamic> result = jsonDecode(data) as Map<String, dynamic>;
    print('Test finished!');
    print(result);
    exitCode = result['result'] == 'true' ? 0 : 1;
  } catch (e, st) {
    print('Driver Error ------');
    print(e);
    print('Driver stacktrace ------');
    print(st);
    exitCode = 1;
  } finally {
    print('Removing Synthetic notch...');
    Process.runSync(adbExecutable, <String>[
      'shell',
      'cmd',
      'overlay',
      'disable',
      'com.android.internal.display.cutout.emulation.tall',
    ]);
    print('Reverting Adb changes...');
    if (shouldResetDevSettings) {
      print('Disabling developer settings...');
      Process.runSync(adbExecutable, <String>[
        'shell',
        'settings',
        'put',
        'global',
        'development_settings_enabled',
        '0',
      ]);
    }
  }
  return;
}
