// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    'flutter devices, doctor, and config display custom extensions when extension prototype is enabled',
    () async {
      final String workingDirectory = getFlutterRoot();
      final Directory tempHome = createResolvedTempDirectorySync('home.');
      final String tempHomePath = tempHome.path;

      try {
        // 1. Run flutter devices to check custom device discovery
        final ProcessResult devicesResult = await processManager.run(
          <String>[flutterBin, ...getLocalEngineArguments(), 'devices'],
          environment: <String, String>{
            'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true',
            'HOME': tempHomePath,
          },
          workingDirectory: workingDirectory,
        );

        expect(devicesResult.exitCode, 0);
        expect(devicesResult.stdout, contains('Linux Desktop Target'));
        expect(devicesResult.stdout, contains('linux-proto-1'));
        expect(devicesResult.stdout, contains('linux-x64'));

        // 2. Run flutter doctor -v to check GEP diagnostics integration
        final ProcessResult doctorResult = await processManager.run(
          <String>[flutterBin, ...getLocalEngineArguments(), 'doctor', '-v'],
          environment: <String, String>{
            'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true',
            'HOME': tempHomePath,
          },
          workingDirectory: workingDirectory,
        );

        expect(doctorResult.exitCode, 0);
        expect(doctorResult.stdout, contains('Extension-backed Diagnostics'));

        // 3. Test flutter config CLI integration with GEP custom options
        // Enable custom feature
        final ProcessResult configEnableResult = await processManager.run(
          <String>[
            flutterBin,
            ...getLocalEngineArguments(),
            'config',
            '--enable-custom-linux-feature',
          ],
          environment: <String, String>{
            'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true',
            'HOME': tempHomePath,
          },
          workingDirectory: workingDirectory,
        );
        expect(configEnableResult.exitCode, 0);

        // List settings to verify it is enabled
        final ProcessResult configListResult = await processManager.run(
          <String>[flutterBin, ...getLocalEngineArguments(), 'config', '--list'],
          environment: <String, String>{
            'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true',
            'HOME': tempHomePath,
          },
          workingDirectory: workingDirectory,
        );
        expect(configListResult.exitCode, 0);
        expect(configListResult.stdout, contains('enable-custom-linux-feature: true'));

        // Disable custom feature
        final ProcessResult configDisableResult = await processManager.run(
          <String>[
            flutterBin,
            ...getLocalEngineArguments(),
            'config',
            '--no-enable-custom-linux-feature',
          ],
          environment: <String, String>{
            'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true',
            'HOME': tempHomePath,
          },
          workingDirectory: workingDirectory,
        );
        expect(configDisableResult.exitCode, 0);

        // List settings to verify it is disabled
        final ProcessResult configListDisableResult = await processManager.run(
          <String>[flutterBin, ...getLocalEngineArguments(), 'config', '--list'],
          environment: <String, String>{
            'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true',
            'HOME': tempHomePath,
          },
          workingDirectory: workingDirectory,
        );
        expect(configListDisableResult.exitCode, 0);
        expect(configListDisableResult.stdout, contains('enable-custom-linux-feature: false'));
      } finally {
        tempHome.deleteSync(recursive: true);
      }
    },
    skip: !platform.isLinux, // GEP Linux extension prototype is Linux-only
  );
}
