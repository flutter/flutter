// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

// Signals a waiting latch in the native test.
@pragma('vm:external-name', 'Signal')
external void signal();

// Signals a waiting latch in the native test, passing a boolean value.
@pragma('vm:external-name', 'SignalBoolValue')
external void signalBoolValue(bool value);

// Signals a waiting latch in the native test, passing a string value.
@pragma('vm:external-name', 'SignalStringValue')
external void signalStringValue(String value);

// Signals a waiting latch in the native test, which returns a value to the fixture.
@pragma('vm:external-name', 'SignalBoolReturn')
external bool signalBoolReturn();

// Notify the native test that the first frame has been scheduled.
@pragma('vm:external-name', 'NotifyFirstFrameScheduled')
external void notifyFirstFrameScheduled();

void main() {}

@pragma('vm:entry-point')
void hiPlatformChannels() {
  ui.channelBuffers.setListener('hi',
      (ByteData? data, ui.PlatformMessageResponseCallback callback) async {
    ui.PlatformDispatcher.instance.sendPlatformMessage('hi', data,
        (ByteData? reply) {
      ui.PlatformDispatcher.instance
          .sendPlatformMessage('hi', reply, (ByteData? reply) {});
    });
    callback(data);
  });
}

@pragma('vm:entry-point')
void customEntrypoint() {}

@pragma('vm:entry-point')
void verifyNativeFunction() {
  signal();
}

@pragma('vm:entry-point')
void verifyNativeFunctionWithParameters() {
  signalBoolValue(true);
}

@pragma('vm:entry-point')
void verifyNativeFunctionWithReturn() {
  bool value = signalBoolReturn();
  signalBoolValue(value);
}

@pragma('vm:entry-point')
void readPlatformExecutable() {
  signalStringValue(io.Platform.executable);
}

@pragma('vm:entry-point')
void drawHelloWorld() {
  ui.PlatformDispatcher.instance.onBeginFrame = (Duration duration) {
    final ui.ParagraphBuilder paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle())..addText('Hello world');
    final ui.Paragraph paragraph = paragraphBuilder.build();

    paragraph.layout(const ui.ParagraphConstraints(width: 800.0));

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    canvas.drawParagraph(paragraph, ui.Offset.zero);

    final ui.Picture picture = recorder.endRecording();
    final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
      ..addPicture(ui.Offset.zero, picture)
      ..pop();

    ui.window.render(sceneBuilder.build());
  };

  ui.PlatformDispatcher.instance.scheduleFrame();
  notifyFirstFrameScheduled();
}
