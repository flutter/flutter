// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;

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
    paragraph = rich(EngineParagraphStyle(fontFamily: 'Roboto'), (builder) {
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
    paragraph = rich(EngineParagraphStyle(fontFamily: 'Roboto'), (builder) {
      builder.addText('Lorem ipsum dolor sit');
    })
      ..layout(constrain(90.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    // Multi-line multi-span.
    paragraph = rich(EngineParagraphStyle(fontFamily: 'Roboto'), (builder) {
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
      EngineParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.left),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.center),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.right),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_align');
  });

  test('respects alignment in DOM mode', () {
    final canvas = DomCanvas(domRenderer.createElement('flt-picture'));

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
      EngineParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.left),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.center),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto', textAlign: TextAlign.right),
      build,
    )..layout(constrain(100.0));
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(0, paragraph.height + 10);

    return takeScreenshot(canvas, bounds, 'canvas_paragraph_align_dom', maxDiffRatePercent: 0.3);
  });

  void testAlignAndTransform(EngineCanvas canvas) {
    CanvasParagraph paragraph;

    void build(CanvasParagraphBuilder builder) {
      builder.pushStyle(EngineTextStyle.only(color: white));
      builder.addText('Lorem ');
      builder.pushStyle(EngineTextStyle.only(color: red));
      builder.addText('ipsum\n');
      builder.pushStyle(EngineTextStyle.only(color: yellow));
      builder.addText('dolor');
    }

    void drawParagraphAt(Offset offset, TextAlign align) {
      paragraph = rich(
        EngineParagraphStyle(fontFamily: 'Roboto', fontSize: 20.0, textAlign: align),
        build,
      )..layout(constrain(150.0));
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(math.pi / 4);
      final Rect rect = Rect.fromLTRB(0.0, 0.0, 150.0, paragraph.height);
      canvas.drawRect(rect, SurfacePaintData()..color = black);
      canvas.drawParagraph(paragraph, Offset.zero);
      canvas.restore();
    }

    drawParagraphAt(Offset(50.0, 0.0), TextAlign.left);
    drawParagraphAt(Offset(150.0, 0.0), TextAlign.center);
    drawParagraphAt(Offset(250.0, 0.0), TextAlign.right);
  }

  test('alignment and transform', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());
    testAlignAndTransform(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_align_transform');
  });

  test('alignment and transform (DOM)', () {
    final canvas = DomCanvas(domRenderer.createElement('flt-picture'));
    testAlignAndTransform(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_align_transform_dom');
  });

  void testGiantParagraphStyles(EngineCanvas canvas) {
    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto', fontSize: 80.0),
      (CanvasParagraphBuilder builder) {
        builder.pushStyle(EngineTextStyle.only(color: yellow, fontSize: 24.0));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(color: red, fontSize: 32.0));
        builder.addText('ipsum');
      },
    )..layout(constrain(double.infinity));
    final Rect rect = Rect.fromLTRB(0.0, 0.0, paragraph.maxIntrinsicWidth, paragraph.height);
    canvas.drawRect(rect, SurfacePaintData()..color = black);
    canvas.drawParagraph(paragraph, Offset.zero);
  }

  test('giant paragraph style', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 300, 200);
    final canvas = BitmapCanvas(bounds, RenderStrategy());
    testGiantParagraphStyles(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_giant_paragraph_style');
  });

  test('giant paragraph style (DOM)', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 300, 200);
    final canvas = DomCanvas(domRenderer.createElement('flt-picture'));
    testGiantParagraphStyles(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_giant_paragraph_style_dom');
  });

  test('giant font size on the body tag (DOM)', () async {
    const Rect bounds = Rect.fromLTWH(0, 0, 600, 200);

    // Store the old font size value on the body, and set a gaint font size.
    final String oldBodyFontSize = html.document.body!.style.fontSize;
    html.document.body!.style.fontSize = '100px';

    final canvas = DomCanvas(domRenderer.createElement('flt-picture'));
    Offset offset = Offset(10.0, 10.0);

    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto'),
      (CanvasParagraphBuilder builder) {
        builder.pushStyle(EngineTextStyle.only(color: yellow, fontSize: 24.0));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(color: red, fontSize: 48.0));
        builder.addText('ipsum');
      },
    )..layout(constrain(double.infinity));
    final Rect rect = Rect.fromLTWH(offset.dx, offset.dy, paragraph.maxIntrinsicWidth, paragraph.height);
    canvas.drawRect(rect, SurfacePaintData()..color = black);
    canvas.drawParagraph(paragraph, offset);
    offset = offset.translate(paragraph.maxIntrinsicWidth, 0.0);

    // Add some extra padding between the two paragraphs.
    offset = offset.translate(20.0, 0.0);

    // Use the same height as the previous paragraph so that the 2 paragraphs
    // look nice in the screenshot.
    final double placeholderHeight = paragraph.height;
    final double placeholderWidth = paragraph.height * 2;

    final CanvasParagraph paragraph2 = rich(
      EngineParagraphStyle(),
      (CanvasParagraphBuilder builder) {
        builder.addPlaceholder(placeholderWidth, placeholderHeight, PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic);
      },
    )..layout(constrain(double.infinity));
    final Rect rect2 = Rect.fromLTWH(offset.dx, offset.dy, paragraph2.maxIntrinsicWidth, paragraph2.height);
    canvas.drawRect(rect2, SurfacePaintData()..color = black);
    canvas.drawParagraph(paragraph2, offset);
    // Draw a rect in the placeholder.
    // Leave some padding around the placeholder to make the black paragraph
    // background visible.
    final double padding = 5;
    final TextBox placeholderBox = paragraph2.getBoxesForPlaceholders().single;
    canvas.drawRect(
      placeholderBox.toRect().shift(offset).deflate(padding),
      SurfacePaintData()..color = red,
    );

    await takeScreenshot(canvas, bounds, 'canvas_paragraph_giant_body_font_size_dom');

    // Restore the old font size value.
    html.document.body!.style.fontSize = oldBodyFontSize;
  });

  test('paints spans with varying heights/baselines', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());

    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto'),
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
      EngineParagraphStyle(fontFamily: 'Roboto'),
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

  test('draws text decorations', () {
    final canvas = BitmapCanvas(bounds, RenderStrategy());
    final List<TextDecorationStyle> decorationStyles = <TextDecorationStyle>[
      TextDecorationStyle.solid,
      TextDecorationStyle.double,
      TextDecorationStyle.dotted,
      TextDecorationStyle.dashed,
      TextDecorationStyle.wavy,
    ];

    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto'),
      (builder) {
        for (TextDecorationStyle decorationStyle in decorationStyles) {
          builder.pushStyle(EngineTextStyle.only(
            color: const Color.fromRGBO(50, 50, 255, 1.0),
            decoration: TextDecoration.underline,
            decorationStyle: decorationStyle,
            decorationColor: red,
            fontFamily: 'Roboto',
            fontSize: 30,
          ));
          builder.addText('Hello World');
          builder.pop();
          builder.addText(' ');
        }
      },
    )..layout(constrain(double.infinity));

    canvas.drawParagraph(paragraph, Offset.zero);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_decoration');
  });

  void testFontFeatures(EngineCanvas canvas) {
    final String text = 'Aa Bb Dd Ee Ff Difficult';
    final FontFeature enableSmallCaps = FontFeature('smcp');
    final FontFeature disableSmallCaps = FontFeature('smcp', 0);

    final String numeric = '123.4560';
    final FontFeature enableOnum = FontFeature('onum');

    final FontFeature disableLigatures = FontFeature('liga', 0);

    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto'),
      (CanvasParagraphBuilder builder) {
        // Small Caps
        builder.pushStyle(EngineTextStyle.only(
          height: 1.5,
          color: black,
          fontSize: 32.0,
        ));
        builder.pushStyle(EngineTextStyle.only(
          color: blue,
          fontFeatures: <FontFeature>[enableSmallCaps],
        ));
        builder.addText(text);
        // Make sure disabling a font feature also works.
        builder.pushStyle(EngineTextStyle.only(
          color: black,
          fontFeatures: <FontFeature>[disableSmallCaps],
        ));
        builder.addText(' (smcp)\n');
        builder.pop(); // disableSmallCaps
        builder.pop(); // enableSmallCaps

        // No ligatures
        builder.pushStyle(EngineTextStyle.only(
          color: blue,
          fontFeatures: <FontFeature>[disableLigatures],
        ));
        builder.addText(text);
        builder.pop(); // disableLigatures
        builder.addText(' (no liga)\n');

        // No font features
        builder.pushStyle(EngineTextStyle.only(
          color: blue,
        ));
        builder.addText(text);
        builder.pop(); // color: blue
        builder.addText(' (none)\n');

        // Onum
        builder.pushStyle(EngineTextStyle.only(
          color: blue,
          fontFeatures: <FontFeature>[enableOnum],
        ));
        builder.addText(numeric);
        builder.pop(); // enableOnum
        builder.addText(' (onum)\n');

        // No font features
        builder.pushStyle(EngineTextStyle.only(
          color: blue,
        ));
        builder.addText(numeric);
        builder.pop(); // color: blue
        builder.addText(' (none)\n\n');

        // Multiple font features
        builder.addText('Combined (smcp, onum):\n');
        builder.pushStyle(EngineTextStyle.only(
          color: blue,
          fontFeatures: <FontFeature>[
            enableSmallCaps,
            enableOnum,
          ],
        ));
        builder.addText('$text - $numeric');
        builder.pop(); // enableSmallCaps, enableOnum
      },
    )..layout(constrain(double.infinity));
    canvas.drawParagraph(paragraph, Offset.zero);
  }

  test('font features', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 600, 500);
    final canvas = BitmapCanvas(bounds, RenderStrategy());
    testFontFeatures(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_font_features');
  });

  test('font features (DOM)', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 600, 500);
    final canvas = DomCanvas(domRenderer.createElement('flt-picture'));
    testFontFeatures(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_font_features_dom');
  });

  void testBackgroundStyle(EngineCanvas canvas) {
    final CanvasParagraph paragraph = rich(
      EngineParagraphStyle(fontFamily: 'Roboto', fontSize: 40.0),
      (CanvasParagraphBuilder builder) {
        builder.pushStyle(EngineTextStyle.only(color: black));
        builder.pushStyle(EngineTextStyle.only(background: Paint()..color = blue));
        builder.addText('Lor');
        builder.pushStyle(EngineTextStyle.only(background: Paint()..color = black, color: white));
        builder.addText('em ');
        builder.pop();
        builder.pushStyle(EngineTextStyle.only(background: Paint()..color = green));
        builder.addText('ipsu');
        builder.pushStyle(EngineTextStyle.only(background: Paint()..color = yellow));
        builder.addText('m\ndo');
        builder.pushStyle(EngineTextStyle.only(background: Paint()..color = red));
        builder.addText('lor sit');
      },
    );
    paragraph.layout(constrain(double.infinity));
    canvas.drawParagraph(paragraph, Offset.zero);
  }

  test('background style', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 300, 200);
    final canvas = BitmapCanvas(bounds, RenderStrategy());
    testBackgroundStyle(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_background_style');
  });

  test('background style (DOM)', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 300, 200);
    final canvas = DomCanvas(domRenderer.createElement('flt-picture'));
    testBackgroundStyle(canvas);
    return takeScreenshot(canvas, bounds, 'canvas_paragraph_background_style_dom');
  });
}
