// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;

import '../../src/common.dart';
import '../test_driver.dart';
import '../test_utils.dart';
import 'hot_reload_const_project.dart';

void testAll({
  bool chrome = false,
  List<String> additionalCommandArgs = const <String>[],
  Object? skip = false,
}) {
  group('chrome: $chrome'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    late Directory tempDir;
    final HotReloadConstProject project = HotReloadConstProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext(
      'hot reload displays a formatted error message when removing a field from a const class, and hot restart succeeds',
      () async {
        await flutter.run(
          device:
              chrome ? GoogleChromeDevice.kChromeDeviceId : FlutterTesterDevices.kTesterDeviceId,
          additionalCommandArgs: additionalCommandArgs,
        );

        project.removeFieldFromConstClass();
        await expectLater(
          flutter.hotReload(),
          throwsA(
            isA<Exception>().having(
              (Exception e) => e.toString(),
              'message',
              contains('Try performing a hot restart instead.'),
            ),
          ),
        );

        await expectLater(flutter.hotRestart(), completes);
      },
    );
  });
}
