// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' show Abi;

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late Directory projectRoot;
  late String arch;

  group('flutter build linux command', () {
    setUpAll(() {
      tempDir = createResolvedTempDirectorySync('build_linux_test.');
      ProcessResult result = processManager.runSync(<String>[
        flutterBin,
        'config',
        '--enable-linux-desktop',
      ]);
      expect(result, const ProcessResultMatcher());

      result = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'create',
        '--platforms=linux',
        'hello',
      ], workingDirectory: tempDir.path);
      expect(result, const ProcessResultMatcher());

      projectRoot = tempDir.childDirectory('hello');
      arch = Abi.current() == Abi.linuxArm64 ? 'arm64' : 'x64';
    });

    tearDownAll(() {
      tryToDelete(tempDir);
    });

    test('bundles libvmservice_snapshot.so in profile mode only', () {
      final ProcessResult profileResult = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'linux',
        '--profile',
        '--no-pub',
      ], workingDirectory: projectRoot.path);
      expect(profileResult, const ProcessResultMatcher());

      final Directory profileBundle = fileSystem.directory(
        fileSystem.path.join(projectRoot.path, 'build', 'linux', arch, 'profile', 'bundle'),
      );
      expect(profileBundle.childFile('hello'), exists);
      expect(profileBundle.childDirectory('lib').childFile('libvmservice_snapshot.so'), exists);

      final ProcessResult releaseResult = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'linux',
        '--release',
        '--no-pub',
      ], workingDirectory: projectRoot.path);
      expect(releaseResult, const ProcessResultMatcher());

      final Directory releaseBundle = fileSystem.directory(
        fileSystem.path.join(projectRoot.path, 'build', 'linux', arch, 'release', 'bundle'),
      );
      expect(releaseBundle.childFile('hello'), exists);
      expect(
        releaseBundle.childDirectory('lib').childFile('libvmservice_snapshot.so'),
        isNot(exists),
      );
    });

    test('bundles libvmservice_snapshot.so with cmake_minimum_required 3.14', () {
      final File cmakeLists = projectRoot.childDirectory('linux').childFile('CMakeLists.txt');
      final String original = cmakeLists.readAsStringSync();
      expect(original, contains('cmake_minimum_required(VERSION 3.13)'));
      cmakeLists.writeAsStringSync(
        original.replaceFirst(
          'cmake_minimum_required(VERSION 3.13)',
          'cmake_minimum_required(VERSION 3.14)',
        ),
      );

      final ProcessResult profileResult = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'linux',
        '--profile',
        '--no-pub',
      ], workingDirectory: projectRoot.path);
      expect(profileResult, const ProcessResultMatcher());

      final Directory profileBundle = fileSystem.directory(
        fileSystem.path.join(projectRoot.path, 'build', 'linux', arch, 'profile', 'bundle'),
      );
      expect(profileBundle.childFile('hello'), exists);
      expect(profileBundle.childDirectory('lib').childFile('libvmservice_snapshot.so'), exists);
    });
  }, skip: !platform.isLinux); // [intended] Linux integration build.
}
