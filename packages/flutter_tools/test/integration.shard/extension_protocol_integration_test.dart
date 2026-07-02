// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    'flutter devices and flutter doctor display custom devices and diagnostics when extension prototype is enabled',
    () async {
      final String workingDirectory = getFlutterRoot();

      // 1. Run flutter devices to check custom device discovery
      final ProcessResult devicesResult = await processManager.run(
        <String>[flutterBin, ...getLocalEngineArguments(), 'devices'],
        environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
        workingDirectory: workingDirectory,
      );

      expect(devicesResult.exitCode, 0);
      expect(devicesResult.stdout, contains('Linux Desktop Target'));
      expect(devicesResult.stdout, contains('linux-proto-1'));
      expect(devicesResult.stdout, contains('linux-x64'));

      // 2. Run flutter doctor -v to check GEP diagnostics integration
      final ProcessResult doctorResult = await processManager.run(
        <String>[flutterBin, ...getLocalEngineArguments(), 'doctor', '-v'],
        environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
        workingDirectory: workingDirectory,
      );

      expect(doctorResult.exitCode, 0);
      expect(doctorResult.stdout, contains('Extension-backed Diagnostics'));
    },
    skip: !platform.isLinux, // GEP Linux extension prototype is Linux-only
  );
}
