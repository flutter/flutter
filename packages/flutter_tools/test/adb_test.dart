// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/adb.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  final String adbPath = new OperatingSystemUtils().which('adb')?.path;
  final Adb adb = new Adb(adbPath);

  // We only test the [Adb] class is we're able to locate the adb binary.
  if (processManager.runSync(<String>[adbPath, 'version']).exitCode != 0)
    return;

  group('adb', () {
    testUsingContext('getVersion', () {
      expect(adb.getVersion(), isNotEmpty);
    });

    testUsingContext('getServerVersion', () async {
      adb.startServer();

      final String version = await adb.getServerVersion();
      expect(version, isNotEmpty);
    });

    testUsingContext('listDevices', () async {
      adb.startServer();

      final List<AdbDevice> devices = await adb.listDevices();

      // Any result is ok.
      expect(devices, isList);
    });
  });
}
