// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:webdriver/sync_io.dart' as sync_io;
import 'package:webdriver/support/async.dart';

import '../common/error.dart';
import '../common/message.dart';
import 'driver.dart';
import 'timeline.dart';

/// An implementation of the Flutter Driver using the WebDriver.
///
/// Example of how to test WebFlutterDriver:
///   1. Have Selenium server (https://bit.ly/2TlkRyu) and WebDriver binary (https://chromedriver.chromium.org/downloads) downloaded and placed under the same folder
///   2. Launch WebDriver Server: java -jar selenium-server-standalone-3.141.59.jar
///   3. Launch Flutter Web application: flutter run -v -d chrome --target=test_driver/scroll_perf_web.dart
///   4. Run test script: flutter drive --target=test_driver/scroll_perf_web.dart -v --use-existing-app=/application address/
class WebFlutterDriver extends FlutterDriver {
  /// Creates a driver that uses a connection provided by the given
  /// [_connection].
  WebFlutterDriver.connectedTo(this._connection) :
        _startTime = DateTime.now();

  final FlutterWebConnection _connection;
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
  /// Driver also depends on environment variables DRIVER_SESSION_ID,
  /// BROWSER_SUPPORTS_TIMELINE, DRIVER_SESSION_URI, DRIVER_SESSION_SPEC
  /// and DRIVER_SESSION_CAPABILITIES for configurations.
  static Future<FlutterDriver> connectWeb(
      {String hostUrl, Duration timeout}) async {
    hostUrl ??= Platform.environment['VM_SERVICE_URL'];
    final Map<String, dynamic> settings = <String, dynamic>{
      'support-timeline-action': Platform.environment['SUPPORT_TIMELINE_ACTION'] == 'true',
      'session-id': Platform.environment['DRIVER_SESSION_ID'],
      'session-uri': Platform.environment['DRIVER_SESSION_URI'],
      'session-spec': Platform.environment['DRIVER_SESSION_SPEC'],
      'session-capabilities': Platform.environment['DRIVER_SESSION_CAPABILITIES'],
    };
    final FlutterWebConnection connection = await FlutterWebConnection.connect
      (hostUrl, settings, timeout: timeout);
    return WebFlutterDriver.connectedTo(connection);
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
    if (_connection.supportsTimelineAction) {
      throw UnsupportedError('Timeline action is not supported by current testing browser');
    }
  }
}

/// Encapsulates connection information to an instance of a Flutter Web application.
class FlutterWebConnection {
  /// Creates a FlutterWebConnection with WebDriver
  /// and whether the WebDriver supports timeline action
  FlutterWebConnection(this._driver, this._supportsTimelineAction);

  final sync_io.WebDriver _driver;


  bool _supportsTimelineAction;
  /// Whether the connected WebDriver supports timeline action for Flutter Web Driver
  // ignore: unnecessary_getters_setters
  bool get supportsTimelineAction => _supportsTimelineAction;

  /// Setter for _supportsTimelineAction
  @visibleForTesting
  // ignore: unnecessary_getters_setters
  set supportsTimelineAction(bool value) {
    _supportsTimelineAction = value;
  }

  /// Starts WebDriver with the given [capabilities] and
  /// establishes the connection to Flutter Web application.
  static Future<FlutterWebConnection> connect(
      String url,
      Map<String, dynamic> settings,
      {Duration timeout}) async {
    // Use sync WebDriver because async version will create a 15 seconds
    // overhead when quitting.
    final sync_io.WebDriver driver = sync_io.fromExistingSession(
        settings['session-id'].toString(),
        uri: Uri.parse(settings['session-uri'].toString()),
        spec: _convertToSpec(settings['session-spec'].toString().toLowerCase()),
        capabilities: jsonDecode(settings['session-capabilities'].toString()) as Map<String, dynamic>);
    driver.get(url);

    await waitUntilExtensionInstalled(driver, timeout);
    return FlutterWebConnection(driver, settings['support-timeline-action'] as bool);
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
      result = await waitFor<dynamic>(
        () => _driver.execute(r'return $flutterDriverResult', <String>[]),
        matcher: isNotNull,
        timeout: duration ?? const Duration(days: 30),
      );
    } catch (_) {
      // Returns null if exception thrown.
      return null;
    } finally {
      // Resets the result.
      _driver.execute(r'''
        $flutterDriverResult = null
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
    _driver.quit(closeSession: false);
  }
}

/// Waits until extension is installed.
Future<void> waitUntilExtensionInstalled(sync_io.WebDriver driver, Duration timeout) async {
  await waitFor<void>(() =>
      driver.execute(r'return typeof(window.$flutterDriver)', <String>[]),
      matcher: 'function',
      timeout: timeout ?? const Duration(days: 365));
}

sync_io.WebDriverSpec _convertToSpec(String specString) {
  switch (specString.toLowerCase()) {
    case 'webdriverspec.w3c':
      return sync_io.WebDriverSpec.W3c;
    case 'webdriverspec.jsonwire':
      return sync_io.WebDriverSpec.JsonWire;
    default:
      return sync_io.WebDriverSpec.Auto;
  }
}
