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

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  ui.Picture recordPicture() {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 500, 500));
    final path = ui.Path()..lineTo(100.0, 100.0);
    final paint = ui.Paint();

    canvas.drawPath(path, paint);
    path.close();
    canvas.drawPath(path, paint);

    return recorder.endRecording();
  }

  test('mutating a path after drawing does not crash during rasterization', () async {
    final sceneBuilder = ui.SceneBuilder()..addPicture(ui.Offset.zero, recordPicture());
    final Future<void> renderFuture = renderScene(sceneBuilder.build());
    await Future<void>.delayed(Duration.zero);

    for (var i = 0; i < 5; i++) {
      recordPicture().dispose();
    }

    await renderFuture;
  });
}
