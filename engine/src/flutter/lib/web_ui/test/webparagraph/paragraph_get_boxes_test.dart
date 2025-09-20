// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph getBoxesForRange 1 Infinity line', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final rects1 = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.max,
    );
    expect(rects1.length, 1);
    expect(rects1.first.toRect().height, paragraph.height);
    expect(paragraph.longestLine, paragraph.width);

    final rects2 = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      // boxHeightStyle: ui.BoxHeightStyle.tight,
      // boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    expect(rects2.length, 1);
    expect(rects2.first.toRect().width, paragraph.longestLine);
    expect(rects2.first.toRect().height, paragraph.height);
    expect(paragraph.longestLine, paragraph.width);
  });

  test('Paragraph getBoxesForRange multiple lines', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 50);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));

    {
      final rects = paragraph.getBoxesForRange(
        0,
        paragraph.text.length,
        boxHeightStyle: ui.BoxHeightStyle.max,
        boxWidthStyle: ui.BoxWidthStyle.max,
      );
      expect(rects.length, 8);
      final double height =
          rects[0].toRect().height +
          rects[2].toRect().height +
          rects[4].toRect().height +
          rects[6].toRect().height;
      final double width01 = rects[0].toRect().width + rects[1].toRect().width;
      final double width23 = rects[2].toRect().width + rects[3].toRect().width;
      final double width45 = rects[4].toRect().width + rects[5].toRect().width;
      final double width67 = rects[6].toRect().width + rects[7].toRect().width;

      expect(height, paragraph.height);
      expect(width01 <= paragraph.requiredWidth, true);
      expect(width23 <= paragraph.requiredWidth, true);
      expect(width45 <= paragraph.requiredWidth, true);
      expect(width67 <= paragraph.requiredWidth, true);
      expect(
        paragraph.longestLine,
        math.max(
          math.max(rects[0].toRect().width, rects[2].toRect().width),
          math.max(rects[4].toRect().width, rects[6].toRect().width),
        ),
      );
    }

    {
      final rects = paragraph.getBoxesForRange(
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

      expect(height, paragraph.height);
      expect(rects[0].toRect().width <= paragraph.width, true);
      expect(rects[1].toRect().width <= paragraph.width, true);
      expect(rects[2].toRect().width <= paragraph.width, true);
      expect(rects[3].toRect().width <= paragraph.width, true);
      expect(
        paragraph.longestLine,
        math.max(
          math.max(rects[0].toRect().width, rects[1].toRect().width),
          math.max(rects[2].toRect().width, rects[3].toRect().width),
        ),
      );
    }
  });

  test('Paragraph getBoxesForRange includeLineSpacing multiple lines', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 40);
    final WebTextStyle heightStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 40, height: 2.0);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(heightStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 500));

    const double EPSILON = 0.001;

    final rectsTop = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingTop,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    final rectsBottom = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingBottom,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    final rectsMiddle = paragraph.getBoxesForRange(
      0,
      paragraph.text.length,
      boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
      //boxWidthStyle: ui.BoxWidthStyle.tight,
    );

    expect(rectsTop.length, 3);
    expect(rectsBottom.length, 3);
    expect(rectsMiddle.length, 3);

    final top0 = rectsTop[0];
    final top1 = rectsTop[1];
    final bottom1 = rectsBottom[1];
    final middle1 = rectsMiddle[1];
    expect((top0.bottom - bottom1.top).abs() < EPSILON, true);
    expect(middle1.top > bottom1.top, true);
    expect(middle1.top < top1.top, true);
  });
}
