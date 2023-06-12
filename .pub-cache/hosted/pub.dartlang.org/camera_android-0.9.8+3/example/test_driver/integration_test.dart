// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const String _examplePackage = 'io.flutter.plugins.cameraexample';

Future<void> main() async {
  if (!(Platform.isLinux || Platform.isMacOS)) {
    print('This test must be run on a POSIX host. Skipping...');
    exit(0);
  }
  final bool adbExists =
      Process.runSync('which', <String>['adb']).exitCode == 0;
  if (!adbExists) {
    print(r'This test needs ADB to exist on the $PATH. Skipping...');
    exit(0);
  }
  print('Granting camera permissions...');
  Process.runSync('adb', <String>[
    'shell',
    'pm',
    'grant',
    _examplePackage,
    'android.permission.CAMERA'
  ]);
  Process.runSync('adb', <String>[
    'shell',
    'pm',
    'grant',
    _examplePackage,
    'android.permission.RECORD_AUDIO'
  ]);
  print('Starting test.');
  final FlutterDriver driver = await FlutterDriver.connect();
  final String data = await driver.requestData(
    null,
    timeout: const Duration(minutes: 1),
  );
  await driver.close();
  print('Test finished. Revoking camera permissions...');
  Process.runSync('adb', <String>[
    'shell',
    'pm',
    'revoke',
    _examplePackage,
    'android.permission.CAMERA'
  ]);
  Process.runSync('adb', <String>[
    'shell',
    'pm',
    'revoke',
    _examplePackage,
    'android.permission.RECORD_AUDIO'
  ]);

  final Map<String, dynamic> result = jsonDecode(data) as Map<String, dynamic>;
  exit(result['result'] == 'true' ? 0 : 1);
}
