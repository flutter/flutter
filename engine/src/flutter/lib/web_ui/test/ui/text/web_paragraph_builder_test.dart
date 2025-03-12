// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../../../lib/src/engine/web_paragraph/layout.dart';
import '../../../lib/src/engine/web_paragraph/paragraph.dart';
import '../../canvaskit/common.dart';
import '../../common/test_initialization.dart';
import '../utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('Build paragraph without text or style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 0);
  });

  test('Build paragraph with some text but without a style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('some text');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 1);
    expect(paragraph.styledTextRanges.last.textStyle, paragraphStyle.getTextStyle());
    expect(
      paragraph.styledTextRanges.last.textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
  });

  test('Build paragraph without any text but with a style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 0);
  });

  test('Build paragraph with a few styles at the and without any text', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('some text');
    builder.pushStyle(textStyle2);
    builder.pushStyle(textStyle3);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 2);
    expect(paragraph.styledTextRanges.first.textStyle, paragraphStyle.getTextStyle());
    expect(
      paragraph.styledTextRanges.first.textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
    expect(paragraph.styledTextRanges.last.textStyle, textStyle1);
    expect(
      paragraph.styledTextRanges.last.textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
  });

  test('Build paragraph with a few styles at the beginning and without some text', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.pushStyle(textStyle2);
    builder.pushStyle(textStyle3);
    builder.addText('some text');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 4);
    expect(paragraph.styledTextRanges[0].textStyle, paragraphStyle.getTextStyle());
    expect(paragraph.styledTextRanges[1].textStyle, textStyle1);
    expect(paragraph.styledTextRanges[2].textStyle, textStyle2);
    expect(paragraph.styledTextRanges[3].textStyle, textStyle3);
    expect(
      paragraph.styledTextRanges[0].textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
    expect(
      paragraph.styledTextRanges[1].textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
    expect(
      paragraph.styledTextRanges[2].textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
    expect(
      paragraph.styledTextRanges[3].textRange,
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
  });

  test('Build paragraph with a nested styles [1] [2] [3]', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1]');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addText('[2]');
    builder.pop();
    builder.pushStyle(textStyle3);
    builder.addText('[3]');
    builder.pop();
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '[1][2][3]');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 4);
    expect(paragraph.styledTextRanges[0].textStyle, paragraphStyle.getTextStyle());
    expect(paragraph.styledTextRanges[1].textStyle, textStyle1);
    expect(paragraph.styledTextRanges[2].textStyle, textStyle2);
    expect(paragraph.styledTextRanges[3].textStyle, textStyle3);
    expect(paragraph.styledTextRanges[0].textRange, ui.TextRange(start: 0, end: 9));
    expect(paragraph.styledTextRanges[1].textRange, ui.TextRange(start: 0, end: 3));
    expect(paragraph.styledTextRanges[2].textRange, ui.TextRange(start: 3, end: 6));
    expect(paragraph.styledTextRanges[3].textRange, ui.TextRange(start: 6, end: 9));
  });

  test('Build paragraph with a nested styles [1[2[3]]]', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[2');
    builder.pushStyle(textStyle3);
    builder.addText('[3]]]');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '[1[2[3]]]');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 4);
    expect(paragraph.styledTextRanges[0].textStyle, paragraphStyle.getTextStyle());
    expect(paragraph.styledTextRanges[1].textStyle, textStyle1);
    expect(paragraph.styledTextRanges[2].textStyle, textStyle2);
    expect(paragraph.styledTextRanges[3].textStyle, textStyle3);
    expect(paragraph.styledTextRanges[0].textRange, ui.TextRange(start: 0, end: 9));
    expect(paragraph.styledTextRanges[1].textRange, ui.TextRange(start: 0, end: 9));
    expect(paragraph.styledTextRanges[2].textRange, ui.TextRange(start: 2, end: 9));
    expect(paragraph.styledTextRanges[3].textRange, ui.TextRange(start: 4, end: 9));
  });
}
