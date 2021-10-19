// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' hide window;

import 'helper.dart';
import 'text_scuba.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpStableTestFonts();

  test('TextAlign.justify with multiple spans', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 400, 400);
    final BitmapCanvas canvas = BitmapCanvas(bounds, RenderStrategy());

    void build(CanvasParagraphBuilder builder) {
      builder.pushStyle(EngineTextStyle.only(color: black));
      builder.addText('Lorem ipsum dolor sit ');
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('amet, consectetur ');
      builder.pushStyle(EngineTextStyle.only(color: green));
      builder.addText('adipiscing elit, sed do eiusmod tempor incididunt ut ');
      builder.pushStyle(EngineTextStyle.only(color: red));
      builder
          .addText('labore et dolore magna aliqua. Ut enim ad minim veniam, ');
      builder.pushStyle(EngineTextStyle.only(color: lightPurple));
      builder.addText('quis nostrud exercitation ullamco ');
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('laboris nisi ut aliquip ex ea commodo consequat.');
    }

    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(
        fontFamily: 'Roboto',
        fontSize: 20.0,
        textAlign: TextAlign.justify,
      ),
      build,
    );
    paragraph.layout(constrain(250.0));
    canvas.drawParagraph(paragraph, Offset.zero);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_justify');
  });

  test('TextAlign.justify with single space and empty line', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 400, 400);
    final BitmapCanvas canvas = BitmapCanvas(bounds, RenderStrategy());

    void build(CanvasParagraphBuilder builder) {
      builder.pushStyle(bg(yellow));
      builder.pushStyle(EngineTextStyle.only(color: black));
      builder.addText('Loremipsumdolorsit');
      builder.pushStyle(EngineTextStyle.only(color: blue));
      builder.addText('amet,                consectetur\n\n');
      builder.pushStyle(EngineTextStyle.only(color: lightPurple));
      builder.addText('adipiscing elit, sed do eiusmod tempor incididunt ut ');
      builder.pushStyle(EngineTextStyle.only(color: red));
      builder.addText('labore et dolore magna aliqua.');
    }

    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(
        fontFamily: 'Roboto',
        fontSize: 20.0,
        textAlign: TextAlign.justify,
      ),
      build,
    );
    paragraph.layout(constrain(250.0));
    canvas.drawParagraph(paragraph, Offset.zero);

    return takeScreenshot(
        canvas, bounds, 'canvas_paragraph_justify_empty_line');
  });

  test('TextAlign.justify with ellipsis', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 400, 300);
    final BitmapCanvas canvas = BitmapCanvas(bounds, RenderStrategy());

    final EngineParagraphStyle paragraphStyle = EngineParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20.0,
      textAlign: TextAlign.justify,
      maxLines: 4,
      ellipsis: '...',
    );
    final CanvasParagraph paragraph = rich(
      paragraphStyle,
      (CanvasParagraphBuilder builder) {
        builder.pushStyle(EngineTextStyle.only(color: black));
        builder.addText('Lorem ipsum dolor sit ');
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('amet, consectetur ');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder
            .addText('adipiscing elit, sed do eiusmod tempor incididunt ut ');
        builder.pushStyle(EngineTextStyle.only(color: red));
        builder.addText(
            'labore et dolore magna aliqua. Ut enim ad minim veniam, ');
        builder.pushStyle(EngineTextStyle.only(color: lightPurple));
        builder.addText('quis nostrud exercitation ullamco ');
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('laboris nisi ut aliquip ex ea commodo consequat.');
      },
    );
    paragraph.layout(constrain(250));
    canvas.drawParagraph(paragraph, Offset.zero);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_justify_ellipsis');
  });

  test('TextAlign.justify with background', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 400, 400);
    final BitmapCanvas canvas = BitmapCanvas(bounds, RenderStrategy());

    final EngineParagraphStyle paragraphStyle = EngineParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20.0,
      textAlign: TextAlign.justify,
    );
    final CanvasParagraph paragraph = rich(
      paragraphStyle,
      (CanvasParagraphBuilder builder) {
        builder.pushStyle(EngineTextStyle.only(color: black));
        builder.pushStyle(bg(blue));
        builder.addText('Lorem ipsum dolor sit ');
        builder.pushStyle(bg(black));
        builder.pushStyle(EngineTextStyle.only(color: white));
        builder.addText('amet, consectetur ');
        builder.pop();
        builder.pushStyle(bg(green));
        builder
            .addText('adipiscing elit, sed do eiusmod tempor incididunt ut ');
        builder.pushStyle(bg(yellow));
        builder.addText(
            'labore et dolore magna aliqua. Ut enim ad minim veniam, ');
        builder.pushStyle(bg(red));
        builder.addText('quis nostrud exercitation ullamco ');
        builder.pushStyle(bg(green));
        builder.addText('laboris nisi ut aliquip ex ea commodo consequat.');
      },
    );
    paragraph.layout(constrain(250));
    canvas.drawParagraph(paragraph, Offset.zero);

    return takeScreenshot(
        canvas, bounds, 'canvas_paragraph_justify_background');
  });
}

EngineTextStyle bg(Color color) {
  return EngineTextStyle.only(background: Paint()..color = color);
}
