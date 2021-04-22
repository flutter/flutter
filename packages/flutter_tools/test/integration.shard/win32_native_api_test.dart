// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/isolated/native_api_win32.dart';
import 'package:flutter_tools/src/windows/native_api.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  // By its nature, this test can only run on a windows machine.
  testWithoutContext('win32 Native API can correctly launch an application', () async {
    int calculatorPid;
    try {
      const String name = 'Microsoft.WindowsCalculator';
      final String amuidLookup = fileSystem.path.join(getFlutterRoot(), 'packages', 'flutter_tools', 'bin', 'getaumidfromname.ps1');

      final ProcessResult result = await processManager.run(<String>['powershell.exe', amuidLookup, '-Name', name]);
      if (result.exitCode != 0) {
        fail('Failed to retrieve AMUID for $name: ${result.exitCode}\n${result.stdout}${result.stdout}');
      }

      final String aumidstring = result.stdout.toString().trim();
      const NativeApi nativeApi = Win32NativeApi();
      calculatorPid = nativeApi.launchApp(aumidstring);

      // Verify that the app started.
      final ProcessResult psCheck = await processManager.run(<String>['powershell.exe', 'ps', '-id', '$calculatorPid']);
      if (psCheck.exitCode != 0) {
        fail('Failed to lookup process ID: ${psCheck.exitCode}\n${psCheck.stdout}${psCheck.stdout}');
      }

      expect(psCheck.stdout, contains('Calculator'));
    } finally {
      if (calculatorPid != null) {
        processManager.killPid(calculatorPid);
      }
    }
  }, skip: !platform.isWindows);
}
