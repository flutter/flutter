// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../globals.dart';
import '../runner/flutter_command.dart';

class RefreshCommand extends FlutterCommand {
  final String name = 'refresh';
  final String description = 'Build and deploy the Dart code in a Flutter app (Android only).';

  RefreshCommand() {
    addTargetOption();
  }

  bool get androidOnly => true;

  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    printTrace('Downloading toolchain.');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ], eagerError: true);

    if (devices.android == null) {
      printError('No device connected.');
      return 1;
    }

    Directory tempDir = await Directory.systemTemp.createTemp('flutter_tools');
    try {
      String snapshotPath = path.join(tempDir.path, 'snapshot_blob.bin');

      int result = await toolchain.compiler.compile(
          mainPath: argResults['target'], snapshotPath: snapshotPath
      );
      if (result != 0) {
        printError('Failed to run the Flutter compiler. Exit code: $result');
        return result;
      }

      bool success = await devices.android.refreshSnapshot(
          applicationPackages.android, snapshotPath
      );
      if (!success) {
        printError('Error refreshing snapshot on ${devices.android.name}.');
        return 1;
      }

      return 0;
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }
}
