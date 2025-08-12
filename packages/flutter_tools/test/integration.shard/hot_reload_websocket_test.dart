// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_device.dart' show WebServerDevice;

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';
import 'transition_test_utils.dart';

void main() {
  testAll();
}

void testAll({List<String> additionalCommandArgs = const <String>[]}) {
  group('WebSocket DWDS connection'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    // Test configuration constants
    const debugUrlTimeout = Duration(seconds: 20);
    const appStartTimeout = Duration(seconds: 15);
    const hotReloadTimeout = Duration(seconds: 10);

    late Directory tempDir;
    final project = HotReloadProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_websocket_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext(
      'hot reload with headless Chrome WebSocket connection',
      () async {
        debugPrint('Starting WebSocket DWDS test with headless Chrome...');

        // Set up listening for app output before starting
        final stdout = StringBuffer();
        final sawDebugUrl = Completer<String>();
        final StreamSubscription<String> subscription = flutter.stdout.listen((String e) {
          stdout.writeln(e);
          // Extract the debug connection URL
          if (e.contains('Waiting for connection from Dart debug extension at http://')) {
            final debugUrlPattern = RegExp(
              r'Waiting for connection from Dart debug extension at (http://[^\s]+)',
            );
            final Match? match = debugUrlPattern.firstMatch(e);
            if (match != null && !sawDebugUrl.isCompleted) {
              sawDebugUrl.complete(match.group(1)!);
            }
          }
        });

        io.Process? chromeProcess;
        try {
          // Step 1: Start Flutter app with web-server device (will wait for debug connection)
          debugPrint('Step 1: Starting Flutter app with web-server device...');
          // Start the app but don't wait for it to complete - it won't complete until Chrome connects
          final Future<void> appStartFuture = runFlutterWithWebServerDevice(
            flutter,
            additionalCommandArgs: [...additionalCommandArgs, '--no-web-resources-cdn'],
          );

          // Step 2: Wait for DWDS debug URL to be available
          debugPrint('Step 2: Waiting for DWDS debug service URL...');
          final String debugUrl = await sawDebugUrl.future.timeout(
            debugUrlTimeout,
            onTimeout: () {
              throw Exception('DWDS debug URL not found - app may not have started correctly');
            },
          );
          debugPrint('✓ DWDS debug service available at: $debugUrl');

          // Step 3: Launch headless Chrome to connect to DWDS
          debugPrint('Step 3: Launching headless Chrome to connect to DWDS...');
          chromeProcess = await _launchHeadlessChrome(debugUrl);
          debugPrint('✓ Headless Chrome launched and connecting to DWDS');

          // Step 4: Wait for app to start (Chrome connection established)
          debugPrint('Step 4: Waiting for Flutter app to start after Chrome connection...');
          await appStartFuture.timeout(
            appStartTimeout,
            onTimeout: () {
              throw Exception('App startup did not complete after Chrome connection');
            },
          );
          debugPrint('✓ Flutter app started successfully with WebSocket connection');

          // Step 5: Test hot reload functionality
          debugPrint('Step 5: Testing hot reload with WebSocket connection...');
          await flutter.hotReload().timeout(
            hotReloadTimeout,
            onTimeout: () {
              throw Exception('Hot reload timed out');
            },
          );

          // Give some time for logs to capture
          await Future<void>.delayed(const Duration(seconds: 2));

          final output = stdout.toString();
          expect(output, contains('Reloaded'), reason: 'Hot reload should complete successfully');
          debugPrint('✓ Hot reload completed successfully with WebSocket connection');

          // Verify the correct infrastructure was used
          expect(
            output,
            contains('Waiting for connection from Dart debug extension'),
            reason: 'Should wait for debug connection (WebSocket infrastructure)',
          );
          expect(output, contains('web-server'), reason: 'Should use web-server device');

          debugPrint('✓ WebSocket DWDS test completed successfully');
          debugPrint('✓ Verified: web-server device + DWDS + WebSocket connection + hot reload');
        } finally {
          await _cleanupResources(chromeProcess, subscription);
        }
      },
      skip: !platform.isMacOS, // Skip on non-macOS platforms where Chrome paths may differ
    );
  });
}

/// Launches headless Chrome with the given debug URL.
/// Uses findChromeExecutable to locate Chrome on the current platform.
Future<io.Process> _launchHeadlessChrome(String debugUrl) async {
  const chromeArgs = [
    '--headless',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-extensions',
    '--disable-dev-shm-usage',
    '--remote-debugging-port=0',
  ];

  final String chromePath = findChromeExecutable(platform, fileSystem);

  try {
    return await io.Process.start(chromePath, [...chromeArgs, debugUrl]);
  } on Exception catch (e) {
    throw Exception(
      'Could not launch Chrome at $chromePath: $e. Please ensure Chrome is installed.',
    );
  }
}

/// Cleans up test resources (Chrome process and stdout subscription).
Future<void> _cleanupResources(
  io.Process? chromeProcess,
  StreamSubscription<String> subscription,
) async {
  if (chromeProcess != null) {
    try {
      chromeProcess.kill();
      await chromeProcess.exitCode;
      debugPrint('Chrome process cleaned up');
    } on Exception catch (e) {
      debugPrint('Warning: Failed to clean up Chrome process: $e');
    }
  }
  await subscription.cancel();
}

// Helper to run flutter with web-server device using WebSocket connection.
Future<void> runFlutterWithWebServerDevice(
  FlutterRunTestDriver flutter, {
  bool verbose = false,
  bool withDebugger = true, // Enable debugger by default for WebSocket connection
  bool startPaused = false, // Don't start paused for this test
  List<String> additionalCommandArgs = const <String>[],
}) => flutter.run(
  verbose: verbose,
  withDebugger: withDebugger, // Enable debugger to establish WebSocket connection
  startPaused: startPaused, // Let the app start normally after debugger connects
  device: WebServerDevice.kWebServerDeviceId,
  additionalCommandArgs: additionalCommandArgs,
);
