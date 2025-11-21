// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const double EPSILON = 0.001;

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph getPositionForOffset scales, rtl, multiline', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.rtl,
    );
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('Placeholder with scale 1.0:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.baseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.ideographic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nPlaceholder with scale 2.0:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.baseline,
      scale: 2.0,
      baselineOffset: 0.0,
      baseline: TextBaseline.ideographic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nPlaceholder with scale 3.0:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.baseline,
      scale: 3.0,
      baselineOffset: 0.0,
      baseline: TextBaseline.ideographic,
    );
    builder.pop();
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));

    final List<TextBox> placeholders = paragraph.getBoxesForPlaceholders();

    expect(placeholders.length, 3);
    expect((placeholders[0].toRect().width - 20.0).abs() < EPSILON, true);
    expect((placeholders[0].toRect().height - 20.0).abs() < EPSILON, true);
    expect(placeholders[0].direction, TextDirection.rtl);
    expect((placeholders[1].toRect().width - 40.0).abs() < EPSILON, true);
    expect((placeholders[1].toRect().height - 40.0).abs() < EPSILON, true);
    expect((placeholders[2].toRect().width - 60.0).abs() < EPSILON, true);
    expect((placeholders[2].toRect().height - 60.0).abs() < EPSILON, true);
  });

  test('Paragraph getPositionForOffset alphabetic, alignment', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.ltr,
    );
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('Alphabetic 20 on baseline:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.baseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 above baseline:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.aboveBaseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 below baseline:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.belowBaseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 middle:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.middle,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 top:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.top,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 bottom:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.bottom,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));

    final List<TextBox> placeholders = paragraph.getBoxesForPlaceholders();

    expect(placeholders.length, 6);
    expect((placeholders[0].toRect().width - 20.0).abs() < EPSILON, true);
    expect((placeholders[0].toRect().height - 20.0).abs() < EPSILON, true);
    expect(placeholders[0].direction, TextDirection.ltr);
    expect((placeholders[1].toRect().width - 20.0).abs() < EPSILON, true);
    expect((placeholders[1].toRect().height - 20.0).abs() < EPSILON, true);
    expect((placeholders[2].toRect().width - 20.0).abs() < EPSILON, true);
    expect((placeholders[2].toRect().height - 20.0).abs() < EPSILON, true);
  });
}
