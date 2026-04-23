// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;

import '../integration.shard/test_data/hot_reload_outside_lib_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

/// Regression test for https://github.com/flutter/flutter/issues/175318.
void main() {
  late Directory tempDir;
  final project = HotReloadOutsideLibProject();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_outside_lib_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    await flutter.done;
    tryToDelete(tempDir);
  });

  testWithoutContext('hot reload applies code changes for an entrypoint outside lib/', () async {
    await flutter.run(
      device: GoogleChromeDevice.kChromeDeviceId,
      script: 'integration_test/main.dart',
      additionalCommandArgs: <String>[
        '--verbose',
        '--no-web-resources-cdn',
        '--web-experimental-hot-reload',
      ],
    );

    // Uncomment the print statement and hot reload to verify the change is actually applied.
    final completer = Completer<void>();
    final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
      printOnFailure(line);
      if (line.contains('(((((RELOAD WORKED)))))')) {
        completer.complete();
      }
    });
    project.uncommentHotReloadPrint();
    try {
      await flutter.hotReload();
      await completer.future.timeout(const Duration(seconds: 15));
    } finally {
      await subscription.cancel();
    }
  });
}
