// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show base64Decode;
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'package:vm_service/vm_service.dart' as vms;
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service_protos/vm_service_protos.dart';

Future<void> _testChromeFormatTrace(vms.VmService vmService) async {
  final vms.Timeline timeline = await vmService.getVMTimeline();

  int saveLayerRecordCount = 0;
  int saveLayerCount = 0;
  int flowEventCount = 0;
  for (final vms.TimelineEvent event in timeline.traceEvents!) {
    final Map<String, dynamic> json = event.json!;
    if (json['ph'] == 'B') {
      if (json['name'] == 'ui.Canvas::saveLayer (Recorded)') {
        saveLayerRecordCount += 1;
      }
      if (json['name'] == 'Canvas::saveLayer') {
        saveLayerCount += 1;
      }
    } else if (json['ph'] == 's' || json['ph'] == 't' || json['ph'] == 'f') {
      flowEventCount += 1;
    }
  }
  expect(saveLayerRecordCount, 3);
  expect(saveLayerCount, 3);
  expect(flowEventCount, 5);
}

Future<void> _testPerfettoFormatTrace(vms.VmService vmService) async {
  final vms.PerfettoTimeline response = await vmService.getPerfettoVMTimeline();
  final List<TracePacket> packets =
      Trace.fromBuffer(base64Decode(response.trace!)).packet;
  final Iterable<TrackEvent> events = packets
      .where((TracePacket packet) => packet.hasTrackEvent())
      .map((TracePacket packet) => packet.trackEvent);

  int saveLayerRecordCount = 0;
  int saveLayerCount = 0;
  int flowIdCount = 0;
  for (final TrackEvent event in events) {
    if (event.type == TrackEvent_Type.TYPE_SLICE_BEGIN) {
      if (event.name == 'ui.Canvas::saveLayer (Recorded)') {
        saveLayerRecordCount += 1;
      }
      if (event.name == 'Canvas::saveLayer') {
        saveLayerCount += 1;
      }
      flowIdCount += event.flowIds.length;
    }
  }
  expect(saveLayerRecordCount, 3);
  expect(saveLayerCount, 3);
  expect(flowIdCount, 5);
}

void main() {
  test('Canvas.saveLayer emits tracing', () async {
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();

    if (info.serverUri == null) {
      fail('This test must not be run with --disable-vm-service.');
    }

    final vms.VmService vmService = await vmServiceConnectUri(
      'ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws',
    );

    final Completer<void> completer = Completer<void>();
    PlatformDispatcher.instance.onBeginFrame = (Duration timeStamp) async {
      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xff0000ff), BlendMode.srcOut);
      canvas.drawPaint(Paint()..imageFilter = ImageFilter.blur(sigmaX: 2, sigmaY: 3));
      canvas.saveLayer(null, Paint());
      canvas.drawRect(const Rect.fromLTRB(10, 10, 20, 20), Paint());
      canvas.saveLayer(const Rect.fromLTWH(0, 0, 100, 100), Paint());
      canvas.drawRect(const Rect.fromLTRB(10, 10, 20, 20), Paint());
      canvas.drawRect(const Rect.fromLTRB(15, 15, 25, 25), Paint());
      canvas.restore();
      canvas.restore();
      final Picture picture = recorder.endRecording();

      final SceneBuilder builder = SceneBuilder();
      builder.addPicture(Offset.zero, picture);
      final Scene scene = builder.build();

      await scene.toImage(100, 100);
      scene.dispose();
      completer.complete();
    };
    PlatformDispatcher.instance.scheduleFrame();
    await completer.future;

    await _testChromeFormatTrace(vmService);
    await _testPerfettoFormatTrace(vmService);
    await vmService.dispose();
  });
}
