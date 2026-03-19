// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('Rasterizer resize', () {
    setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

    test('renders correctly after resizing the view', () async {
      final view = implicitView as EngineFlutterView;

      // 1. Initial size 200x200
      view.debugPhysicalSizeOverride = const ui.Size(200, 200);
      view.debugForceResize();

      Future<void> drawCenteredCircle(ui.Size size, ui.Color color) async {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawCircle(
          ui.Offset(size.width / 2, size.height / 2),
          math.min(size.width, size.height) / 4,
          ui.Paint()..color = color,
        );
        final ui.Picture picture = recorder.endRecording();
        final sb = ui.SceneBuilder();
        sb.addPicture(ui.Offset.zero, picture);
        await renderer.renderScene(sb.build(), view);
      }

      // Draw first frame at 200x200. This ensures the rasterizer is initialized
      // and has a "current" size.
      await drawCenteredCircle(const ui.Size(200, 200), const ui.Color(0xFFFF0000));

      // 2. Resize to 400x400 and draw again.
      // This tests that the second frame correctly uses the new size for
      // measurement and painting, even if it happens immediately after the resize.
      view.debugPhysicalSizeOverride = const ui.Size(400, 400);
      view.debugForceResize();

      // Draw second frame at 400x400 with a green circle.
      // If the reordering was incorrect, the circle might be centered at (100, 100)
      // instead of (200, 200), or it might be clipped.
      await drawCenteredCircle(const ui.Size(400, 400), const ui.Color(0xFF00FF00));

      await matchGoldenFile(
        'ui_resize_centered_circle.png',
        region: const ui.Rect.fromLTWH(0, 0, 400, 400),
      );
    });
  });
}
