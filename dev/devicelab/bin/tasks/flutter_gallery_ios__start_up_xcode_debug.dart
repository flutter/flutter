// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';
import 'package:process/process.dart';

Future<void> main() async {
  // TODO(vashworth): Remove after Xcode 15 and iOS 17 are in CI (https://github.com/flutter/flutter/issues/132128)
  // XcodeDebug workflow is used for CoreDevices (iOS 17+ and Xcode 15+). Use
  // FORCE_XCODE_DEBUG environment variable to force the use of XcodeDebug
  // workflow in CI to test from older versions since devicelab has not yet been
  // updated to iOS 17 and Xcode 15.
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  final XcodeDebugTest xcodeDebugTest = XcodeDebugTest();
  await xcodeDebugTest.debugAutomation();
  await task(createFlutterGalleryStartupTest(
    runEnvironment: <String, String>{
      'FORCE_XCODE_DEBUG': 'true',
    },
  ));



  // await xcodeDebugTest.debugAutomation();
}

class XcodeDebugTest {
  Future<void> debugAutomation() async {
    print('Debugging automation...');
    const FileSystem fileSystem = LocalFileSystem();
    const ProcessManager processManager = LocalProcessManager();

    final String? home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      print('Home: $home');

      final Directory tccDir = fileSystem.directory(fileSystem.path.join(home, 'Library', 'Application Support', 'com.apple.TCC'));

      try {
        if (tccDir.existsSync()) {
          final List<FileSystemEntity> files = tccDir.listSync();
          for (final FileSystemEntity file in files) {
            print(file.path);
          }
        }
      } on PathAccessException {
        print('Path Access to ${tccDir.path} failed');
        return;
      }

      final File db = tccDir.childFile('TCC.db');
      try {
        if (!db.existsSync()) {
          print('File ${db.path} does not exist');
          return;
        }
      } on PathAccessException {
        print('Path Access to ${db.path} failed');
        return;
      }

      // create backup if there isn't one
      final File backup = tccDir.childFile('TCC.db.backup');
      if (!backup.existsSync()) {
        print('Creating backup...');
        db.copySync(backup.path);
      }


      // Select from db
      print('Selecting from real db...');
      final ProcessResult accessResult = await processManager.run(
        <String>[
          'sqlite3',
          db.path,
          'SELECT service, client, client_type, auth_value, indirect_object_identifier_type, indirect_object_identifier, last_modified FROM access WHERE service = "kTCCServiceAppleEvents"'
        ],
      );
      print('Access Result: ${accessResult.exitCode}');
      print('[stdout]: ${accessResult.stdout.toString().trim()}');
      print('[stderr]: ${accessResult.stderr.toString().trim()}');


      // Try updating db
      print('Updating real db...');
      final ProcessResult replaceResult = await processManager.run(
        <String>[
          'sqlite3',
          db.path,
          "UPDATE access SET auth_value = 2 WHERE service = 'kTCCServiceAppleEvents' AND indirect_object_identifier = 'com.apple.dt.Xcode'"
        ],
      );

      print('Update Result: ${replaceResult.exitCode}');
      print('[stdout]: ${replaceResult.stdout.toString().trim()}');
      print('[stderr]: ${replaceResult.stderr.toString().trim()}');

      if (replaceResult.exitCode == 0) {
        return;
      }

    } else {
      print('Unable to find HOME');
    }
  }
}