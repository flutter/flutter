// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/device.dart';
import 'package:path/path.dart' as path;

import '../android/android_device.dart';
import '../application_package.dart';
import '../cache.dart';
import '../flx.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class RefreshCommand extends FlutterCommand {
  @override
  final String name = 'refresh';

  @override
  final String description = 'Build and deploy the Dart code in a Flutter app (Android only).';

  RefreshCommand() {
    usesTargetOption();

    argParser.addOption('activity',
      help: 'The Android activity that will be told to reload the Flutter code.'
    );
  }

  Device device;

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    device = await findTargetDevice(androidOnly: true);
    if (device == null)
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {
    Directory tempDir = await Directory.systemTemp.createTemp('flutter_tools');
    try {
      String snapshotPath = path.join(tempDir.path, 'snapshot_blob.bin');
      int result = await createSnapshot(mainPath: targetFile, snapshotPath: snapshotPath);

      if (result != 0) {
        printError('Failed to run the Flutter compiler. Exit code: $result');
        return result;
      }

      Cache.releaseLockEarly();

      String activity = argResults['activity'];
      if (activity == null) {
        AndroidApk apk = applicationPackages.getPackageForPlatform(device.platform);
        if (apk != null) {
          activity = apk.launchActivity;
        } else {
          printError('Unable to find the activity to be refreshed.');
          return 1;
        }
      }

      AndroidDevice androidDevice = device;

      bool success = await androidDevice.refreshSnapshot(activity, snapshotPath);
      if (!success) {
        printError('Error refreshing snapshot on $device.');
        return 1;
      }

      return 0;
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }
}
