// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:matcher/matcher.dart';
import 'package:webdriver/sync_io.dart' as sync;
import 'package:webdriver/support/async.dart';

import '../common/error.dart';
import '../common/message.dart';
import 'driver.dart';
import 'timeline.dart';
import 'web_driver_config.dart';

/// An implementation of the Flutter Driver using the WebDriver.
class WebFlutterDriver extends FlutterDriver {
  final FlutterWebConnection _connection;
  final String _browserName;
  DateTime _startTime;

  WebFlutterDriver._connect(this._connection, this._browserName);

  /// Creates a driver that uses a connection provided by the given
  /// [hostUrl].
  static Future<FlutterDriver> connectWeb({String hostUrl}) async {
    hostUrl ??= Platform.environment['VM_SERVICE_URL'];
    String browserName = Platform.environment['BROWSER_NAME'];
    Map<String, dynamic> settings = <String, dynamic> {
      'browser-name': browserName,
      'browser-dimension': Platform.environment['BROWSER_DIMENSION'],
      'headless': Platform.environment['HEADLESS']?.toLowerCase() == 'true',
      'selenium-port': Platform.environment['SELENIUM_PORT'],
    };
    final connection = await FlutterWebConnection.connect
      (hostUrl, settings);
    return WebFlutterDriver._connect(connection, browserName);
  }

  @override
  Future<Map<String, dynamic>> sendCommand(Command command) async {
    Map<String, dynamic> response;
    final Map<String, String> serialized = command.serialize();
    try {
      final dynamic data = await _connection.sendCommand('window.\$flutterDriver(\'${jsonEncode(serialized)}\')');
      response = data != null ? json.decode(data) : <String, dynamic>{};
    } catch (error, stackTrace) {
      throw DriverError('Failed to respond to $command due to remote error\n : \$flutterDriver(\'${jsonEncode(serialized)}\')',
          error,
          stackTrace
      );
    }
    if (response['isError'] == true)
      throw DriverError('Error in Flutter application: ${response['response']}');
    return response['response'];
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
  Future<List<int>> screenshot() async {
    // HACK: this artificial delay here is to deal with a race between the
    //       driver script and the GPU thread. The issue is that driver API
    //       synchronizes with the framework based on transient callbacks, which
    //       are out of sync with the GPU thread. Here's the timeline of events
    //       in ASCII art:
    //
    //       -------------------------------------------------------------------
    //       Without this delay:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize -->
    //       Gap   :              | random |
    //       Driver:                        <-- screenshot -->
    //
    //       In the diagram above, the gap is the time between the last driver
    //       action taken, such as a `tap()`, and the subsequent call to
    //       `screenshot()`. The gap is random because it is determined by the
    //       unpredictable network communication between the driver process and
    //       the application. If this gap is too short, which it typically will
    //       be, the screenshot is taken before the GPU thread is done
    //       rasterizing the frame, so the screenshot of the previous frame is
    //       taken, which is wrong.
    //
    //       -------------------------------------------------------------------
    //       With this delay, if we're lucky:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize -->
    //       Gap   :              |    2 seconds or more   |
    //       Driver:                                        <-- screenshot -->
    //
    //       The two-second gap should be long enough for the GPU thread to
    //       finish rasterizing the frame, but not longer than necessary to keep
    //       driver tests as fast a possible.
    //
    //       -------------------------------------------------------------------
    //       With this delay, if we're not lucky:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize randomly slow today -->
    //       Gap   :              |    2 seconds or more   |
    //       Driver:                                        <-- screenshot -->
    //
    //       In practice, sometimes the device gets really busy for a while and
    //       even two seconds isn't enough, which means that this is still racy
    //       and a source of flakes.
    await Future<void>.delayed(const Duration(seconds: 2));

    return _connection.screenshot();
  }

  @override
  Future<void> startTracing({
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    Duration timeout = kUnusuallyLongTimeout,
  }) async {
    if (_browserName != kChrome) {
      throw UnimplementedError();
    }

    _startTime = DateTime.now();
  }

  @override
  Future<Timeline> stopTracingAndDownloadTimeline({Duration timeout = kUnusuallyLongTimeout}) async {
    if (_browserName != kChrome) {
      throw UnimplementedError();
    }
    if (_startTime == null) {
      return null;
    }

    List<sync.LogEntry> logs = _connection.logs;
    List<Map<String, dynamic>> events = [];
    for (var entry in logs) {
      if (_startTime.isBefore(entry.timestamp)) {
        Map<String, dynamic> data = jsonDecode(entry.message)['message'];
        if (data['method'] == 'Tracing.dataCollected') {
          // 'ts' data collected from Chrome is in double format, conversion needed
          data['params']['ts'] =
              double.parse(data['params']['ts'].toString()).toInt();
          events.add(data['params']);
        }
      }
    }
    Map<String, dynamic> json = <String, dynamic>{
      'traceEvents': events,
    };
    _startTime = null;
    return Timeline.fromJson(json);
  }

  @override
  Future<Timeline> traceAction(Future<dynamic> Function() action, {
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    bool retainPriorEvents = false,
  }) async {
    if (_browserName != kChrome) {
      throw UnimplementedError();
    }
    if (!retainPriorEvents) {
      await clearTimeline();
    }
    await startTracing(streams: streams);
    await action();

    return stopTracingAndDownloadTimeline();
  }

  @override
  Future<void> clearTimeline({Duration timeout = kUnusuallyLongTimeout}) async {
    if (_browserName != kChrome) {
      throw UnimplementedError();
    }

    // Reset start time
    _startTime = null;
  }
}

/// Encapsulates connection information to an instance of a Flutter Web application.
class FlutterWebConnection {

  final sync.WebDriver _driver;

  FlutterWebConnection._(this._driver);

  /// Starts WebDriver with the given [capabilities] and
  /// establishes the connection to Flutter Web application.
  static Future<FlutterWebConnection> connect(String url, Map<String, dynamic> settings) async {
    sync.WebDriver driver = createDriver(settings);
    driver.get(url);

    // Configure WebDriver browser by setting its location and dimension.
    List<String> dimensions = settings['browser-dimension'].split(',');
    if (dimensions.length != 2) {
      throw DriverError('Invalid browser window size.');
    }
    int x = int.parse(dimensions[0]);
    int y = int.parse(dimensions[1]);
    sync.Window window = driver.window;
    await window.setLocation(Point<int>(0, 0));
    await window.setSize(Rectangle<int>(0, 0, x, y));

    // Wait until extension is installed.
    await waitFor<void>(() => driver.execute('return typeof(window.\$flutterDriver)', []),
        matcher: 'function',
        timeout: Duration(minutes: 1));
    return new FlutterWebConnection._(driver);
  }

  /// Sends command via WebDriver to Flutter web application
  Future<dynamic> sendCommand(String script) async {
    dynamic result;
    try {
      _driver.execute(script, <void>[]);
    } catch (_) {
      // In case there is an exception, do nothing
    }

    try {
      result = await waitFor<dynamic>(() => _driver.execute('return \$flutterDriverResult', <void>[]),
          matcher: isNotNull,
          timeout: Duration(seconds: 30));
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
  List<sync.LogEntry> get logs => _driver.logs.get(sync.LogType.performance);

  /// Takes screenshot via WebDriver.
  List<int> screenshot()  => _driver.captureScreenshotAsList();

  /// Closes the WebDriver.
  Future close() async {
    _driver.quit();
  }
}

