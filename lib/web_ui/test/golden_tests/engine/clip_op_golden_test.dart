// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';
import 'screenshot.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
  });

  /// Regression test for https://github.com/flutter/flutter/issues/64734.
  test('Clips using difference', () async {
    final Rect region = const Rect.fromLTRB(0, 0, 400, 300);
    final RecordingCanvas canvas = RecordingCanvas(region);
    final Rect titleRect = Rect.fromLTWH(20, 0, 50, 20);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xff000000)
      ..strokeWidth = 1;
    canvas.save();
    try {
      final Rect borderRect = Rect.fromLTRB(0, 10, region.width, region.height);
      canvas.clipRect(titleRect, ClipOp.difference);
      canvas.drawRect(borderRect, paint);
    } finally {
      canvas.restore();
    }
    canvas..drawRect(titleRect, paint);
    await canvasScreenshot(canvas, 'clip_op_difference',
        region: const Rect.fromLTRB(0, 0, 420, 360));
  });
}
