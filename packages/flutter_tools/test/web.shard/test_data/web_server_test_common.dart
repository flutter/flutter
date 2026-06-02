// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:async/async.dart';
import 'package:flutter_tools/src/web/web_device.dart' show WebServerDevice;

import 'package:webdriver/async_io.dart';

import '../../integration.shard/test_driver.dart';

const debugUrlTimeout = Duration(seconds: 15);
const reloadRestartTimeout = Duration(seconds: 5);

class WebServerDeviceTestRunner {
  WebServerDeviceTestRunner(this._flutter);

  final FlutterRunTestDriver _flutter;
  WebDriver? _webDriver;
  io.Process? _chromedriverProcess;
  late StreamQueue<LogEntry> _currentBrowserLogChunk;

  /// Runs the flutter app on the 'web-server' device and returns the web server
  /// URL where the application is accessible.
  Future<String> runWebServerDevice({List<String>? additionalCommandArgs}) async {
    try {
      final Future<String> webServerOutputLine = _flutter.stdout.firstWhere(
        (String e) => e.contains('lib/main.dart is being served at http://'),
      );
      // Start Flutter app using the web-server device.
      await _flutter
          .run(
            additionalCommandArgs: additionalCommandArgs,
            device: WebServerDevice.kWebServerDeviceId,
          )
          .timeout(
            appStartTimeout,
            onTimeout: () =>
                throw Exception('Flutter run command failed to start after: $appStartTimeout'),
          );
      // Wait for web server startup message.
      final String outputLine = await webServerOutputLine.timeout(
        debugUrlTimeout,
        onTimeout: () => throw Exception('Web server URL not found after $debugUrlTimeout.'),
      );

      final debugUrlPattern = RegExp(r'lib/main.dart is being served at (http://[^\s]+)');
      final Match? match = debugUrlPattern.firstMatch(outputLine);
      return match!.group(1)!;
    } on Exception {
      await cleanup();
      rethrow;
    }
  }

  /// Launches a headless Chrome browser and navigates to [url].
  Future<void> connectWithChrome(String url) async {
    final int chromeDriverPort = await findFreePort();
    _chromedriverProcess = await io.Process.start('chromedriver', ['--port=$chromeDriverPort']);
    var attempts = 0;
    // Using a retry loop to allow chromedriver time to spin up.
    while (attempts < 10) {
      try {
        attempts++;
        _webDriver = await createDriver(
          uri: Uri.parse('http://localhost:$chromeDriverPort/'),
          desired: Capabilities.chrome
            ..addAll(<String, dynamic>{
              'goog:loggingPrefs': <String, String>{LogType.browser: 'INFO'},
              Capabilities.chromeOptions: {
                'args': ['--headless', '--disable-gpu'],
              },
            }),
        );
        break;
      } on io.SocketException {
        if (attempts >= 10) {
          _chromedriverProcess!.kill();
          await _chromedriverProcess!.exitCode;
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    _currentBrowserLogChunk = StreamQueue(_webDriver!.logs.get(LogType.browser));
    // Navigate to the application URL.
    await _webDriver!.get(url);
  }

  /// Hot reloads the running application.
  Future<void> hotReload() async {
    return _flutter.hotReload().timeout(
      reloadRestartTimeout,
      onTimeout: () => throw Exception(
        'Hot reload request '
        'timed out after $reloadRestartTimeout.',
      ),
    );
  }

  /// Hot restarts the running application.
  Future<void> hotRestart() async {
    return _flutter.hotRestart().timeout(
      reloadRestartTimeout,
      onTimeout: () => throw Exception(
        'Hot restart request '
        'timed out after $reloadRestartTimeout.',
      ),
    );
  }

  /// Returns the next browser log entry that contains contains [message] or
  /// throws an Exception if it is not found within [timeout].
  Future<String> findNextInBrowserLog(String message, Duration timeout) async {
    /// Returns the first log message that contains [message] found in the
    /// current browser log chunk or `null` if it was not found.
    Future<String?> findNextInCurrentLogChunk(String message) async {
      while (await _currentBrowserLogChunk!.hasNext) {
        final LogEntry entry = await _currentBrowserLogChunk!.next;
        final String? logMessage = entry.message;
        if (logMessage != null && logMessage.contains(message)) {
          return logMessage;
        }
      }
      return null;
    }

    /// Returns the first log message that contains [message].
    ///
    /// Requests new chunks of the browser log as needed.
    Future<String> findNext() async {
      while (true) {
        final String? logMessage = await findNextInCurrentLogChunk(message);
        if (logMessage != null) {
          return logMessage;
        }
        // The last fetched browser log stream has closed. Fetch the next chunk
        // of log entries.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        _currentBrowserLogChunk = StreamQueue(_webDriver!.logs.get(LogType.browser));
      }
    }

    return findNext().timeout(
      timeout,
      onTimeout: () {
        throw Exception('Did not find "$message" in browser console logs after $timeout.');
      },
    );
  }

  /// Attempts to the browser if it has been started.
  Future<void> quitBrowser() async {
    await _webDriver?.quit().timeout(
      quitTimeout,
      onTimeout: () => throw Exception('Browser failed to quit after $quitTimeout.'),
    );
    _webDriver = null;
  }

  Future<void> cleanup() async {
    await _webDriver?.quit();
    _chromedriverProcess?.kill();
    await _chromedriverProcess?.exitCode;
  }
}

/// Returns a port that is likely to be unused.
///
/// NOTE: Technically speaking another process could bind this port after this
/// method returns.
Future<int> findFreePort() async {
  final io.ServerSocket socket = await io.ServerSocket.bind(io.InternetAddress.loopbackIPv4, 0);
  final int port = socket.port;
  await socket.close();
  return port;
}
