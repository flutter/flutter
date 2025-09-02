// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:async';

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_data/websocket_dwds_test_common.dart';
import 'test_driver.dart';
import 'test_utils.dart';
import 'transition_test_utils.dart';

void main() {
  testAll();
}

void testAll({List<String> additionalCommandArgs = const <String>[]}) {
  group('WebSocket DWDS connection for hot restart'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    // Test configuration constants
    const hotRestartTimeout = Duration(seconds: 15);

    late Directory tempDir;
    final project = HotReloadProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_restart_websocket_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext(
      'hot restart with headless Chrome WebSocket connection',
      () async {
        debugPrint('Starting WebSocket DWDS test with headless Chrome for hot restart...');

        // Set up WebSocket connection
        final WebSocketDwdsTestSetup setup = await WebSocketDwdsTestUtils.setupWebSocketConnection(
          flutter,
          additionalCommandArgs: additionalCommandArgs,
        );

        try {
          // Test hot restart functionality
          debugPrint('Step 6: Testing hot restart with WebSocket connection...');
          await flutter.hotRestart().timeout(
            hotRestartTimeout,
            onTimeout: () {
              throw Exception('Hot restart timed out');
            },
          );

          // Give some time for logs to capture
          await Future<void>.delayed(const Duration(seconds: 2));

          final output = setup.stdout.toString();
          expect(
            output,
            contains('Restarted application'),
            reason: 'Hot restart should complete successfully',
          );
          debugPrint('✓ Hot restart completed successfully with WebSocket connection');

          // Verify the correct infrastructure was used
          WebSocketDwdsTestUtils.verifyWebSocketInfrastructure(output);

          debugPrint('✓ WebSocket DWDS test completed successfully');
          debugPrint('✓ Verified: web-server device + DWDS + WebSocket connection + hot restart');
        } finally {
          await cleanupWebSocketTestResources(setup.chromeProcess, setup.subscription);
        }
      },
      skip: !platform.isMacOS, // Skip on non-macOS platforms where Chrome paths may differ
    );
  });
}
