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

  test(
    'flutter build linux --config-only installs to the bundle after a failed configure',
    () async {
      final Directory tempDir = createResolvedTempDirectorySync('install_prefix_test.');
      try {
        await expectLater(
          processManager.run(<String>[
            flutterBin,
            'create',
            '--platforms=linux',
            '--no-pub',
            'install_prefix_test',
          ], workingDirectory: tempDir.path),
          completion(const ProcessResultMatcher()),
        );
        final String workingDirectory = tempDir.childDirectory('install_prefix_test').path;
        final buildCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'linux',
          '--config-only',
        ];

        // Fail the first configure by making system dependencies unavailable.
        final ProcessResult failedResult = await processManager.run(
          buildCommand,
          workingDirectory: workingDirectory,
          environment: <String, String>{
            'PKG_CONFIG_LIBDIR': '/nonexistent',
            'PKG_CONFIG_PATH': '/nonexistent',
          },
        );
        expect(failedResult.exitCode, isNot(0));

        await expectLater(
          processManager.run(buildCommand, workingDirectory: workingDirectory),
          completion(const ProcessResultMatcher()),
        );

        final arch = Abi.current() == Abi.linuxArm64 ? 'arm64' : 'x64';
        final String buildDirectory = fileSystem.path.join(
          workingDirectory,
          'build',
          'linux',
          arch,
          'release',
        );
        final String cache = fileSystem
            .file(fileSystem.path.join(buildDirectory, 'CMakeCache.txt'))
            .readAsStringSync();
        expect(
          cache,
          contains('CMAKE_INSTALL_PREFIX:PATH=${fileSystem.path.join(buildDirectory, 'bundle')}\n'),
        );
      } finally {
        tryToDelete(tempDir);
      }
    },
    skip: !platform.isLinux, // [intended] Linux builds only work on Linux.
  );

  test(
    'flutter build linux --config-only propagates local engine options to generated_config.cmake',
    () async {
      final Directory tempDir = createResolvedTempDirectorySync('local_engine_test.');
      final Directory engineSrc = tempDir.childDirectory('engine').childDirectory('src');
      engineSrc.childDirectory('out').childDirectory('host_debug').createSync(recursive: true);

      final String workingDirectory = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'flutter_gallery',
      );

      try {
        await processManager.run(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'pub',
          'get',
        ], workingDirectory: workingDirectory);
        final buildCommand = <String>[
          flutterBin,
          '--local-engine=host_debug',
          '--local-engine-host=host_debug',
          '--local-engine-src-path=${engineSrc.path}',
          'build',
          'linux',
          '--config-only',
          '--no-pub',
          '-v',
        ];
        final ProcessResult result = await processManager.run(
          buildCommand,
          workingDirectory: workingDirectory,
        );

        expect(
          result.exitCode,
          0,
          reason:
              'Command failed with exitCode ${result.exitCode}.\n'
              'STDOUT:\n${result.stdout}\n'
              'STDERR:\n${result.stderr}',
        );

        final File generatedConfig = fileSystem.file(
          fileSystem.path.join(
            workingDirectory,
            'linux',
            'flutter',
            'ephemeral',
            'generated_config.cmake',
          ),
        );
        expect(generatedConfig, exists);
        final String content = generatedConfig.readAsStringSync();
        expect(content, contains('"LOCAL_ENGINE=host_debug"'));
        expect(content, contains('"LOCAL_ENGINE_HOST=host_debug"'));
        expect(content, contains('"FLUTTER_ENGINE=${engineSrc.path}"'));
      } finally {
        tryToDelete(tempDir);
        tryToDelete(
          fileSystem.directory(
            fileSystem.path.join(workingDirectory, 'linux', 'flutter', 'ephemeral'),
          ),
        );
      }
    },
    skip: !platform.isLinux, // [intended] Linux builds only work on Linux.
  );
}
