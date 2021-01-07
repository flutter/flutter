// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide window;
import 'package:ui/src/engine.dart';

import '../scuba.dart';
import 'helper.dart';

typedef CanvasTest = FutureOr<void> Function(EngineCanvas canvas);

const Rect bounds = Rect.fromLTWH(0, 0, 800, 600);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  setUpStableTestFonts();

  test('draws paragraphs with placeholders', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    Offset offset = Offset.zero;
    for (PlaceholderAlignment placeholderAlignment in PlaceholderAlignment.values) {
      final CanvasParagraph paragraph = rich(
        ParagraphStyle(fontFamily: 'Roboto', fontSize: 14.0),
        (builder) {
          builder.pushStyle(TextStyle(color: black));
          builder.addText('Lorem ipsum');
          builder.addPlaceholder(
            80.0,
            50.0,
            placeholderAlignment,
            baselineOffset: 40.0,
            baseline: TextBaseline.alphabetic,
          );
          builder.pushStyle(TextStyle(color: blue));
          builder.addText('dolor sit amet, consecteur.');
        },
      )..layout(constrain(200.0));

      // Draw the paragraph.
      canvas.drawParagraph(paragraph, offset);

      // Then fill the placeholders.
      final TextBox placeholderBox = paragraph.getBoxesForPlaceholders().single;
      final SurfacePaint redPaint = Paint()..color = red;
      canvas.drawRect(placeholderBox.toRect().shift(offset), redPaint.paintData);

      offset = offset.translate(0.0, paragraph.height + 30.0);
    }

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_placeholders');
  });

  test('draws paragraphs with placeholders and text align', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    const List<TextAlign> aligns = <TextAlign>[
      TextAlign.left,
      TextAlign.center,
      TextAlign.right,
    ];

    Offset offset = Offset.zero;
    for (TextAlign align in aligns) {
      final CanvasParagraph paragraph = rich(
        ParagraphStyle(fontFamily: 'Roboto', fontSize: 14.0, textAlign: align),
        (builder) {
          builder.pushStyle(TextStyle(color: black));
          builder.addText('Lorem');
          builder.addPlaceholder(80.0, 50.0, PlaceholderAlignment.bottom);
          builder.pushStyle(TextStyle(color: blue));
          builder.addText('ipsum.');
        },
      )..layout(constrain(200.0));

      // Draw the paragraph.
      canvas.drawParagraph(paragraph, offset);

      // Then fill the placeholders.
      final TextBox placeholderBox = paragraph.getBoxesForPlaceholders().single;
      final SurfacePaint redPaint = Paint()..color = red;
      canvas.drawRect(placeholderBox.toRect().shift(offset), redPaint.paintData);

      offset = offset.translate(0.0, paragraph.height + 30.0);
    }

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_placeholders_align');
  });
}
