// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/chrome.dart' show kChromeEnvironment;
import 'package:path/path.dart';
import 'package:platform/platform.dart';
import '../integration.shard/test_data/hot_reload_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

// import 'test_data/web_server_test_common.dart';

void main() {
  group('hot reload on web server device', () {
    late Directory tempDir;
    final project = HotReloadProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_web_server_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext('works before connecting a browser, '
        'with a connected chrome browser '
        'and after disconnecting the browser.', () async {
      final String? chromeExecutable = const LocalPlatform().environment[kChromeEnvironment];
      if (chromeExecutable == null) {
        throw StateError('Chrome executable not found in environment ($kChromeEnvironment).');
      }
      io.ProcessResult result = io.Process.runSync(chromeExecutable, <String>['--version']);

      printOnFailure(
        '\n'
        'kChromeEnvironment\n'
        'Executable: $chromeExecutable\n'
        '$chromeExecutable --version:\n${result.stdout}\n'
        '=========================================================\n',
      );

      var chromedriverPath = '';

      for (final String pathPart in split(chromeExecutable)) {
        join(chromedriverPath, pathPart);
        if (pathPart == 'chrome') {
          break;
        }
      }
      chromedriverPath = join(chromedriverPath, 'drivers', 'chromedriver');

      result = io.Process.runSync(chromedriverPath, <String>['--version']);
      printOnFailure(
        'chromedriver next to chrome from CIPD\n'
        'Executable: $chromedriverPath\n'
        '$chromedriverPath --version: ${result.stdout}\n'
        '=========================================================\n',
      );

      result = io.Process.runSync('which', <String>['chromedriver']);
      final String whichChromeDriverStdout = result.stdout.toString().trim();
      result = io.Process.runSync(whichChromeDriverStdout, <String>['--version']);
      printOnFailure(
        'which chromedriver: $whichChromeDriverStdout\n'
        '$whichChromeDriverStdout --version: ${result.stdout}'
        '=========================================================\n',
      );

      final String? pathEnv = const LocalPlatform().environment['PATH'];
      printOnFailure(
        'PATH:\n'
        '$pathEnv\n'
        '=========================================================\n',
      );
      throw Exception('FAIL TEST ON PURPOSE TO GET PRINTING!');
      // These could all be individual test cases but are combined here to share
      // the overhead of flutter run with can take 20 seconds or more on CI.
      // final testRunner = WebServerDeviceTestRunner(flutter);
      // try {
      //   final String appUrl = await testRunner.runWebServerDevice();
      //   // Request a hot reload without any edits or connected browsers.
      //   await expectLater(testRunner.hotReload(), completes);
      //   // Request a hot reload after an edit without any connected browsers.
      //   project.uncommentHotReloadPrint();
      //   await expectLater(testRunner.hotReload(), completes);
      //   // Restore the previous edit.
      //   project.commentHotReloadPrint();
      //   await expectLater(testRunner.hotReload(), completes);
      //   // Connect a chrome browser to load the application.
      //   await testRunner.connectWithChrome(appUrl);
      //   // Wait for a logged message from the Flutter app to confirm it has started.
      //   await expectLater(
      //     testRunner.findNextInBrowserLog('((((TICK 1))))', appStartTimeout),
      //     completes,
      //   );
      //   // Request a hot reload after an edit.
      //   project.uncommentHotReloadPrint();
      //   await expectLater(testRunner.hotReload(), completes);
      //   // Confirm build counter was incremented.
      //   await expectLater(
      //     testRunner.findNextInBrowserLog('((((TICK 2))))', defaultTimeout),
      //     completes,
      //   );
      //   // Confirm the new code ran in the browser.
      //   await expectLater(
      //     testRunner.findNextInBrowserLog('(((((RELOAD WORKED)))))', defaultTimeout),
      //     completes,
      //   );
      //   // Close the browser.
      //   await expectLater(testRunner.quitBrowser(), completes);
      //   // Request a hot reload without any edits or connected browsers.
      //   await expectLater(testRunner.hotReload(), completes);
      // } finally {
      //   await testRunner.cleanup();
      // }
    });
  });
}
