// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'package:file/file.dart';

import '../integration.shard/test_data/hot_reload_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

import 'test_data/web_server_test_common.dart';

void main() {
  group('hot restart on web server device', () {
    late Directory tempDir;
    final project = HotReloadProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_restart_web_server_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext('works before and after connecting a chrome browser', () async {
      final testRunner = WebServerDeviceTestRunner(flutter);
      try {
        final String appUrl = await testRunner.runWebServerDevice();
        // Request a hot restart without any edits or connected browsers.
        await expectLater(testRunner.hotRestart(), completes);
        // Request a hot restart after an edit without any connected browsers.
        project.uncommentHotReloadPrint();
        await expectLater(testRunner.hotRestart(), completes);
        // Restore the previous edit.
        project.commentHotReloadPrint();
        await expectLater(testRunner.hotRestart(), completes);
        // Connect a chrome browser to load the application.
        await testRunner.connectWithChrome(appUrl);
        // Wait for a logged message from the Flutter app to confirm it has started.
        await expectLater(
          testRunner.findNextInBrowserLog('((((TICK 1))))', appStartTimeout),
          completes,
        );
        // Request a hot restart after an edit.
        project.uncommentHotReloadPrint();
        await expectLater(testRunner.hotRestart(), completes);
        // Confirm build counter was reset when the application restarted.
        await expectLater(
          testRunner.findNextInBrowserLog('((((TICK 1))))', defaultTimeout),
          completes,
        );
        // Confirm the new code ran in the browser.
        await expectLater(
          testRunner.findNextInBrowserLog('(((((RELOAD WORKED)))))', defaultTimeout),
          completes,
        );
        // Close the browser.
        await expectLater(testRunner.quitBrowser(), completes);
        // Request a hot restart without any edits or connected browsers.
        await expectLater(testRunner.hotRestart(), completes);
      } finally {
        await testRunner.cleanup();
      }
    });
  });
}
