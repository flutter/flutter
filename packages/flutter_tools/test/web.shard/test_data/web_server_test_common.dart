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
import 'package:test/test.dart' show printOnFailure;
import 'package:webdriver/async_io.dart' hide Browser;

import '../../integration.shard/test_driver.dart';

const reloadRestartTimeout = Duration(seconds: 30);
const createWebDriverTimeout = Duration(seconds: 25);

class WebServerDeviceTestRunner {
  WebServerDeviceTestRunner(this._flutter);

  final FlutterRunTestDriver _flutter;
  WebDriver? _webDriver;
  io.Process? _chromeDriverProcess;
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
  ///
  /// `chromedriver --port=0` lets the OS pick a port for its first bind and
  /// then binds the same port on the other loopback address (`[::1]` then
  /// `127.0.0.1` on Linux and Windows; the reverse on macOS) without
  /// checking that it is free there (see `RunServer` in Chromium's
  /// `chrome/test/chromedriver/server/chromedriver_server.cc`). When another
  /// process already holds that port, chromedriver prints
  /// `IPv4 port not available. Exiting...` (or `IPv6 ...` on macOS) and exits.
  /// Each new attempt gets a fresh OS-assigned port.
  Future<int> _startChromeDriverProcess() async {
    // TODO(mdebbar): Remove the retry once https://issues.chromium.org/issues/582923020 is fixed.
    const maxAttempts = 3;
    for (var attempt = 1; ; attempt++) {
      try {
        return await _startChromeDriverProcessOnce();
      } on _ChromeDriverPortInUseException {
        await _chromeDriverProcess?.exitCode;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        printOnFailure('chromedriver could not bind its port (attempt $attempt), retrying.');
      }
    }
  }

  Future<int> _startChromeDriverProcessOnce() async {
    _chromeDriverProcess = await io.Process.start('chromedriver', <String>['--port=0']);
    final completer = Completer<int>();
    final portPattern = RegExp(r'started successfully on port (\d+)');
    var portInUse = false;
    _chromeDriverProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String line) {
            printOnFailure('chromedriver stdout: $line');
            if (line.contains('port not available')) {
              portInUse = true;
            }
            final Match? match = portPattern.firstMatch(line);
            if (!completer.isCompleted && match != null) {
              completer.complete(int.parse(match.group(1)!));
            }
          },
          onError: (dynamic error, StackTrace stack) {
            final message =
                'chromedriver stdout error:\n'
                '$error\n'
                '$stack';
            if (!completer.isCompleted) {
              completer.completeError(Exception(message));
            } else {
              throw Exception(message);
            }
          },
          onDone: () {
            if (completer.isCompleted) {
              return;
            }
            if (portInUse) {
              completer.completeError(const _ChromeDriverPortInUseException());
            } else {
              completer.completeError(
                'chromedriver stdout closed before finding the expected startup message.',
              );
            }
          },
        );
    _chromeDriverProcess!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      // Surface errors that appear on this process if the test fails for some reason.
      printOnFailure('chromedriver stderr: $line');
    });
    return completer.future;
  }

  /// Creates a [WebDriver] instance using a running 'chromedriver' process on
  /// [chromeDriverPort].
  Future<void> _createWebDriver(int chromeDriverPort, String url) async {
    _webDriver = await createDriver(
      uri: Uri.parse('http://localhost:$chromeDriverPort/'),
      desired: getDesiredCapabilities(
        Browser.chrome,
        true, // headless
        platform: const LocalPlatform(),
        chromeBinary: const LocalPlatform().environment[kChromeEnvironment],
      ),
    );
    _currentBrowserLogChunk = StreamQueue(_webDriver!.logs.get(LogType.browser));
  }

  /// Launches a headless Chrome browser and navigates to [url].
  Future<void> connectWithChrome(String url) async {
    final int chromeDriverPort = await _startChromeDriverProcess().timeout(
      createWebDriverTimeout,
      onTimeout: () =>
          throw Exception('Failed to start "chromedriver" after: $createWebDriverTimeout'),
    );
    await _createWebDriver(chromeDriverPort, url).timeout(
      createWebDriverTimeout,
      onTimeout: () => throw Exception('Failed to create web driver after $createWebDriverTimeout'),
    );
    // Navigate to the application URL.
    await _webDriver!
        .get(url)
        .timeout(
          createWebDriverTimeout,
          onTimeout: () =>
              throw Exception('Failed to navigate to $url after $createWebDriverTimeout'),
        );
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
      final String? logMessage = await findNextInCurrentLogChunk(message).timeout(
        timeout - stopwatch.elapsed,
        onTimeout: () =>
            throw Exception('Failed to find "$message" in browser console logs after $timeout.'),
      );
      if (logMessage != null) {
        return logMessage;
      }
      // The last fetched browser log stream has closed. Fetch the next chunk
      // of log entries.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _currentBrowserLogChunk = StreamQueue(_webDriver!.logs.get(LogType.browser));
    }
    throw Exception('Failed to find "$message" in browser console logs after $timeout.');
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
      await quitBrowser();
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Ignore errors during cleanup to ensure chromedriver is killed.
    } finally {
      _chromeDriverProcess?.kill();
      await _chromeDriverProcess?.exitCode;
    }
  }
}

/// Thrown when chromedriver exits because the port it picked is already in use.
class _ChromeDriverPortInUseException implements Exception {
  const _ChromeDriverPortInUseException();

  @override
  String toString() => 'chromedriver exited because its port was not available.';
}
