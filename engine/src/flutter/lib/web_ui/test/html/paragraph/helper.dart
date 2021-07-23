// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

const Color white = Color(0xFFFFFFFF);
const Color black = Color(0xFF000000);
const Color red = Color(0xFFFF0000);
const Color lightGreen = Color(0xFFDCEDC8);
const Color green = Color(0xFF00FF00);
const Color lightBlue = Color(0xFFB3E5FC);
const Color blue = Color(0xFF0000FF);
const Color yellow = Color(0xFFFFEB3B);
const Color lightPurple = Color(0xFFE1BEE7);

ParagraphConstraints constrain(double width) {
  return ParagraphConstraints(width: width);
}

CanvasParagraph plain(
  EngineParagraphStyle style,
  String text, {
  EngineTextStyle? textStyle,
}) {
  final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);
  if (textStyle != null) {
    builder.pushStyle(textStyle);
  }
  builder.addText(text);
  return builder.build();
}

CanvasParagraph rich(
  EngineParagraphStyle style,
  void Function(CanvasParagraphBuilder) callback,
) {
  final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);
  callback(builder);
  return builder.build();
}

Future<void> takeScreenshot(
  EngineCanvas canvas,
  Rect region,
  String fileName, {
  bool write = false,
  double? maxDiffRatePercent,
}) async {
  final html.Element sceneElement = html.Element.tag('flt-scene');
  try {
    sceneElement.append(canvas.rootElement);
    html.document.body!.append(sceneElement);
    await matchGoldenFile(
      '$fileName.png',
      region: region,
      maxDiffRatePercent: maxDiffRatePercent,
      write: write,
    );
  } finally {
    // The page is reused across tests, so remove the element after taking the
    // Scuba screenshot.
    sceneElement.remove();
  }
}
