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
import 'src/poppable_screen.dart';
import 'src/scenario.dart';

Map<String, Scenario> _scenarios = <String, Scenario>{
  'animated_color_square': AnimatedColorSquareScenario(window),
  'platform_view': PlatformViewScenario(window, 'Hello from Scenarios (Platform View)', id: 0),
  'platform_view_cliprect': PlatformViewClipRectScenario(window, 'PlatformViewClipRect', id: 1),
  'platform_view_cliprrect': PlatformViewClipRRectScenario(window, 'PlatformViewClipRRect', id: 2),
  'platform_view_clippath': PlatformViewClipPathScenario(window, 'PlatformViewClipPath', id: 3),
  'platform_view_transform': PlatformViewTransformScenario(window, 'PlatformViewTransform', id: 4),
  'platform_view_opacity': PlatformViewOpacityScenario(window, 'PlatformViewOpacity', id: 5),
  'platform_view_multiple': MultiPlatformViewScenario(window, firstId: 6, secondId: 7),
  'platform_view_multiple_background_foreground': MultiPlatformViewBackgroundForegroundScenario(window, firstId: 8, secondId: 9),
  'poppable_screen': PoppableScreenScenario(window),
  'platform_view_eaglcontext': PlatformViewGLScenario(window, 'null', id:6),
};

Scenario _currentScenario = _scenarios['animated_color_square'];

void main() {
  window
    ..onPlatformMessage = _handlePlatformMessage
    ..onBeginFrame = _onBeginFrame
    ..onDrawFrame = _onDrawFrame
    ..onMetricsChanged = _onMetricsChanged
    ..onPointerDataPacket = _onPointerDataPacket
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
  } else {
    _currentScenario?.onPlatformMessage(name, data, callback);
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

void _onPointerDataPacket(PointerDataPacket packet) {
  _currentScenario.onPointerDataPacket(packet);
}
