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
  xcodeDebugTest.resetPermissions();
}

class XcodeDebugTest {

  File? db;
  File? backup;

  Future<void> debugAutomation() async {
    print('Debugging automation...');
    const FileSystem fileSystem = LocalFileSystem();
    const ProcessManager processManager = LocalProcessManager();

    final String? home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final Directory tccDir = fileSystem.directory(fileSystem.path.join(home, 'Library', 'Application Support', 'com.apple.TCC'));
      db = tccDir.childFile('TCC.db');
      final File localDB = db!;
      try {
        if (!localDB.existsSync()) {
          print('File ${localDB.path} does not exist');
          return;
        }
      } on PathAccessException {
        print('Path Access to ${localDB.path} failed');
        return;
      }

      // Select from db
      await queryDB(db: localDB, processManager: processManager);

      // create backup if there isn't one
      print('Creating backup...');
      backup = tccDir.childFile('TCC.db.backup');
      if (!backup!.existsSync()) {
        localDB.copySync(backup!.path);
      }

      final Directory tempDirectory = fileSystem.systemTempDirectory.createTempSync('temp_automation.');

      // Check if permission already given
      final Process scriptProcess = await processManager.start(
        <String>[
          'osascript',
          '-e',
          'tell app "Xcode"',
          '-e',
          'launch',
          '-e',
          'make "${tempDirectory.childFile('empty.txt').path}"',
          '-e',
          'end tell',
        ],
      );

      await Future.any(<Future<dynamic>>[
        scriptProcess.exitCode,
        Future<void>.delayed(const Duration(seconds: 5)),
      ]);

      scriptProcess.kill();

      final ProcessResult killProcess = await processManager.run(
        <String>[
          'killall',
          'UserNotificationCenter',
        ],
      );

      print('Kill Result: ${killProcess.exitCode}');
      print('[stdout]: ${killProcess.stdout.toString().trim()}');
      print('[stderr]: ${killProcess.stderr.toString().trim()}');

      // Select from db
      await queryDB(db: localDB, processManager: processManager);

      // Try updating db
      print('Updating real db...');
      final ProcessResult replaceResult = await processManager.run(
        <String>[
          'sqlite3',
          localDB.path,
          "UPDATE access SET auth_value = 2, auth_reason = 3, flags = NULL WHERE service = 'kTCCServiceAppleEvents' AND indirect_object_identifier = 'com.apple.dt.Xcode'"
        ],
      );

      print('Update Result: ${replaceResult.exitCode}');
      print('[stdout]: ${replaceResult.stdout.toString().trim()}');
      print('[stderr]: ${replaceResult.stderr.toString().trim()}');

      // Select from db
      await queryDB(db: localDB, processManager: processManager);

      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync();
      }

    } else {
      print('Unable to find HOME');
    }
  }

  void resetPermissions() {
    print('Restoring backup...');
    if (backup != null && db != null) {
      backup!.copySync(db!.path);
      backup!.deleteSync();
    }
  }

  Future<void> queryDB({
    required File db,
    required ProcessManager processManager,
  }) async {
    // Select from db
      print('Selecting from real db...');
      final ProcessResult accessResult = await processManager.run(
        <String>[
          'sqlite3',
          db.path,
          'SELECT service, client, client_type, auth_value, auth_reason, indirect_object_identifier_type, indirect_object_identifier, flags, last_modified FROM access WHERE service = "kTCCServiceAppleEvents"'
        ],
      );
      print('Access Result: ${accessResult.exitCode}');
      print('[stdout]: ${accessResult.stdout.toString().trim()}');
      print('[stderr]: ${accessResult.stderr.toString().trim()}');
  }
}
