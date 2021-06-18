// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'package:vm_service/vm_service.dart' as vms;
import 'package:vm_service/vm_service_io.dart';

void main() {
  test('Capture an SKP ', () async {
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();

    if (info.serverUri == null) {
      fail('This test must not be run with --disable-observatory.');
    }

    final vms.VmService vmService = await vmServiceConnectUri(
      'ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws',
    );

    final Completer<void> completer = Completer<void>();
    window.onBeginFrame = (Duration timeStamp) {
      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTRB(10, 10, 20, 20), Paint());
      final Picture picture = recorder.endRecording();

      final SceneBuilder builder = SceneBuilder();
      builder.addPicture(Offset.zero, picture);
      final Scene scene = builder.build();

      window.render(scene);
      scene.dispose();
      // window.onBeginFrame = (Duration timeStamp) {
        completer.complete();
      // };
      // window.scheduleFrame();
    };
    window.scheduleFrame();
    await completer.future;

    final vms.Response response = await vmService.callServiceExtension('_flutter.screenshotSkp');

    final String base64data = response.json!['skp'] as String;
    expect(base64data, isNotNull);
    expect(base64data, isNotEmpty);
    final Uint8List decoded = base64Decode(base64data);
    expect(decoded.sublist(0, 8), 'skiapict'.codeUnits);

    await vmService.dispose();
  });
}
