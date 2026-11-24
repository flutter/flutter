// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'dart_data_asset_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(setUpAllDataAssets);
  setUp(setUpDataAssets);
  tearDown(tearDownDataAssets);

  group('dart data assets', () {
    testWithoutContext('flutter test', () async {
      final ProcessTestResult result = await runFlutter(
        <String>['test', '-v'],
        appRoot.path,
        <Transition>[Barrier(RegExp('.* All tests passed!'))],
      );
      if (result.exitCode != 0) {
        throw Exception(
          'flutter test failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
        );
      }
    });
  });
}
