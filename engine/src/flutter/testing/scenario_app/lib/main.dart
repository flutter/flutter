// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'src/animated_color_square.dart';
import 'src/platform_view.dart';
import 'src/scenario.dart';

Map<String, Scenario> _scenarios = <String, Scenario>{
  'animated_color_square': AnimatedColorSquareScenario(window),
  'text_platform_view': PlatformViewScenario(window, 'Hello from Scenarios (Platform View)'),
};

Scenario _currentScenario = _scenarios['animated_color_square'];

void main() {
  window
    ..onPlatformMessage = _handlePlatformMessage
    ..onBeginFrame = _onBeginFrame
    ..onDrawFrame = _onDrawFrame
    ..onMetricsChanged = _onMetricsChanged
    ..scheduleFrame();
  final ByteData data = ByteData(1);
  data.setUint8(0, 1);
  window.sendPlatformMessage('scenario_status', data, null);
}

Future<void> _handlePlatformMessage(
    String name, ByteData data, PlatformMessageResponseCallback callback) async {
      print(name);
      print(utf8.decode(data.buffer.asUint8List()));
  if (name == 'set_scenario' && data != null) {
    final String scenarioName = utf8.decode(data.buffer.asUint8List());
    final Scenario candidateScenario = _scenarios[scenarioName];
    if (candidateScenario != null) {
      _currentScenario = candidateScenario;
      window.scheduleFrame();
    }
    if (callback != null) {
      final ByteData data = ByteData(1);
      data.setUint8(0, candidateScenario == null ? 0 : 1);
      callback(data);
    }
  } else if (name == 'write_timeline') {
    final String timelineData = await _getTimelineData();
    callback(Uint8List.fromList(utf8.encode(timelineData)).buffer.asByteData());
  }
}

Future<String> _getTimelineData() async {
  final String isolateId = developer.Service.getIsolateID(Isolate.current);
  final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
  final Uri cpuProfileTimelineUri = info.serverUri.resolve(
    '_getCpuProfileTimeline?tags=None&isolateId=$isolateId',
  );
  final Uri vmServiceTimelineUri = info.serverUri.resolve('getVMTimeline');
  final Map<String, dynamic> cpuTimelineJson = await _getJson(cpuProfileTimelineUri);
  final Map<String, dynamic> vmServiceTimelineJson = await _getJson(vmServiceTimelineUri);
  final Map<String, dynamic> cpuResult = cpuTimelineJson['result'].cast<String, dynamic>();
  final Map<String, dynamic> vmServiceResult =
      vmServiceTimelineJson['result'].cast<String, dynamic>();

  return json.encode(<String, dynamic>{
    'stackFrames': cpuResult['stackFrames'],
    'traceEvents': <dynamic>[...cpuResult['traceEvents'], ...vmServiceResult['traceEvents']],
  });
}

Future<Map<String, dynamic>> _getJson(Uri uri) async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(uri);
  final HttpClientResponse response = await request.close();
  if (response.statusCode > 299) {
    return null;
  }
  final String data = await utf8.decodeStream(response);
  return json.decode(data);
}

void _onBeginFrame(Duration duration) {
  _currentScenario.onBeginFrame(duration);
}

void _onDrawFrame() {
  _currentScenario.onDrawFrame();
}

void _onMetricsChanged() {
  _currentScenario.onMetricsChanged();
}
