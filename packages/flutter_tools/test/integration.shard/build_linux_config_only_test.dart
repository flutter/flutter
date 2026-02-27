// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    'flutter build linux --config-only updates generated build files without performing build',
    () async {
      final String workingDirectory = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'flutter_gallery',
      );

      await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);
      final buildCommand = <String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'linux',
        '--config-only',
        '-v',
      ];
      await processManager.run(buildCommand, workingDirectory: workingDirectory);

      final arch = Abi.current() == Abi.linuxArm64 ? 'arm64' : 'x64';

      // Build file should be created.
      final File generatedConfig = fileSystem.file(
        fileSystem.path.join(workingDirectory, 'build', 'linux', arch, 'release', 'build.ninja'),
      );
      expect(generatedConfig, exists);

      // No code should be compiled.
      final File appLibrary = fileSystem.file(
        fileSystem.path.join(workingDirectory, 'build', 'lib', 'libapp.so'),
      );
      final File exe = fileSystem.file(
        fileSystem.path.join(
          workingDirectory,
          'build',
          'linux',
          arch,
          'release',
          'intermediates_do_not_run',
          'flutter_gallery',
        ),
      );
      final File bundleExe = fileSystem.file(
        fileSystem.path.join(
          workingDirectory,
          'build',
          'linux',
          arch,
          'release',
          'bundle',
          'flutter_gallery',
        ),
      );
      expect(appLibrary, isNot(exists));
      expect(exe, isNot(exists));
      expect(bundleExe, isNot(exists));
    },
    skip: !platform.isLinux, // [intended] Linux builds only work on Linux.
  );
}
