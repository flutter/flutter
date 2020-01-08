// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:webdriver/sync_io.dart' as sync_io;
import 'package:webdriver/support/async.dart';

import '../common/error.dart';
import '../common/message.dart';
import 'driver.dart';
import 'timeline.dart';
import 'web_driver_config.dart';

export 'web_driver_config.dart';

/// An implementation of the Flutter Driver using the WebDriver.
///
/// Example of how to test WebFlutterDriver:
///   1. Have Selenium server (https://bit.ly/2TlkRyu) and WebDriver binary (https://chromedriver.chromium.org/downloads) downloaded and placed under the same folder
///   2. Launch WebDriver Server: java -jar selenium-server-standalone-3.141.59.jar
///   3. Launch Flutter Web application: flutter run -v -d chrome --target=test_driver/scroll_perf_web.dart
///   4. Run test script: flutter drive --target=test_driver/scroll_perf.dart -v --use-existing-app=/application address/
class WebFlutterDriver extends FlutterDriver {
  /// Creates a driver that uses a connection provided by the given
  /// [_connection] and [_browserName].
  WebFlutterDriver.connectedTo(this._connection, this._browser) :
        _startTime = DateTime.now();

  final FlutterWebConnection _connection;
  final Browser _browser;
  DateTime _startTime;

  /// Start time for tracing
  @visibleForTesting
  DateTime get startTime => _startTime;

  @override
  VMIsolate get appIsolate => throw UnsupportedError('WebFlutterDriver does not support appIsolate');

  @override
  VMServiceClient get serviceClient => throw UnsupportedError('WebFlutterDriver does not support serviceClient');

  /// Creates a driver that uses a connection provided by the given
  /// [hostUrl] which would fallback to environment variable VM_SERVICE_URL.
  /// Driver also depends on environment variables BROWSER_NAME,
  /// BROWSER_DIMENSION, HEADLESS and SELENIUM_PORT for configurations.
  static Future<FlutterDriver> connectWeb(
      {String hostUrl, Duration timeout}) async {
    hostUrl ??= Platform.environment['VM_SERVICE_URL'];
    final Browser browser = browserNameToEnum(Platform.environment['BROWSER_NAME']);
    final Map<String, dynamic> settings = <String, dynamic>{
      'browser': browser,
      'browser-dimension': Platform.environment['BROWSER_DIMENSION'],
      'headless': Platform.environment['HEADLESS']?.toLowerCase() == 'true',
      'selenium-port': Platform.environment['SELENIUM_PORT'],
    };
    final FlutterWebConnection connection = await FlutterWebConnection.connect
      (hostUrl, settings, timeout: timeout);
    return WebFlutterDriver.connectedTo(connection, browser);
  }

  @override
  Future<Map<String, dynamic>> sendCommand(Command command) async {
    Map<String, dynamic> response;
    final Map<String, String> serialized = command.serialize();
    try {
      final dynamic data = await _connection.sendCommand('window.\$flutterDriver(\'${jsonEncode(serialized)}\')', command.timeout);
      response = data != null ? json.decode(data as String) as Map<String, dynamic> : <String, dynamic>{};
    } catch (error, stackTrace) {
      throw DriverError('Failed to respond to $command due to remote error\n : \$flutterDriver(\'${jsonEncode(serialized)}\')',
          error,
          stackTrace
      );
    }
    if (response['isError'] == true)
      throw DriverError('Error in Flutter application: ${response['response']}');
    return response['response'] as Map<String, dynamic>;
  }

  @override
  Future<void> close() => _connection.close();

  @override
  Future<void> forceGC() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, Object>>> getVmFlags() async {
    throw UnimplementedError();
  }

  @override
  Future<void> waitUntilFirstFrameRasterized() async {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> screenshot() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    return _connection.screenshot();
  }

  @override
  Future<void> startTracing({
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    Duration timeout = kUnusuallyLongTimeout,
  }) async {
    _checkBrowserSupportsTimeline();
  }

  @override
  Future<Timeline> stopTracingAndDownloadTimeline({Duration timeout = kUnusuallyLongTimeout}) async {
    _checkBrowserSupportsTimeline();

    final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
    for (final sync_io.LogEntry entry in _connection.logs) {
      if (_startTime.isBefore(entry.timestamp)) {
        final Map<String, dynamic> data = jsonDecode(entry.message)['message'] as Map<String, dynamic>;
        if (data['method'] == 'Tracing.dataCollected') {
          // 'ts' data collected from Chrome is in double format, conversion needed
          try {
            data['params']['ts'] =
                double.parse(data['params']['ts'].toString()).toInt();
          } on FormatException catch (_) {
            // data is corrupted, skip
            continue;
          }
          events.add(data['params'] as Map<String, dynamic>);
        }
      }
    }
    final Map<String, dynamic> json = <String, dynamic>{
      'traceEvents': events,
    };
    return Timeline.fromJson(json);
  }

  @override
  Future<Timeline> traceAction(Future<dynamic> Function() action, {
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    bool retainPriorEvents = false,
  }) async {
    _checkBrowserSupportsTimeline();
    if (!retainPriorEvents) {
      await clearTimeline();
    }
    await startTracing(streams: streams);
    await action();

    return stopTracingAndDownloadTimeline();
  }

  @override
  Future<void> clearTimeline({Duration timeout = kUnusuallyLongTimeout}) async {
    _checkBrowserSupportsTimeline();

    // Reset start time
    _startTime = DateTime.now();
  }

  /// Checks whether browser supports Timeline related operations
  void _checkBrowserSupportsTimeline() {
    if (_browser != Browser.chrome) {
      throw UnimplementedError();
    }
  }
}

/// Encapsulates connection information to an instance of a Flutter Web application.
class FlutterWebConnection {
  FlutterWebConnection._(this._driver);

  final sync_io.WebDriver _driver;

  /// Starts WebDriver with the given [capabilities] and
  /// establishes the connection to Flutter Web application.
  static Future<FlutterWebConnection> connect(
      String url,
      Map<String, dynamic> settings,
      {Duration timeout}) async {
    // Use sync WebDriver because async version will create a 15 seconds
    // overhead when quitting.
    final sync_io.WebDriver driver = createDriver(settings);
    driver.get(url);

    // Configure WebDriver browser by setting its location and dimension.
    final List<String> dimensions = settings['browser-dimension'].split(',') as List<String>;
    if (dimensions.length != 2) {
      throw DriverError('Invalid browser window size.');
    }
    final int x = int.parse(dimensions[0]);
    final int y = int.parse(dimensions[1]);
    final sync_io.Window window = driver.window;
    window.setLocation(const math.Point<int>(0, 0));
    window.setSize(math.Rectangle<int>(0, 0, x, y));

    // Wait until extension is installed.
    await waitFor<void>(() => driver.execute('return typeof(window.\$flutterDriver)', <String>[]),
        matcher: 'function',
        timeout: timeout ?? const Duration(days: 365));
    return FlutterWebConnection._(driver);
  }

  /// Sends command via WebDriver to Flutter web application
  Future<dynamic> sendCommand(String script, Duration duration) async {
    dynamic result;
    try {
      _driver.execute(script, <void>[]);
    } catch (_) {
      // In case there is an exception, do nothing
    }

    try {
      result = await waitFor<dynamic>(() => _driver.execute('r'
          'eturn \$flutterDriverResult', <String>[]),
          matcher: isNotNull,
          timeout: duration ?? const Duration(days: 30));
    } catch (_) {
      // Returns null if exception thrown.
      return null;
    } finally {
      // Resets the result.
      _driver.execute('''
        \$flutterDriverResult = null
      ''', <void>[]);
    }
    return result;
  }

  /// Gets performance log from WebDriver.
  List<sync_io.LogEntry> get logs => _driver.logs.get(sync_io.LogType.performance);

  /// Takes screenshot via WebDriver.
  List<int> screenshot()  => _driver.captureScreenshotAsList();

  /// Closes the WebDriver.
  Future<void> close() async {
    _driver.quit();
  }
}
