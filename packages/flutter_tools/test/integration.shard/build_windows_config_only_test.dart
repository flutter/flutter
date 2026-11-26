// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    'flutter build windows --config-only updates generated build files without performing build',
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
        'windows',
        '--config-only',
        '-v',
      ];
      await processManager.run(buildCommand, workingDirectory: workingDirectory);

      final arch = Abi.current() == Abi.windowsArm64 ? 'arm64' : 'x64';

      // Solution file should be created.
      final File generatedConfig = fileSystem.file(
        fileSystem.path.join(workingDirectory, 'build', 'windows', arch, 'flutter_gallery.sln'),
      );
      expect(generatedConfig, exists);

      // No code should be compiled.
      final File appLibrary = fileSystem.file(
        fileSystem.path.join(workingDirectory, 'build', 'windows', 'app.so'),
      );
      final File exe = fileSystem.file(
        fileSystem.path.join(
          workingDirectory,
          'build',
          'windows',
          arch,
          'runner',
          'Release',
          'flutter_gallery.exe',
        ),
      );
      expect(appLibrary, isNot(exists));
      expect(exe, isNot(exists));
    },
    skip: !platform.isWindows, // [intended] Windows builds only work on Windows.
  );

  test(
    'flutter build windows --config-only installs next to the executable after a failed configure',
    () async {
      final Directory tempDir = createResolvedTempDirectorySync('install_prefix_test.');
      try {
        await expectLater(
          processManager.run(<String>[
            flutterBin,
            'create',
            '--template=plugin_ffi',
            '--platforms=windows',
            '--no-pub',
            'install_prefix_test',
          ], workingDirectory: tempDir.path),
          completion(const ProcessResultMatcher()),
        );
        final Directory pluginDirectory = tempDir.childDirectory('install_prefix_test');

        // Make a plugin fail the configure, as there are no system dependencies to
        // remove on Windows.
        pluginDirectory
            .childDirectory('windows')
            .childFile('CMakeLists.txt')
            .writeAsStringSync(
              'if(DEFINED ENV{FAIL_CONFIGURE})\n'
              '  message(FATAL_ERROR "Configure failed")\n'
              'endif()\n',
              mode: FileMode.append,
            );

        final String workingDirectory = pluginDirectory.childDirectory('example').path;
        final buildCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'windows',
          '--config-only',
        ];

        final ProcessResult failedResult = await processManager.run(
          buildCommand,
          workingDirectory: workingDirectory,
          environment: <String, String>{'FAIL_CONFIGURE': '1'},
        );
        expect(failedResult.exitCode, isNot(0));

        await expectLater(
          processManager.run(buildCommand, workingDirectory: workingDirectory),
          completion(const ProcessResultMatcher()),
        );

        final arch = Abi.current() == Abi.windowsArm64 ? 'arm64' : 'x64';
        final String cache = fileSystem
            .file(
              fileSystem.path.join(workingDirectory, 'build', 'windows', arch, 'CMakeCache.txt'),
            )
            .readAsStringSync();
        expect(
          cache,
          contains(r'CMAKE_INSTALL_PREFIX:PATH=$<TARGET_FILE_DIR:install_prefix_test_example>'),
        );
      } finally {
        tryToDelete(tempDir);
      }
    },
    skip: !platform.isWindows, // [intended] Windows builds only work on Windows.
  );
}
