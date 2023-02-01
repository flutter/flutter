// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
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
    } else if (message == 'verifyStringConversion') {
      // Use a test string that contains code points that fit in both 8 and 16 bits.
      // The code points are passed a list of integers through the method channel,
      // which will use the UTF16 to UTF8 utility function to convert them to a
      // std::string, which should equate to the original expected string.
      // TODO(schectman): Remove trailing null from returned string
      const String expected = 'ABCℵ\x00';
      final Int32List codePoints = Int32List.fromList(expected.codeUnits);
      final String converted = await testStringConversion(codePoints);
      return (converted == expected)
        ? 'success'
        : 'error: conversion of UTF16 string to UTF8 failed, expected "${expected.codeUnits}" but got "${converted.codeUnits}"';
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
