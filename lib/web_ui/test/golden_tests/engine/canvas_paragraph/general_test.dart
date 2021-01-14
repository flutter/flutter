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

  test('paints spans and lines correctly', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    Offset offset = Offset.zero;
    CanvasParagraph paragraph;

    // Single-line multi-span.
    paragraph = rich(ParagraphStyle(fontFamily: 'Roboto'), (builder) {
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('Lorem ');
      builder.pushStyle(EngineTextStyle.only(
        color: green,
        background: Paint()..color = red,
      ));
      builder.addText('ipsum ');
      builder.pop();
      builder.addText('.');
    })
      ..layout(constrain(double.infinity));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    // Multi-line single-span.
    paragraph = rich(ParagraphStyle(fontFamily: 'Roboto'), (builder) {
      builder.addText('Lorem ipsum dolor sit');
    })
      ..layout(constrain(90.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    // Multi-line multi-span.
    paragraph = rich(ParagraphStyle(fontFamily: 'Roboto'), (builder) {
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('Lorem ipsum ');
      builder.pushStyle(EngineTextStyle.only(background: Paint()..color = red));
      builder.pushStyle(EngineTextStyle.only(color: green));
      builder.addText('dolor ');
      builder.pop();
      builder.addText('sit');
    })
      ..layout(constrain(90.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_general');
  });

  test('respects alignment', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    Offset offset = Offset.zero;
    CanvasParagraph paragraph;

    void build(CanvasParagraphBuilder builder) {
      builder.pushStyle(EngineTextStyle.only(color: black));
      builder.addText('Lorem ');
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('ipsum ');
      builder.pushStyle(EngineTextStyle.only(color: green));
      builder.addText('dolor ');
      builder.pushStyle(EngineTextStyle.only(color: red));
      builder.addText('sit');
    }

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.left),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.center),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.right),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_align');
  });

  test('paints spans with varying heights/baselines', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    final CanvasParagraph paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto'),
      (builder) {
        builder.pushStyle(EngineTextStyle.only(fontSize: 20.0));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(
          fontSize: 40.0,
          background: Paint()..color = green,
        ));
        builder.addText('ipsum ');
        builder.pushStyle(EngineTextStyle.only(
          fontSize: 10.0,
          color: white,
          background: Paint()..color = black,
        ));
        builder.addText('dolor ');
        builder.pushStyle(EngineTextStyle.only(fontSize: 30.0));
        builder.addText('sit ');
        builder.pop();
        builder.pop();
        builder.pushStyle(EngineTextStyle.only(
          fontSize: 20.0,
          background: Paint()..color = blue,
        ));
        builder.addText('amet');
      },
    )..layout(constrain(220.0));
    canvas.drawParagraph(paragraph, Offset.zero);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_varying_heights');
  });

  test('respects letter-spacing', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    final CanvasParagraph paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto'),
      (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(color: green, letterSpacing: 1));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(color: red, letterSpacing: 3));
        builder.addText('Lorem');
      },
    )..layout(constrain(double.infinity));
    canvas.drawParagraph(paragraph, Offset.zero);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_letter_spacing');
  });
}
