// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_driver/driver_extension.dart';

import 'windows.dart';

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
  // Create a completer to send the window visibility result back to the
  // integration test.
  final Completer<String> visibilityCompleter = Completer<String>();
  enableFlutterDriverExtension(handler: (String? message) async {
    if (message == 'verifyWindowVisibility') {
      return visibilityCompleter.future;
    } else if (message == 'verifyTheme') {
      final bool app = await isAppDarkModeEnabled();
      final bool system = await isSystemDarkModeEnabled();

      return (app == system)
        ? 'success'
        : 'error: app dark mode ($app) does not match system dark mode ($system)';
    }

    throw 'Unrecognized message: $message';
  });

  try {
    if (await isWindowVisible()) {
      throw 'Window should be hidden at startup';
    }

    bool firstFrame = true;
    ui.PlatformDispatcher.instance.onBeginFrame = (Duration duration) async {
      if (await isWindowVisible()) {
        if (firstFrame) {
          throw 'Window should be hidden on first frame';
        }

        if (!visibilityCompleter.isCompleted) {
          visibilityCompleter.complete('success');
        }
      }

      // Draw something to trigger the first frame callback that displays the
      // window.
      drawHelloWorld();
      firstFrame = false;
    };

    ui.PlatformDispatcher.instance.scheduleFrame();
  } catch (e) {
    visibilityCompleter.completeError(e);
    rethrow;
  }
}
