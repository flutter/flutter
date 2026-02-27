// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_device.dart' show WebServerDevice;

import '../../src/common.dart';
import '../test_driver.dart';
import '../test_utils.dart';
import '../transition_test_utils.dart';

/// Configuration for WebSocket DWDS tests.
class WebSocketDwdsTestConfig {
  const WebSocketDwdsTestConfig({
    this.debugUrlTimeout = const Duration(seconds: 20),
    this.appStartTimeout = const Duration(seconds: 15),
  });

  final Duration debugUrlTimeout;
  final Duration appStartTimeout;
}

/// Result of setting up a WebSocket DWDS connection.
class WebSocketDwdsTestSetup {
  const WebSocketDwdsTestSetup({
    required this.stdout,
    required this.chromeProcess,
    required this.subscription,
  });

  final StringBuffer stdout;
  final io.Process chromeProcess;
  final StreamSubscription<String> subscription;
}

/// Common utilities for WebSocket DWDS tests.
class WebSocketDwdsTestUtils {
  /// Sets up WebSocket DWDS connection with headless Chrome.
  ///
  /// This method handles the complete setup flow:
  /// 1. Start Flutter app with web-server device
  /// 2. Wait for DWDS debug URL
  /// 3. Launch headless Chrome to connect to DWDS
  /// 4. Wait for app startup after Chrome connection
  static Future<WebSocketDwdsTestSetup> setupWebSocketConnection(
    FlutterRunTestDriver flutter, {
    required List<String> additionalCommandArgs,
    WebSocketDwdsTestConfig config = const WebSocketDwdsTestConfig(),
  }) async {
    debugPrint('Starting WebSocket DWDS connection setup...');

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
      // Start Flutter app with web-server device (will wait for debug connection)
      debugPrint('Starting Flutter app with web-server device...');
      final Future<void> appStartFuture = runFlutterWithWebServerDevice(
        flutter,
        additionalCommandArgs: [...additionalCommandArgs, '--no-web-resources-cdn'],
      );

      // Wait for DWDS debug URL to be available
      debugPrint('Waiting for DWDS debug service URL...');
      final String debugUrl = await sawDebugUrl.future.timeout(
        config.debugUrlTimeout,
        onTimeout: () {
          throw Exception('DWDS debug URL not found - app may not have started correctly');
        },
      );
      debugPrint('✓ DWDS debug service available at: $debugUrl');

      // Launch headless Chrome to connect to DWDS
      debugPrint('Launching headless Chrome to connect to DWDS...');
      chromeProcess = await launchHeadlessChrome(debugUrl);
      debugPrint('✓ Headless Chrome launched and connecting to DWDS');

      // Wait for app to start (Chrome connection established)
      debugPrint('Waiting for Flutter app to start after Chrome connection...');
      await appStartFuture.timeout(
        config.appStartTimeout,
        onTimeout: () {
          throw Exception('App startup did not complete after Chrome connection');
        },
      );
      debugPrint('✓ Flutter app started successfully with WebSocket connection');

      return WebSocketDwdsTestSetup(
        stdout: stdout,
        chromeProcess: chromeProcess,
        subscription: subscription,
      );
    } catch (e) {
      // Clean up on error
      await subscription.cancel();
      if (chromeProcess != null) {
        chromeProcess.kill();
        await chromeProcess.exitCode;
      }
      rethrow;
    }
  }

  /// Verifies WebSocket DWDS infrastructure is being used.
  static void verifyWebSocketInfrastructure(String output) {
    expect(
      output,
      contains('Waiting for connection from Dart debug extension'),
      reason: 'Should wait for debug connection (WebSocket infrastructure)',
    );
    expect(output, contains('web-server'), reason: 'Should use web-server device');
  }
}

/// Launches headless Chrome with the given debug URL.
/// Uses findChromeExecutable to locate Chrome on the current platform.
Future<io.Process> launchHeadlessChrome(String debugUrl) async {
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
Future<void> cleanupWebSocketTestResources(
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

/// Helper to run flutter with web-server device using WebSocket connection.
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
