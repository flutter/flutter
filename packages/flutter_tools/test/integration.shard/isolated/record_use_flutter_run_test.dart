// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'record_use_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(setUpAllRecordUse);
  setUp(setUpRecordUse);
  tearDown(tearDownRecordUse);

  group('record use', () {
    // This test relies on running the flutter app and capturing `print()`s
    // the app prints to determine if the test succeeded.
    // `flutter run --release` on the web doesn't support capturing
    // prints. See https://github.com/flutter/flutter/issues/159668
    // So this test only does `flutter run` for the hostOS.
    for (final device in <String>[hostOs]) {
      testWithoutContext('flutter run on $device --release', () async {
        final ProcessTestResult result = await runFlutter(
          <String>['run', '-v', '-d', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('Launching lib${Platform.pathSeparator}main.dart on'),
            Multiple.contains(
              <Pattern>[
                'Flutter run key command',

                // The translations are found.
                'HELLO: Ahoy!',
                'FRIEND: Matey',

                // The translations are tree-shaken.
                'COUNT: $expectedTranslationCount',
              ],
              handler: (_) {
                return 'q';
              },
            ),
            Barrier.contains('Application finished.'),
          ],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter run failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
      });
    }
  });
}
