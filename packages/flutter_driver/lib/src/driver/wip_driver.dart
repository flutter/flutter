// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../common/error.dart';
import '../common/message.dart';
import 'driver.dart';
import 'timeline.dart';

///
class WipFlutterDriver extends FlutterDriver {
  WipFlutterDriver._connect(this._wipDebugger);

  static Future<FlutterDriver> connectWeb({String hostUrl}) async {
    hostUrl ??= Platform.environment['VM_SERVICE_URL'];
    final Uri uri = await _getRemoteDebuggerUrl(Uri.parse(hostUrl));
    final ChromeConnection chromeConnection = ChromeConnection(uri.host, uri.port);
    final ChromeTab chromeTab = await chromeConnection.getTab((ChromeTab chromeTab) {
      return chromeTab.url.contains('localhost');
    });
    final WipConnection wipConnection = await chromeTab.connect();
    return WipFlutterDriver._connect(wipConnection.debugger);
  }

  static Future<Uri> _getRemoteDebuggerUrl(Uri base) async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(base.resolve('/json/list'));
      final HttpClientResponse response = await request.close();
      final List<dynamic> jsonObject = await json.fuse(utf8).decoder.bind(response).single;
      return base.resolve(jsonObject.first['devtoolsFrontendUrl']);
    } catch (_) {
      // If we fail to talk to the remote debugger protocol, give up and return
      // the raw URL rather than crashing.
      return base;
    }
  }

  final WipDebugger _wipDebugger;

  @override
  Future<Map<String, dynamic>> sendCommand(Command command) async {
    Map<String, dynamic> response;
    try {
      final Map<String, String> serialized = command.serialize();
      final WipResponse wipResponse  = await _wipDebugger.sendCommand('Runtime.evaluate', params: <String, Object>{
        'expression': 'window.\$flutterDriver(\'${jsonEncode(serialized)}\')',
        'awaitPromise': true,
        'returnByValue': true,
      });
      try {
        response = json.decode(wipResponse.result['result']['value']['c'] ?? '');
      } on FormatException {
        response = <String, dynamic>{
          'isError': false,
          'response': <String, dynamic>{},
        };
      }
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to fulfill ${command.runtimeType} due to remote error',
        error,
        stackTrace,
      );
    }
    if (response['isError'] == true)
      throw DriverError('Error in Flutter application: ${response['response']}');
    return response['response'];
  }

  @override
  Future<void> clearTimeline({Duration timeout = kUnusuallyLongTimeout}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    return _wipDebugger.connection.close();
  }

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
    throw UnimplementedError();
  }

  @override
  Future<void> startTracing({
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    Duration timeout = kUnusuallyLongTimeout,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Timeline> stopTracingAndDownloadTimeline({Duration timeout = kUnusuallyLongTimeout}) async {
    throw UnimplementedError();
  }

  @override
  Future<Timeline> traceAction(Future<dynamic> Function() action, {
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    bool retainPriorEvents = false,
  }) async {
    throw UnimplementedError();
  }
}