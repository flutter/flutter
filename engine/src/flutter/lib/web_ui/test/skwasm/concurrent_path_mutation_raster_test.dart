// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import '../common/rendering.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const int _maxFrames = 10;
const int _pathsPerFrame = 50;

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  ui.Picture recordPicture(int frame) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 500, 500));
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);

    for (var i = 0; i < _pathsPerFrame; i++) {
      final path = ui.Path();
      path.moveTo(0, 64.0);
      path.lineTo(250.0, 0.0);
      path.lineTo(500.0, 64.0);

      final paint = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..color = const ui.Color(0xFFFF0000)
        ..strokeWidth = 1.0;

      canvas.drawPath(path, paint);

      path.close();
      paint.style = ui.PaintingStyle.fill;
      paint.color = const ui.Color(0x20FF0000);
      canvas.drawPath(path, paint);
    }

    return recorder.endRecording();
  }

  test('concurrent path mutation and rasterization does not corrupt the heap', () async {
    for (var frame = 0; frame < _maxFrames; frame++) {
      final ui.Picture picture = recordPicture(frame);
      final sceneBuilder = ui.SceneBuilder();
      sceneBuilder.addPicture(ui.Offset.zero, picture);

      final Future<void> renderFuture = renderScene(sceneBuilder.build());
      await Future<void>.delayed(Duration.zero);

      // Mutate paths on main thread while raster thread is rendering
      recordPicture(frame + 1).dispose();

      await renderFuture;
      picture.dispose();
    }
  });
}
