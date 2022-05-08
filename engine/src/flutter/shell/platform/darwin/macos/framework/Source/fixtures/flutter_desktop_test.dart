// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';

void signalNativeTest() native 'SignalNativeTest';

void main() {
}

/// Notifies the test of a string value.
///
/// This is used to notify the native side of the test of a string value from
/// the Dart fixture under test.
void notifyStringValue(String s) native 'NotifyStringValue';

@pragma('vm:entry-point')
void executableNameNotNull() {
  notifyStringValue(Platform.executable);
}

@pragma('vm:entry-point')
void canLogToStdout() {
  // Emit hello world message to output then signal the test.
  print('Hello logging');
  signalNativeTest();
}

@pragma('vm:entry-point')
void canCompositePlatformViews() {
  PlatformDispatcher.instance.onBeginFrame = (Duration duration) {
    SceneBuilder builder = SceneBuilder();
    builder.addPicture(Offset(1.0, 1.0), _createSimplePicture());
    builder.pushOffset(1.0, 2.0);
    builder.addPlatformView(42, width: 123.0, height: 456.0);
    builder.addPicture(Offset(1.0, 1.0), _createSimplePicture());
    builder.pop(); // offset
    PlatformDispatcher.instance.views.first.render(builder.build());
  };
  PlatformDispatcher.instance.scheduleFrame();
}

/// Returns a [Picture] of a simple black square.
Picture _createSimplePicture() {
  Paint blackPaint = Paint();
  PictureRecorder baseRecorder = PictureRecorder();
  Canvas canvas = Canvas(baseRecorder);
  canvas.drawRect(Rect.fromLTRB(0.0, 0.0, 1000.0, 1000.0), blackPaint);
  return baseRecorder.endRecording();
}

@pragma('vm:entry-point')
void nativeCallback() {
  signalNativeTest();
}
