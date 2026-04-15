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

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;

final devices = <String>['flutter-tester', hostOs];

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

  for (final String device in devices) {
    for (final String buildMode in buildModes) {
      if (device == 'flutter-tester' && buildMode != 'debug') {
        continue;
      }
      final hotReload = buildMode == 'debug' ? ' hot reload and hot restart' : '';
      testWithoutContext('flutter run$hotReload with native assets $device $buildMode', () async {
        await inTempDir((Directory tempDirectory) async {
          final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
          final Directory exampleDirectory = packageDirectory.childDirectory('example');

          final ProcessTestResult result = await runFlutter(
            <String>['run', '-d$device', '--$buildMode'],
            exampleDirectory.path,
            <Transition>[
              Multiple.contains(
                <Pattern>['Flutter run key commands.'],
                handler: (String line) {
                  if (buildMode == 'debug') {
                    // Do a hot reload diff on the initial dill file.
                    return 'r';
                  } else {
                    // No hot reload and hot restart in release mode.
                    return 'q';
                  }
                },
              ),
              if (buildMode == 'debug') ...<Transition>[
                Barrier.contains('Performing hot reload...', logging: true),
                Multiple(
                  <Pattern>[RegExp('Reloaded .*')],
                  handler: (String line) {
                    // Do a hot restart, pushing a new complete dill file.
                    return 'R';
                  },
                ),
                Barrier.contains('Performing hot restart...'),
                Multiple(
                  <Pattern>[RegExp('Restarted application .*')],
                  handler: (String line) {
                    // Do another hot reload, pushing a diff to the second dill file.
                    return 'r';
                  },
                ),
                Barrier.contains('Performing hot reload...', logging: true),
                Multiple(
                  <Pattern>[RegExp('Reloaded .*')],
                  handler: (String line) {
                    return 'q';
                  },
                ),
              ],
              Barrier.contains('Application finished.'),
            ],
            logging: false,
          );
          if (result.exitCode != 0) {
            throw Exception(
              'flutter run failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
            );
          }
          final String stdout = result.stdout.join('\n');
          // Check that we did not fail to resolve the native function in the
          // dynamic library.
          expect(
            stdout,
            isNot(contains("Invalid argument(s): Couldn't resolve native function 'sum'")),
          );
          // And also check that we did not have any other exceptions that might
          // shadow the exception we would have gotten.
          expect(stdout, isNot(contains('EXCEPTION CAUGHT BY WIDGETS LIBRARY')));

          switch (device) {
            case 'macos':
              expectDylibIsBundledMacOS(exampleDirectory, buildMode);
            case 'linux':
              expectDylibIsBundledLinux(exampleDirectory, buildMode);
            case 'windows':
              expectDylibIsBundledWindows(exampleDirectory, buildMode);
          }
          if (device == hostOs) {
            expectCCompilerIsConfigured(exampleDirectory);
          }
        });
      });
    }
  }
}
