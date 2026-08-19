// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph getBoxesForRange 1 Infinity line', () {
    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation.';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final List<ui.TextBox> rects1 = paragraph.getBoxesForRange(
      0,
      text.length,
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.max,
    );
    expect(rects1.length, 1);
    expect(rects1.first.toRect().height >= paragraph.height, true);
    expect(rects1.first.toRect().width, paragraph.longestLine);

    final List<ui.TextBox> rects2 = paragraph.getBoxesForRange(
      0,
      text.length,
      // boxHeightStyle: ui.BoxHeightStyle.tight,
      // boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    expect(rects2.length, 1);
    expect(rects2.first.toRect().height >= paragraph.height, true);
    expect(rects2.first.toRect().width, paragraph.longestLine);
  });

  test('Paragraph getBoxesForRange multiple lines', () {
    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation.';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 50);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));
    expect(paragraph.numberOfLines, 4);

    {
      final List<ui.TextBox> rects = paragraph.getBoxesForRange(
        0,
        text.length,
        boxHeightStyle: ui.BoxHeightStyle.max,
        boxWidthStyle: ui.BoxWidthStyle.max,
      );
      expect(rects.length, 6);
      final double height =
          rects[0].toRect().height +
          rects[2].toRect().height +
          rects[3].toRect().height +
          rects[5].toRect().height;
      final double width01 = rects[0].toRect().width + rects[1].toRect().width;
      final double width2 = rects[2].toRect().width;
      final double width34 = rects[3].toRect().width + rects[4].toRect().width;
      final double width5 = rects[5].toRect().width;

      expect(height <= paragraph.height, true);
      expect(width01 > 500, true);
      expect(width2 > 500, true);
      expect(width34 > 500, true);
      expect(width5 < 500, true);
      expect(paragraph.longestLine < 500, true);
    }

    // TODO(jlavrova): apparently, event BoxWidthStyle.tight takes in account trailing spaces.
    {
      final List<ui.TextBox> rects = paragraph.getBoxesForRange(
        0,
        text.length,
        // boxHeightStyle: ui.BoxHeightStyle.tight,
        // boxWidthStyle: ui.BoxWidthStyle.tight,
      );
      expect(rects.length, 4);
      final double height =
          rects[0].toRect().height +
          rects[1].toRect().height +
          rects[2].toRect().height +
          rects[3].toRect().height;
      final double width1 = rects[0].toRect().width;
      final double width2 = rects[1].toRect().width;
      final double width3 = rects[2].toRect().width;
      final double width4 = rects[3].toRect().width;

      expect(height <= paragraph.height, true);
      expect(width1 < 500, true);
      expect(width2 > 500, true);
      expect(width3 < 500, true);
      expect(width4 < 500, true);
      expect(paragraph.longestLine < 500, true);
    }
  });

  test('Paragraph getBoxesForRange includeLineSpacing multiple lines', () {
    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation.';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 40);
    final heightStyle = ui.TextStyle(fontFamily: 'Roboto', fontSize: 40, height: 2.0);
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.pushStyle(heightStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));

    const EPSILON = 0.001;

    final List<ui.TextBox> rectsTop = paragraph.getBoxesForRange(
      0,
      text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingTop,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    final List<ui.TextBox> rectsBottom = paragraph.getBoxesForRange(
      0,
      text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingBottom,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    final List<ui.TextBox> rectsMiddle = paragraph.getBoxesForRange(
      0,
      text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    expect(rectsTop.length, 3);
    expect(rectsBottom.length, 3);
    expect(rectsMiddle.length, 3);

    final ui.TextBox top0 = rectsTop[0];
    final ui.TextBox top1 = rectsTop[1];
    final ui.TextBox bottom0 = rectsBottom[0];
    final ui.TextBox bottom1 = rectsBottom[1];
    final ui.TextBox middle0 = rectsMiddle[0];
    final ui.TextBox middle1 = rectsMiddle[1];

    expect((top0.top - bottom0.top).abs() < EPSILON, true);
    expect((top0.top - middle0.top).abs() < EPSILON, true);
    expect(top0.bottom < middle0.bottom, true);
    expect(middle0.bottom < bottom0.bottom, true);

    expect((top0.bottom - top1.top).abs() < EPSILON, true);
    expect((middle0.bottom - middle1.top).abs() < EPSILON, true);
    expect((bottom0.bottom - bottom1.top).abs() < EPSILON, true);
    expect(top1.bottom < middle1.bottom, true);
    expect(middle1.bottom < bottom1.bottom, true);
  });

  test('Paragraph getBoxesForRange 1 finite line', () {
    const text = 'Username';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 93));

    final List<ui.TextBox> rects1 = paragraph.getBoxesForRange(
      0,
      1,
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.max,
    );
    expect(rects1.length, 1);
    expect(rects1.first.toRect().width < paragraph.longestLine, true);
    expect(rects1.first.toRect().height >= paragraph.height, true);

    final List<ui.TextBox> rects2 = paragraph.getBoxesForRange(
      0,
      text.length,
      // boxHeightStyle: ui.BoxHeightStyle.tight,
      // boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    expect(rects2.length, 1);
    expect(rects2.first.toRect().width, paragraph.longestLine);
    expect(rects2.first.toRect().height >= paragraph.height, true);
  });

  test('getBoxesForRange returns correct positions for text selection', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Get boxes for a range
    final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 5);

    expect(boxes.isNotEmpty, true);
    for (final box in boxes) {
      print('Box: left=${box.left}, top=${box.top}, right=${box.right}, bottom=${box.bottom}');
      expect(box.left >= 0, true);
      expect(box.top <= 0, true);
      expect(box.right > box.left, true);
      expect(box.bottom > box.top, true);
    }
  });

  test('getBoxesForRange handles full text range', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, text.length);

    expect(boxes.isNotEmpty, true);
  });

  test('getBoxesForRange handles RTL text correctly', () {
    final paragraphStyle = ui.ParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      textDirection: ui.TextDirection.rtl,
    );
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('مرحبا'); // Arabic (RTL)
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));

    final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 'مرحبا'.length);

    expect(boxes.isNotEmpty, true);
    for (final box in boxes) {
      expect(box.left >= 0, true);
      expect(box.right > box.left, true);
    }
  });

  test('getBoxesForRange handles empty range', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final List<ui.TextBox> boxes = paragraph.getBoxesForRange(5, 5);

    // Empty range should return empty list or minimal box
    expect(boxes.isEmpty || boxes.every((box) => box.toRect().width == 0), true);
  });

  test('getBoxesForRange handles multiline text with strut style', () {
    final paragraphStyle = ui.ParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      strutStyle: ui.StrutStyle(fontSize: 20),
    );
    const text = 'Hello \nWorld';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final List<ui.TextBox> boxes1 = paragraph.getBoxesForRange(
      0,
      1,
      boxHeightStyle: ui.BoxHeightStyle.strut,
    );
    final List<ui.TextBox> boxes2 = paragraph.getBoxesForRange(
      text.length - 1,
      text.length,
      boxHeightStyle: ui.BoxHeightStyle.strut,
    );

    expect(boxes1.isNotEmpty && boxes1.length == 1, true);
    expect(boxes2.isNotEmpty && boxes2.length == 1, true);
    expect(boxes1.first.toRect().bottom >= boxes2.first.toRect().top, true);
  });
}
