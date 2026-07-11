// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    'flutter build macOS with FLUTTER_MACOS_ARM64_ONLY=true builds arm64-only binary in release mode',
    () async {
      final String workingDirectory = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'flutter_gallery',
      );

      // Clean the project.
      await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);

      // Build with FLUTTER_MACOS_ARM64_ONLY=true.
      final ProcessResult buildResult = await processManager.run(
        <String>[flutterBin, ...getLocalEngineArguments(), 'build', 'macos', '--release'],
        workingDirectory: workingDirectory,
        environment: <String, String>{'FLUTTER_MACOS_ARM64_ONLY': 'true'},
      );

      expect(buildResult.exitCode, 0, reason: 'Build failed: ${buildResult.stderr}');

      final File appBinary = fileSystem.file(
        fileSystem.path.join(
          workingDirectory,
          'build',
          'macos',
          'Build',
          'Products',
          'Release',
          'Flutter Gallery.app',
          'Contents',
          'MacOS',
          'Flutter Gallery',
        ),
      );

      expect(appBinary, exists);

      // Verify using lipo that it only contains arm64.
      final ProcessResult lipoResult = await processManager.run(<String>[
        'lipo',
        '-archs',
        appBinary.path,
      ]);

      expect(lipoResult.exitCode, 0);
      final lipoOutput = lipoResult.stdout as String;

      expect(lipoOutput.trim(), 'arm64');
    },
    skip: !platform.isMacOS, // [intended] macOS builds only work on macos.
  );
}
