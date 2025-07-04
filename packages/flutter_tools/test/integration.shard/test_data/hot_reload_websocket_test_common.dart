// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/web_device.dart' show WebServerDevice;

import '../../src/common.dart';
import '../test_driver.dart';
import '../test_utils.dart';
import 'hot_reload_project.dart';

void testAllWebSocket({List<String> additionalCommandArgs = const <String>[]}) {
  group('WebSocket DWDS connection'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    // Define timeout constants
    const Duration hotReloadTimeout = Duration(seconds: 10);

    late Directory tempDir;
    final HotReloadProject project = HotReloadProject();
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

    testWithoutContext('hot reload with headless Chrome WebSocket connection', () async {
      print('Starting WebSocket DWDS test with headless Chrome...');

      // Set up listening for app output before starting
      final StringBuffer stdout = StringBuffer();
      final Completer<String> sawDebugUrl = Completer<String>();
      final StreamSubscription<String> subscription = flutter.stdout.listen((String e) {
        stdout.writeln(e);
        // Extract the debug connection URL
        if (e.contains('Waiting for connection from Dart debug extension at http://')) {
          final RegExp debugUrlPattern = RegExp(
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
        print('Step 1: Starting Flutter app with web-server device...');
        // Start the app but don't wait for it to complete - it won't complete until Chrome connects
        final Future<void> appStartFuture = runFlutterWithWebServerDevice(
          flutter,
          additionalCommandArgs: [...additionalCommandArgs, '--no-web-resources-cdn'],
        );

        // Step 2: Wait for DWDS debug URL to be available (this happens before app startup completes)
        print('Step 2: Waiting for DWDS debug service URL...');
        final String debugUrl = await sawDebugUrl.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw Exception('DWDS debug URL not found - app may not have started correctly');
          },
        );
        print('✓ DWDS debug service available at: $debugUrl');

        // Step 3: Launch headless Chrome to connect to DWDS
        print('Step 3: Launching headless Chrome to connect to DWDS...');
        try {
          chromeProcess = await io
              .Process.start('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
            '--headless',
            '--disable-gpu',
            '--no-sandbox',
            '--disable-extensions',
            '--disable-dev-shm-usage',
            '--remote-debugging-port=0',
            debugUrl,
          ]);
          print('✓ Headless Chrome launched and connecting to DWDS');
        } catch (e) {
          // Fallback to system Chrome
          try {
            chromeProcess = await io.Process.start('google-chrome', [
              '--headless',
              '--disable-gpu',
              '--no-sandbox',
              '--disable-extensions',
              '--disable-dev-shm-usage',
              '--remote-debugging-port=0',
              debugUrl,
            ]);
            print('✓ Headless Chrome launched (system path) and connecting to DWDS');
          } catch (e2) {
            throw Exception('Could not launch Chrome: $e2. Please ensure Chrome is installed.');
          }
        }

        // Step 4: Wait for app to start (Chrome connection established)
        print('Step 4: Waiting for Flutter app to start after Chrome connection...');

        // Now that Chrome is connecting, wait for the app startup to complete
        await appStartFuture.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('App startup did not complete after Chrome connection');
          },
        );
        print('✓ Flutter app started successfully with WebSocket connection');

        // Step 5: Test hot reload functionality
        print('Step 5: Testing hot reload with WebSocket connection...');
        await flutter.hotReload().timeout(
          hotReloadTimeout,
          onTimeout: () {
            throw Exception('Hot reload timed out');
          },
        );

        // Give some time for logs to capture
        await Future<void>.delayed(const Duration(seconds: 2));

        final String output = stdout.toString();
        expect(output, contains('Reloaded'), reason: 'Hot reload should complete successfully');
        print('✓ Hot reload completed successfully with WebSocket connection');

        // Verify the correct infrastructure was used
        expect(
          output,
          contains('Waiting for connection from Dart debug extension'),
          reason: 'Should wait for debug connection (WebSocket infrastructure)',
        );
        expect(output, contains('web-server'), reason: 'Should use web-server device');

        print('✓ WebSocket DWDS test completed successfully');
        print('✓ Verified: web-server device + DWDS + WebSocket connection + hot reload');
      } finally {
        // Cleanup
        if (chromeProcess != null) {
          try {
            chromeProcess.kill();
            await chromeProcess.exitCode;
            print('Chrome process cleaned up');
          } catch (e) {
            print('Warning: Failed to clean up Chrome process: $e');
          }
        }
        await subscription.cancel();
      }
    });
  });
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
