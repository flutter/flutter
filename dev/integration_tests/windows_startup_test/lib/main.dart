// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void drawHelloWorld() {
  final ui.ParagraphStyle style = ui.ParagraphStyle();
  final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(style)
    ..addText('Hello world');
  final ui.Paragraph paragraph = paragraphBuilder.build();

  paragraph.layout(const ui.ParagraphConstraints(width: 100.0));

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);

  canvas.drawParagraph(paragraph, ui.Offset.zero);

  final ui.Picture picture = recorder.endRecording();
  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
    ..addPicture(ui.Offset.zero, picture)
    ..pop();

  ui.window.render(sceneBuilder.build());
}

void main() async {
  // Create a completer to send the result back to the integration test.
  final Completer<String> completer = Completer<String>();
  enableFlutterDriverExtension(handler: (String? message) => completer.future);

  try {
    const MethodChannel methodChannel =
        MethodChannel('tests.flutter.dev/windows_startup_test');

    // TODO(loic-sharma): Make the window invisible until after the first frame.
    // https://github.com/flutter/flutter/issues/41980
    final bool? visible = await methodChannel.invokeMethod('isWindowVisible');
    if (visible == null || visible == false) {
      throw 'Window should be visible at startup';
    }

    ui.PlatformDispatcher.instance.onBeginFrame = (Duration duration) async {
      final bool? visible = await methodChannel.invokeMethod('isWindowVisible');
      if (visible == null || visible == false) {
        throw 'Window should be visible';
      }

      if (!completer.isCompleted) {
        completer.complete('success');
      }

      drawHelloWorld();
    };

    ui.PlatformDispatcher.instance.scheduleFrame();
  } catch (e) {
    completer.completeError(e);
    rethrow;
  }
}
