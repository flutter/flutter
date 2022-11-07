// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'scenario.dart';

/// A scenario with red on top and blue on the bottom.
class GetBitmapScenario extends Scenario {
  /// Creates the GetBitmap scenario.
  ///
  /// The [dispatcher] parameter must not be null.
  GetBitmapScenario(PlatformDispatcher dispatcher)
      : super(dispatcher);

  @override
  void onBeginFrame(Duration duration) {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, window.physicalSize.width, 300),
        Paint()..color = const Color(0xFFFF0000));
    canvas.drawRect(
        Rect.fromLTWH(0, window.physicalSize.height - 300,
            window.physicalSize.width, 300),
        Paint()..color = const Color(0xFF0000FF));
    final Picture picture = recorder.endRecording();
    final SceneBuilder builder = SceneBuilder();
    builder.addPicture(Offset.zero, picture);
    final Scene scene = builder.build();
    window.render(scene);
    picture.dispose();
    scene.dispose();
  }
}
