// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/adb.dart';
import 'package:test/test.dart';

void main() {
  final Adb adb = new Adb('adb');

  // We only test the [Adb] class is we're able to locate the adb binary.
  if (!adb.exists())
    return;

  group('adb', () {
    test('getVersion', () {
      expect(adb.getVersion(), isNotEmpty);
    });

    test('getServerVersion', () async {
      adb.startServer();

      final String version = await adb.getServerVersion();
      expect(version, isNotEmpty);
    });

    test('listDevices', () async {
      adb.startServer();

      final List<AdbDevice> devices = await adb.listDevices();

      // Any result is ok.
      expect(devices, isList);
    });
  });
}
