// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test exercises dynamic libraries added to a flutter app or package.
// It covers:
//  * `flutter run`, including hot reload and hot restart
//  * `flutter test`
//  * `flutter build`

@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart' show flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;

final add2appBuildSubcommands = <String>[
  if (hostOs == 'macos') ...<String>['macos-framework', 'ios-framework'],
];

/// The build modes to target for each flutter command that supports passing
/// a build mode.
///
/// The flow of compiling kernel as well as bundling dylibs can differ based on
/// build mode, so we should cover this.
const buildModes = <String>['debug', 'profile', 'release'];

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    // TODO(dacoharkes): Implement Fuchsia. https://github.com/flutter/flutter/issues/129757
    return;
  }

  for (final String add2appBuildSubcommand in add2appBuildSubcommands) {
    testWithoutContext('flutter build $add2appBuildSubcommand with native assets', () async {
      await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
        final Directory exampleDirectory = packageDirectory.childDirectory('example');

        final ProcessResult result = processManager.runSync(<String>[
          flutterBin,
          'build',
          add2appBuildSubcommand,
          '--codesign-identity',
          '-',
        ], workingDirectory: exampleDirectory.path);
        if (result.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }

        for (final String buildMode in buildModes) {
          expectDylibIsBundledWithFrameworks(
            exampleDirectory,
            buildMode,
            add2appBuildSubcommand.replaceAll('-framework', ''),
          );
        }
        expectCCompilerIsConfigured(exampleDirectory);
      });
    });
  }
}
