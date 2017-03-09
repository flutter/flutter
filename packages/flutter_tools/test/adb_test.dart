// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/adb.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  final Adb adb = new Adb('adb');

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
