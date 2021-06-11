// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
void main() {

}

Picture CreateSimplePicture() {
  Paint blackPaint = Paint();
  PictureRecorder baseRecorder = PictureRecorder();
  Canvas canvas = Canvas(baseRecorder);
  canvas.drawRect(Rect.fromLTRB(0.0, 0.0, 1000.0, 1000.0), blackPaint);
  return baseRecorder.endRecording();
}

@pragma('vm:entry-point')
void can_composite_platform_views() {
  PlatformDispatcher.instance.onBeginFrame = (Duration duration) {
    SceneBuilder builder = SceneBuilder();
    builder.addPicture(Offset(1.0, 1.0), CreateSimplePicture());
    builder.pushOffset(1.0, 2.0);
    builder.addPlatformView(42, width: 123.0, height: 456.0);
    builder.addPicture(Offset(1.0, 1.0), CreateSimplePicture());
    builder.pop(); // offset
    PlatformDispatcher.instance.views.first.render(builder.build());
  };
  PlatformDispatcher.instance.scheduleFrame();
}

void signalNativeTest() native 'SignalNativeTest';

@pragma('vm:entry-point')
void native_callback() {
  signalNativeTest();
}
