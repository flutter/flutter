// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  final DomElement sceneElement = createDomElement('flt-scene');
  if (isIosSafari) {
    // Shrink to fit on the iPhone screen.
    sceneElement.style.position = 'absolute';
    sceneElement.style.transformOrigin = '0 0 0';
    sceneElement.style.transform = 'scale(0.3)';
  }
  try {
    sceneElement.append(canvas.rootElement);
    domDocument.body!.append(sceneElement);
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

/// Fills the single placeholder in the given [paragraph] with a red rectangle.
///
/// The placeholder is filled relative to [offset].
///
/// Throws if the paragraph contains more than one placeholder.
void fillPlaceholder(
  EngineCanvas canvas,
  Offset offset,
  CanvasParagraph paragraph,
) {
  final TextBox placeholderBox = paragraph.getBoxesForPlaceholders().single;
  final SurfacePaint paint = SurfacePaint()..color = red;
  canvas.drawRect(placeholderBox.toRect().shift(offset), paint.paintData);
}


/// Fill the given [boxes] with rectangles of the given [color].
///
/// All rectangles are filled relative to [offset].
void fillBoxes(EngineCanvas canvas, Offset offset, List<TextBox> boxes, Color color) {
  for (final TextBox box in boxes) {
    final Rect rect = box.toRect().shift(offset);
    canvas.drawRect(rect, SurfacePaintData()..color = color);
  }
}
