// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:async/async.dart';
import 'package:flutter_tools/src/base/platform.dart' show LocalPlatform;
import 'package:flutter_tools/src/drive/web_driver_service.dart'
    show Browser, getDesiredCapabilities;
import 'package:flutter_tools/src/web/chrome.dart' show kChromeEnvironment;
import 'package:flutter_tools/src/web/web_device.dart' show WebServerDevice;
import 'package:webdriver/async_io.dart' hide Browser;

import '../../integration.shard/test_driver.dart';

const reloadRestartTimeout = Duration(seconds: 5);
const createWebDriverTimeout = Duration(seconds: 15);

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
        (String e) => e.contains('main.dart is being served at http://'),
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
        appStartTimeout,
        onTimeout: () => throw Exception('Web server URL not found after $appStartTimeout.'),
      );

      final debugUrlPattern = RegExp(r'main.dart is being served at (http://[^\s]+)');
      final Match? match = debugUrlPattern.firstMatch(outputLine);
      return match!.group(1)!;
    } on Exception {
      await cleanup();
      rethrow;
    }
  }

  /// Starts the 'chromedriver' process and returns the port number that it is
  /// listening on.
  Future<int> _startChromeDriverProcess() async {
    final int chromeDriverPort = await findFreePort();
    _chromedriverProcess = await io.Process.start('chromedriver', <String>[
      '--port=$chromeDriverPort',
    ]);
    final completer = Completer<void>();
    _chromedriverProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String line) {
            if (!completer.isCompleted &&
                line.contains(
                  'ChromeDriver was started successfully on port '
                  '$chromeDriverPort.',
                )) {
              completer.complete();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('chromedriver stdout closed without startup message'),
              );
            }
          },
        );
    _chromedriverProcess!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String line) {
            if (!completer.isCompleted) {
              completer.completeError(Exception('chromedriver stderr: $line'));
            } else {
              throw Exception('chromedriver stderr: $line');
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );
    await completer.future;
    return chromeDriverPort;
  }

  /// Creates a [WebDriver] instance using a running 'chromedriver' process on
  /// [chromeDriverPort] and navigates the browser to [url].
  Future<void> _createWebDriver(int chromeDriverPort, String url) async {
    final Future<WebDriver> driverFuture = createDriver(
      uri: Uri.parse('http://localhost:$chromeDriverPort/'),
      desired: getDesiredCapabilities(
        Browser.chrome,
        true, // headless
        chromeBinary: const LocalPlatform().environment[kChromeEnvironment],
      ),
    );
    try {
      _webDriver = await driverFuture.timeout(
        createWebDriverTimeout,
        onTimeout: () =>
            throw Exception('Failed to create web driver after $createWebDriverTimeout'),
      );
    } on io.SocketException {
      _chromedriverProcess!.kill();
      await _chromedriverProcess!.exitCode;
      rethrow;
    }
    _currentBrowserLogChunk = StreamQueue(_webDriver!.logs.get(LogType.browser));
    // Navigate to the application URL.
    await _webDriver!.get(url);
  }

  /// Launches a headless Chrome browser and navigates to [url].
  Future<void> connectWithChrome(String url) async {
    final int chromeDriverPort = await _startChromeDriverProcess();
    await _createWebDriver(chromeDriverPort, url);
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

  /// Returns the next browser log entry that contains [message] or throws an
  /// Exception if it is not found within [timeout].
  Future<String> findNextInBrowserLog(String message, Duration timeout) async {
    /// Returns the first log message that contains [message] found in the
    /// current browser log chunk or `null` if it was not found.
    Future<String?> findNextInCurrentLogChunk(String message) async {
      while (await _currentBrowserLogChunk.hasNext) {
        final LogEntry entry = await _currentBrowserLogChunk.next;
        final String? logMessage = entry.message;
        if (logMessage != null && logMessage.contains(message)) {
          return logMessage;
        }
      }
      return null;
    }

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final String? logMessage = await findNextInCurrentLogChunk(message);
      if (logMessage != null) {
        return logMessage;
      }
      // The last fetched browser log stream has closed. Fetch the next chunk
      // of log entries.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _currentBrowserLogChunk = StreamQueue(_webDriver!.logs.get(LogType.browser));
    }
    throw Exception('Did not find "$message" in browser console logs after $timeout.');
  }

  /// Attempts to quit the browser if it has been started.
  Future<void> quitBrowser() async {
    await _webDriver?.quit().timeout(
      quitTimeout,
      onTimeout: () => throw Exception('Browser failed to quit after $quitTimeout.'),
    );
    _webDriver = null;
  }

  Future<void> cleanup() async {
    try {
      await _webDriver?.quit();
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Ignore errors during cleanup to ensure chromedriver is killed.
    } finally {
      _chromedriverProcess?.kill();
      await _chromedriverProcess?.exitCode;
    }
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
