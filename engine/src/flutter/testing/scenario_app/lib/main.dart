// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'src/scenarios.dart';

void main() {
  assert(window.locale != null);
  window
    ..onPlatformMessage = _handlePlatformMessage
    ..onBeginFrame = _onBeginFrame
    ..onDrawFrame = _onDrawFrame
    ..onMetricsChanged = _onMetricsChanged
    ..onPointerDataPacket = _onPointerDataPacket
    ..scheduleFrame();

  final ByteData data = ByteData(1);
  data.setUint8(0, 1);
  window.sendPlatformMessage('waiting_for_status', data, null);
}

void _handleDriverMessage(Map<String, dynamic> call) {
  final String methodName = call['method'] as String;
  switch (methodName) {
    case 'set_scenario':
      assert(call['args'] != null);
      loadScenario(call['args'] as Map<String, dynamic>);
    break;
    default:
      throw 'Unimplemented method: $methodName.';
  }
}

Future<void> _handlePlatformMessage(
    String name, ByteData data, PlatformMessageResponseCallback callback) async {
  print('$name = ${utf8.decode(data.buffer.asUint8List())}');

  switch (name) {
    case 'driver':
      _handleDriverMessage(json.decode(utf8.decode(data.buffer.asUint8List())) as Map<String, dynamic>);
    break;
    case 'write_timeline':
      final String timelineData = await _getTimelineData();
      callback(Uint8List.fromList(utf8.encode(timelineData)).buffer.asByteData());
    break;
    default:
      currentScenario?.onPlatformMessage(name, data, callback);
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
  final Map<String, dynamic> cpuResult = cpuTimelineJson['result'] as Map<String, dynamic>;
  final Map<String, dynamic> vmServiceResult = vmServiceTimelineJson['result'] as Map<String, dynamic>;

  return json.encode(<String, dynamic>{
    'stackFrames': cpuResult['stackFrames'],
    'traceEvents': <dynamic>[
      ...cpuResult['traceEvents'] as List<dynamic>,
      ...vmServiceResult['traceEvents'] as List<dynamic>,
    ],
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
  return json.decode(data) as Map<String, dynamic>;
}

void _onBeginFrame(Duration duration) {
  currentScenario?.onBeginFrame(duration);

  // Render an empty frame to signal first frame in the platform side.
  if (currentScenario == null) {
    final SceneBuilder builder = SceneBuilder();
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}

void _onDrawFrame() {
  currentScenario?.onDrawFrame();
}

void _onMetricsChanged() {
  currentScenario?.onMetricsChanged();
}

void _onPointerDataPacket(PointerDataPacket packet) {
  currentScenario?.onPointerDataPacket(packet);
}
