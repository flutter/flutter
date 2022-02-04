// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'package:vm_service/vm_service.dart' as vms;
import 'package:vm_service/vm_service_io.dart';

void main() {
  test('Canvas.saveLayer emits tracing', () async {
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();

    if (info.serverUri == null) {
      fail('This test must not be run with --disable-observatory.');
    }

    final vms.VmService vmService = await vmServiceConnectUri(
      'ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws',
    );

    final Completer<void> completer = Completer<void>();
    window.onBeginFrame = (Duration timeStamp) async {
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
    window.scheduleFrame();
    await completer.future;

    final vms.Timeline timeline = await vmService.getVMTimeline();
    await vmService.dispose();

    int saveLayerRecordCount = 0;
    int saveLayerCount = 0;
    for (final vms.TimelineEvent event in timeline.traceEvents!) {
      final Map<String, dynamic> json = event.json!;
      if (json['ph'] == 'B') {
        if (json['name'] == 'ui.Canvas::saveLayer (Recorded)') {
          saveLayerRecordCount += 1;
        }
        if (json['name'] == 'Canvas::saveLayer') {
          saveLayerCount += 1;
        }
      }
    }
    expect(saveLayerRecordCount, 3);
    expect(saveLayerCount, 3);
  });
}
