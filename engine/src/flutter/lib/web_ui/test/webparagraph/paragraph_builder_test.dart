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

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('Build paragraph without text or style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 1); // Default text style from the paragraph style
  });

  test('Build paragraph with some text but without a style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('some text');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 1);
    expect(paragraph.styledTextRanges.last.style, paragraphStyle.getTextStyle());
    expect(paragraph.styledTextRanges.last.start, 0);
    expect(paragraph.styledTextRanges.last.end, paragraph.text.length);
  });

  test('Build paragraph without any text but with a style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 1);
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
    expect(paragraph.styledTextRanges.length, 1);
    expect(paragraph.styledTextRanges.first.style, textStyle1.fillMissingFields());
    expect(paragraph.styledTextRanges.last.start, 0);
    expect(paragraph.styledTextRanges.last.end, paragraph.text.length);
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
    expect(paragraph.styledTextRanges.length, 1);
    expect(paragraph.styledTextRanges[0].style, textStyle3.fillMissingFields());
    expect(paragraph.styledTextRanges.last.start, 0);
    expect(paragraph.styledTextRanges.last.end, paragraph.text.length);
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
    expect(paragraph.styledTextRanges.length, 3);
    expect(paragraph.styledTextRanges[0].style, textStyle1.fillMissingFields());
    expect(paragraph.styledTextRanges[1].style, textStyle2.fillMissingFields());
    expect(paragraph.styledTextRanges[2].style, textStyle3.fillMissingFields());
    expect(paragraph.styledTextRanges[0].start, 0);
    expect(paragraph.styledTextRanges[0].end, 3);
    expect(paragraph.styledTextRanges[1].start, 3);
    expect(paragraph.styledTextRanges[1].end, 6);
    expect(paragraph.styledTextRanges[2].start, 6);
    expect(paragraph.styledTextRanges[2].end, 9);
  });

  test('Build paragraph with nested styles [1[2[3]]]', () {
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
    expect(paragraph.styledTextRanges.length, 3);
    expect(paragraph.styledTextRanges[0].style, textStyle1.fillMissingFields());
    expect(paragraph.styledTextRanges[1].style, textStyle2.fillMissingFields());
    expect(paragraph.styledTextRanges[2].style, textStyle3.fillMissingFields());
    expect(paragraph.styledTextRanges[0].start, 0);
    expect(paragraph.styledTextRanges[0].end, 2);
    expect(paragraph.styledTextRanges[1].start, 2);
    expect(paragraph.styledTextRanges[1].end, 4);
    expect(paragraph.styledTextRanges[2].start, 4);
    expect(paragraph.styledTextRanges[2].end, 9);
  });

  test('Build paragraph with inherited styles [1[2[3]]]', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle();
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto');
    final WebTextStyle textStyle2 = WebTextStyle(fontSize: 42);
    final WebTextStyle textStyle3 = WebTextStyle(fontStyle: FontStyle.italic);

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
    expect(paragraph.styledTextRanges.length, 3);
    expect(paragraph.styledTextRanges[0].style, textStyle1.fillMissingFields());
    expect(
      paragraph.styledTextRanges[1].style,
      WebTextStyle(fontFamily: 'Roboto', fontSize: 42).fillMissingFields(),
    );
    expect(
      paragraph.styledTextRanges[2].style,
      WebTextStyle(
        fontFamily: 'Roboto',
        fontSize: 42,
        fontStyle: FontStyle.italic,
      ).fillMissingFields().fillMissingFields(),
    );
    expect(paragraph.styledTextRanges[0].start, 0);
    expect(paragraph.styledTextRanges[0].end, 2);
    expect(paragraph.styledTextRanges[1].start, 2);
    expect(paragraph.styledTextRanges[1].end, 4);
    expect(paragraph.styledTextRanges[2].start, 4);
    expect(paragraph.styledTextRanges[2].end, 9);
  });

  test('Build paragraph with complex nested styles [1[11[111][112]]][2[21[221][222]]]', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);
    final WebTextStyle textStyle4 = WebTextStyle(fontFamily: 'Roboto', fontSize: 45);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1.fillMissingFields());
    builder.addText('[1');
    builder.pushStyle(textStyle2.fillMissingFields());
    builder.addText('[11');
    builder.pushStyle(textStyle3.fillMissingFields());
    builder.addText('[111]');
    builder.pop();
    builder.pushStyle(textStyle4.fillMissingFields());
    builder.addText('[112]]]');
    builder.pop();
    builder.pop();
    builder.pop();
    builder.pushStyle(textStyle1.fillMissingFields());
    builder.addText('[2');
    builder.pushStyle(textStyle2.fillMissingFields());
    builder.addText('[21');
    builder.pushStyle(textStyle3.fillMissingFields());
    builder.addText('[211]');
    builder.pop();
    builder.pushStyle(textStyle4.fillMissingFields());
    builder.addText('[212]]]');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '[1[11[111][112]]][2[21[211][212]]]');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 8);
  });

  final String placeholderChar = String.fromCharCode(0xFFFC);

  test('Build paragraph with a placeholder', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 10);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('textStyle1. ');
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
    builder.pushStyle(textStyle3);
    builder.addText('textStyle3. ');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.baseline,
      scale: 4.0,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'textStyle1. ${placeholderChar}textStyle3. $placeholderChar');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.styledTextRanges.length, 4);
    expect(paragraph.styledTextRanges[0].placeholder == null, true);
    expect(paragraph.styledTextRanges[1].placeholder != null, true);
    expect(paragraph.styledTextRanges[2].placeholder == null, true);
    expect(paragraph.styledTextRanges[3].placeholder != null, true);
    expect(paragraph.styledTextRanges[1].placeholder!.baseline, TextBaseline.ideographic);
    expect(paragraph.styledTextRanges[3].placeholder!.baseline, TextBaseline.alphabetic);
  });
}
