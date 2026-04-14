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

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    // TODO(dacoharkes): Implement Fuchsia. https://github.com/flutter/flutter/issues/129757
    return;
  }

  testWithoutContext('flutter test with native assets', () async {
    await inTempDir((Directory tempDirectory) async {
      final Directory packageDirectory = await createTestProject(packageName, tempDirectory);

      final ProcessTestResult result = await runFlutter(
        <String>['test'],
        packageDirectory.path,
        <Transition>[Barrier(RegExp('.* All tests passed!'))],
        logging: false,
      );
      if (result.exitCode != 0) {
        throw Exception(
          'flutter test failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
        );
      }
    });
  });
}
