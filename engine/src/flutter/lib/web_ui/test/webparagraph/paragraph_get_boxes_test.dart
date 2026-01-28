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
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation.',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final List<ui.TextBox> rects1 = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.max,
    );
    expect(rects1.length, 1);
    expect(rects1.first.toRect().height, paragraph.height);
    expect(rects1.first.toRect().width, paragraph.longestLine);

    final List<ui.TextBox> rects2 = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      // boxHeightStyle: ui.BoxHeightStyle.tight,
      // boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    expect(rects2.length, 1);
    expect(rects2.first.toRect().height, paragraph.height);
    expect(rects2.first.toRect().width, paragraph.longestLine);
  });

  test('Paragraph getBoxesForRange multiple lines', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 50);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));
    expect(paragraph.lines.length, 4);

    {
      final List<ui.TextBox> rects = paragraph.getBoxesForRange(
        0,
        paragraph.text.length,
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

      expect(height, paragraph.height);
      expect(width01 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(width2 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(width34 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(width5 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(
        paragraph.maxLineWidthWithTrailingSpaces,
        math.max(
          math.max(rects[0].toRect().width, rects[2].toRect().width),
          math.max(rects[3].toRect().width, rects[5].toRect().width),
        ),
      );
    }

    // TODO(jlavrova): apparently, event BoxWidthStyle.tight takes in account trailing spaces.
    {
      final List<ui.TextBox> rects = paragraph.getBoxesForRange(
        0,
        paragraph.text.length,
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

      expect(height, paragraph.height);
      expect(width1 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(width2 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(width3 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(width4 <= paragraph.maxLineWidthWithTrailingSpaces, true);
      expect(
        paragraph.maxLineWidthWithTrailingSpaces,
        math.max(
          math.max(rects[0].toRect().width, rects[1].toRect().width),
          math.max(rects[2].toRect().width, rects[3].toRect().width),
        ),
      );
    }
  });

  test('Paragraph getBoxesForRange includeLineSpacing multiple lines', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 40);
    final heightStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 40, height: 2.0);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(heightStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));

    const EPSILON = 0.001;

    final List<ui.TextBox> rectsTop = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingTop,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    final List<ui.TextBox> rectsBottom = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingBottom,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    final List<ui.TextBox> rectsMiddle = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    expect(rectsTop.length, 3);
    expect(rectsBottom.length, 3);
    expect(rectsMiddle.length, 3);

    final ui.TextBox top0 = rectsTop[0];
    final ui.TextBox top1 = rectsTop[1];
    final ui.TextBox bottom1 = rectsBottom[1];
    final ui.TextBox middle1 = rectsMiddle[1];
    expect((top0.bottom - bottom1.top).abs() < EPSILON, true);
    expect(middle1.top > bottom1.top, true);
    expect(middle1.top < top1.top, true);
  });

  test('Paragraph getBoxesForRange 1 finite line', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Username');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 93));

    final List<ui.TextBox> rects1 = paragraph.getBoxesForRange(
      0,
      1,
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.max,
    );
    expect(rects1.length, 1);
    expect(rects1.first.toRect().width < paragraph.longestLine, true);
    expect(rects1.first.toRect().height, paragraph.height);

    final List<ui.TextBox> rects2 = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      // boxHeightStyle: ui.BoxHeightStyle.tight,
      // boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    expect(rects2.length, 1);
    expect(rects2.first.toRect().width, paragraph.longestLine);
    expect(rects2.first.toRect().height, paragraph.height);
  });
}
