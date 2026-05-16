// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;

import '../../integration.shard/test_data/hot_reload_outside_lib_project.dart';
import '../../integration.shard/test_driver.dart';
import '../../integration.shard/test_utils.dart';
import '../../src/common.dart';

enum HotAction { reload, restart }

/// Regression test body for https://github.com/flutter/flutter/issues/175318.
///
/// Shared between the hot reload and hot restart variants.
void testHotActionOutsideLib(HotAction action) {
  late Directory tempDir;
  final project = HotReloadOutsideLibProject();
  late FlutterRunTestDriver flutter;
  final String actionName = switch (action) {
    HotAction.reload => 'hot reload',
    HotAction.restart => 'hot restart',
  };

  setUp(() async {
    tempDir = createResolvedTempDirectorySync(
      '${actionName.replaceAll(' ', '_')}_outside_lib_test.',
    );
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    await flutter.done;
    tryToDelete(tempDir);
  });

  testWithoutContext('$actionName applies code changes for an entrypoint outside lib/', () async {
    await flutter.run(
      device: GoogleChromeDevice.kChromeDeviceId,
      script: 'integration_test/main.dart',
      additionalCommandArgs: <String>[
        '--verbose',
        '--no-web-resources-cdn',
        '--web-experimental-hot-reload',
      ],
    );

    final completer = Completer<void>();
    final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
      printOnFailure(line);
      if (line.contains('(((((RELOAD WORKED)))))')) {
        completer.complete();
      }
    });
    project.uncommentHotReloadPrint();
    try {
      await switch (action) {
        HotAction.reload => flutter.hotReload(),
        HotAction.restart => flutter.hotRestart(),
      };
      await completer.future.timeout(const Duration(seconds: 15));
    } finally {
      await subscription.cancel();
    }
  });
}
