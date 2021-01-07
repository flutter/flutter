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

  test('ellipsis', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    Offset offset = Offset.zero;
    CanvasParagraph paragraph;

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', ellipsis: '...'),
      (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('ipsum');
      },
    )..layout(constrain(80.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', ellipsis: '...'),
      (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem\n');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('ipsum ');
        builder.pushStyle(EngineTextStyle.only(color: red));
        builder.addText('dolor sit');
      },
    )..layout(constrain(80.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', ellipsis: '...'),
      (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem\n');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('ipsum ');
        builder.pushStyle(EngineTextStyle.only(color: red));
        builder.addText('d');
        builder.pushStyle(EngineTextStyle.only(color: black));
        builder.addText('o');
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('l');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('o');
        builder.pushStyle(EngineTextStyle.only(color: red));
        builder.addText('r');
        builder.pushStyle(EngineTextStyle.only(color: black));
        builder.addText(' ');
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('s');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('i');
        builder.pushStyle(EngineTextStyle.only(color: red));
        builder.addText('t');
      },
    )..layout(constrain(80.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      ParagraphStyle(fontFamily: 'Roboto', maxLines: 2, ellipsis: '...'),
      (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('ipsum');
        builder.pushStyle(EngineTextStyle.only(color: red));
        builder.addText('dolor');
        builder.pushStyle(EngineTextStyle.only(color: black));
        builder.addText('sit');
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('amet');
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('consectetur');
      },
    )..layout(constrain(80.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_ellipsis');
  });
}
