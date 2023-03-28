// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'src/scenarios.dart';

void main() {
  // TODO(goderbauer): Create a window if embedder doesn't provide an implicit
  //   view to draw into once we have a windowing API and set the window's
  //   FlutterView to the _view property.
  assert(PlatformDispatcher.instance.implicitView != null);
  PlatformDispatcher.instance
    ..onPlatformMessage = _handlePlatformMessage
    ..onBeginFrame = _onBeginFrame
    ..onDrawFrame = _onDrawFrame
    ..onMetricsChanged = _onMetricsChanged
    ..onPointerDataPacket = _onPointerDataPacket
    ..scheduleFrame();

  final ByteData data = ByteData(1);
  data.setUint8(0, 1);
  PlatformDispatcher.instance.sendPlatformMessage('waiting_for_status', data, null);
}

/// The FlutterView into which the [Scenario]s will be rendered.
FlutterView get _view => PlatformDispatcher.instance.implicitView!;

void _handleDriverMessage(Map<String, dynamic> call) {
  final String? methodName = call['method'] as String?;
  switch (methodName) {
    case 'set_scenario':
      assert(call['args'] != null);
      loadScenario(call['args'] as Map<String, dynamic>, _view);
    default:
      throw 'Unimplemented method: $methodName.';
  }
}

Future<void> _handlePlatformMessage(
    String name, ByteData? data, PlatformMessageResponseCallback? callback) async {
  if (data != null) {
    print('$name = ${utf8.decode(data.buffer.asUint8List())}');
  } else {
    print(name);
  }

  switch (name) {
    case 'driver':
      _handleDriverMessage(json.decode(utf8.decode(data!.buffer.asUint8List())) as Map<String, dynamic>);
    case 'write_timeline':
      final String timelineData = await _getTimelineData();
      callback!(Uint8List.fromList(utf8.encode(timelineData)).buffer.asByteData());
    default:
      currentScenario?.onPlatformMessage(name, data, callback);
  }
}

Future<String> _getTimelineData() async {
  final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
  final Uri vmServiceTimelineUri = info.serverUri!.resolve('getVMTimeline');
  final Map<String, dynamic> vmServiceTimelineJson = await _getJson(vmServiceTimelineUri);
  final Map<String, dynamic> vmServiceResult = vmServiceTimelineJson['result'] as Map<String, dynamic>;
  return json.encode(<String, dynamic>{
    'traceEvents': <dynamic>[
      ...vmServiceResult['traceEvents'] as List<dynamic>,
    ],
  });
}

Future<Map<String, dynamic>> _getJson(Uri uri) async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(uri);
  final HttpClientResponse response = await request.close();
  if (response.statusCode > 299) {
    return <String, dynamic>{};
  }
  final String data = await utf8.decodeStream(response);
  return json.decode(data) as Map<String, dynamic>;
}

void _onBeginFrame(Duration duration) {
  // Render an empty frame to signal first frame in the platform side.
  if (currentScenario == null) {
    final SceneBuilder builder = SceneBuilder();
    final Scene scene = builder.build();
    _view.render(scene);
    scene.dispose();
    return;
  }
  currentScenario!.onBeginFrame(duration);
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
