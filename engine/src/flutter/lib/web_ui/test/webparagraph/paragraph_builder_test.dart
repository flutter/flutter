// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

// We need to add a default background to all initial styles because
// it will be set automatically by the ParagraphBuilder and we need them
// to match in the tests.
final WebTextStyle defaultBackground = WebTextStyle(
  background: Paint()..color = const Color(0x00000000),
);

Future<void> testMain() async {
  test('Build paragraph for Flutter Gallery', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'GoogleSans',
      fontSize: 20.0,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    final textStyle = WebTextStyle(fontFamily: 'GoogleSans', fontSize: 20.0);
    builder.pushStyle(textStyle);
    builder.addText('Options');
    builder.pop();
    final WebParagraph paragraph = builder.build();
    expect(paragraph.spans, hasLength(1));
    expect(
      paragraph.spans.single as TextSpan,
      TextSpan(
        start: 0,
        end: 7,
        style: paragraphStyle.textStyle.mergeWith(textStyle).mergeWith(defaultBackground),
        text: 'Options',
      ),
    );
  });

  test('Build paragraph without text or style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, isEmpty); // No text => no spans.
  });

  test('Build paragraph with some text but without a style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('some ');
    builder.addText('text');
    final WebParagraph paragraph = builder.build();

    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, hasLength(1));

    final span = paragraph.spans.single as TextSpan;
    expect(span.text, 'some text');
    expect(span.style, paragraphStyle.textStyle.mergeWith(defaultBackground));
    expect(span.start, 0);
    expect(span.end, paragraph.text.length);
  });

  test('Build paragraph without any text but with a style', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, isEmpty);
  });

  test('Build paragraph with a few styles at the end without any text', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);
    final WebTextStyle textStyle4 = WebTextStyle(fontFamily: 'Roboto', fontSize: 45);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('some ');
    builder.pushStyle(textStyle2);
    builder.pop();
    builder.addText('text');
    builder.pushStyle(textStyle3);
    builder.pushStyle(textStyle4);
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, hasLength(1));

    final span = paragraph.spans.single as TextSpan;
    expect(span.text, 'some text');
    expect(span.style, paragraphStyle.textStyle.mergeWith(textStyle1).mergeWith(defaultBackground));
    expect(span.start, 0);
    expect(span.end, paragraph.text.length);
  });

  test('Build paragraph with a few styles at the beginning and without some text', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('');
    builder.pushStyle(textStyle2);
    builder.pushStyle(textStyle3);
    builder.addText('some text');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'some text');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, hasLength(1));

    final span = paragraph.spans.single as TextSpan;
    expect(span.text, 'some text');
    expect(span.style, paragraphStyle.textStyle.mergeWith(textStyle3).mergeWith(defaultBackground));
    expect(span.start, 0);
    expect(span.end, paragraph.text.length);
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
    expect(paragraph.spans, hasLength(3));

    final spans = paragraph.spans.cast<TextSpan>();
    expect(spans[0].text, '[1]');
    expect(spans[1].text, '[2]');
    expect(spans[2].text, '[3]');
    expect(
      spans[0].style,
      paragraphStyle.textStyle.mergeWith(textStyle1).mergeWith(defaultBackground),
    );
    expect(
      spans[1].style,
      paragraphStyle.textStyle.mergeWith(textStyle2).mergeWith(defaultBackground),
    );
    expect(
      spans[2].style,
      paragraphStyle.textStyle.mergeWith(textStyle3).mergeWith(defaultBackground),
    );

    expect(spans[0].start, 0);
    expect(spans[0].end, 3);
    expect(spans[1].start, 3);
    expect(spans[1].end, 6);
    expect(spans[2].start, 6);
    expect(spans[2].end, 9);
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
    expect(paragraph.spans, hasLength(3));

    final spans = paragraph.spans.cast<TextSpan>();
    expect(spans[0].text, '[1');
    expect(spans[1].text, '[2');
    expect(spans[2].text, '[3]]]');
    expect(
      spans[0].style,
      paragraphStyle.textStyle.mergeWith(textStyle1).mergeWith(defaultBackground),
    );
    expect(
      spans[1].style,
      paragraphStyle.textStyle.mergeWith(textStyle2).mergeWith(defaultBackground),
    ); // Technically it's a merge with textStyle1 too but it does not affect the result.
    expect(
      spans[2].style,
      paragraphStyle.textStyle.mergeWith(textStyle3).mergeWith(defaultBackground),
    ); // Same as above.

    expect(spans[0].start, 0);
    expect(spans[0].end, 2);
    expect(spans[1].start, 2);
    expect(spans[1].end, 4);
    expect(spans[2].start, 4);
    expect(spans[2].end, 9);
  });

  test(
    'Build paragraph with inherited styles (font name, font size, font weight, font style) [1[2[3]]]',
    () {
      final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontSize: 32);
      final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto');
      final WebTextStyle textStyle2 = WebTextStyle(fontSize: 42, fontWeight: FontWeight.bold);
      final WebTextStyle textStyle3 = WebTextStyle(
        fontSize: 52,
        fontStyle: FontStyle.italic,
        fontFamily: 'Arial',
      );

      final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
      builder.pushStyle(textStyle1);
      builder.addText('[1');
      builder.pushStyle(textStyle2);
      builder.addText('[2');
      builder.pushStyle(textStyle3);
      builder.addText('[3');
      builder.pop();
      builder.addText(']]]');
      final WebParagraph paragraph = builder.build();
      final WebTextStyle merged1 = paragraph.paragraphStyle.textStyle
          .mergeWith(textStyle1)
          .mergeWith(defaultBackground);
      final WebTextStyle merged12 = merged1.mergeWith(textStyle2);
      final WebTextStyle merged123 = merged12.mergeWith(textStyle3);

      expect(paragraph.text, '[1[2[3]]]');
      expect(paragraph.paragraphStyle, paragraphStyle);
      expect(paragraph.spans, hasLength(4));

      final spans = paragraph.spans.cast<TextSpan>();
      expect(spans[0].text, '[1');
      expect(spans[1].text, '[2');
      expect(spans[2].text, '[3');
      expect(spans[3].text, ']]]');
      expect(spans[0].style, merged1);
      expect(spans[1].style, merged12);
      expect(spans[2].style, merged123);
      expect(spans[3].style, merged12); // back to `12` since `3` was popped.

      expect(spans[0].start, 0);
      expect(spans[0].end, 2);
      expect(spans[1].start, 2);
      expect(spans[1].end, 4);
      expect(spans[2].start, 4);
      expect(spans[2].end, 6);
      expect(spans[3].start, 6);
      expect(spans[3].end, 9);
    },
  );

  test('Build paragraph with inherited styles (foreground, background) [1[2[3]]]', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 24.0);
    final WebTextStyle textStyle1 = WebTextStyle(
      foreground: Paint()..color = const Color(0xFF00FF00),
    );
    final WebTextStyle textStyle2 = WebTextStyle(
      background: Paint()..color = const Color(0xFFFF0000),
    );
    final WebTextStyle textStyle3 = WebTextStyle(
      foreground: Paint()..color = const Color(0xFF0000FF),
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[2');
    builder.pushStyle(textStyle3);
    builder.addText('[3]]]');
    final WebParagraph paragraph = builder.build();
    final WebTextStyle merged1 = paragraph.paragraphStyle.textStyle
        .mergeWith(textStyle1)
        .mergeWith(defaultBackground);
    final WebTextStyle merged12 = merged1.mergeWith(textStyle2);
    final WebTextStyle merged123 = merged12.mergeWith(textStyle3);

    expect(paragraph.text, '[1[2[3]]]');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, hasLength(3));

    final spans = paragraph.spans.cast<TextSpan>();
    expect(spans[0].text, '[1');
    expect(spans[1].text, '[2');
    expect(spans[2].text, '[3]]]');
    expect(spans[0].style, merged1);
    expect(spans[1].style, merged12);
    expect(spans[2].style, merged123);

    expect(spans[0].start, 0);
    expect(spans[0].end, 2);
    expect(spans[1].start, 2);
    expect(spans[1].end, 4);
    expect(spans[2].start, 4);
    expect(spans[2].end, 9);
  });

  test('Build paragraph with complex nested styles [1[11[111][112]]][2[21[211][212]]]', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 35);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);
    final WebTextStyle textStyle4 = WebTextStyle(fontFamily: 'Roboto', fontSize: 45);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);

    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[11');
    builder.pushStyle(textStyle3);
    builder.addText('[111]');
    builder.pop();
    builder.pushStyle(textStyle4);
    builder.addText('[112]');
    builder.addText(']]');
    builder.pop();
    builder.pop();
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('[2');
    builder.pushStyle(textStyle2);
    builder.addText('[21');
    builder.pushStyle(textStyle3);
    builder.addText('[211]');
    builder.pop();
    builder.pushStyle(textStyle4);
    builder.addText('[212]]]');
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, '[1[11[111][112]]][2[21[211][212]]]');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, hasLength(8));
  });

  test('Build paragraph with a placeholder', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle textStyle1 = WebTextStyle(fontFamily: 'Roboto', fontSize: 10);
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebTextStyle textStyle3 = WebTextStyle(fontFamily: 'Roboto', fontSize: 30);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('textStyle1.');
    builder.addText(' ');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addText('');
    builder.addPlaceholder(
      20,
      25,
      PlaceholderAlignment.baseline,
      scale: 2.0,
      baselineOffset: 10.0,
      baseline: TextBaseline.ideographic,
    );
    builder.pop();
    builder.pushStyle(textStyle3);
    builder.addText('textStyle3.');
    builder.addText(' ');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      40,
      45,
      PlaceholderAlignment.top,
      scale: 4.0,
      baselineOffset: 30.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    final WebParagraph paragraph = builder.build();

    expect(builder.placeholderCount, 2);
    expect(builder.placeholderScales, <double>[2.0, 4.0]);

    expect(paragraph.text, 'textStyle1. ${kPlaceholderChar}textStyle3. $kPlaceholderChar');
    expect(paragraph.paragraphStyle, paragraphStyle);
    expect(paragraph.spans, hasLength(4));

    final span0 = paragraph.spans[0] as TextSpan;
    final span1 = paragraph.spans[1] as PlaceholderSpan;
    final span2 = paragraph.spans[2] as TextSpan;
    final span3 = paragraph.spans[3] as PlaceholderSpan;

    expect(span0.text, 'textStyle1. ');
    expect(
      span0.style,
      paragraphStyle.textStyle.mergeWith(textStyle1).mergeWith(defaultBackground),
    );
    expect(span0.start, 0);
    expect(span0.end, 0 + 12);

    expect(span1.baseline, TextBaseline.ideographic);
    expect(span1.alignment, PlaceholderAlignment.baseline);
    expect(span1.baselineOffset, 10.0 * 2.0);
    expect(span1.width, 20 * 2.0);
    expect(span1.height, 25 * 2.0);
    expect(
      span1.style,
      paragraphStyle.textStyle.mergeWith(textStyle2).mergeWith(defaultBackground),
    );
    expect(span1.start, 12);
    expect(span1.end, 12 + 1);

    expect(span2.text, 'textStyle3. ');
    expect(
      span2.style,
      paragraphStyle.textStyle.mergeWith(textStyle3).mergeWith(defaultBackground),
    );
    expect(span2.start, 13);
    expect(span2.end, 13 + 12);

    expect(span3.baseline, TextBaseline.alphabetic);
    expect(span3.alignment, PlaceholderAlignment.top);
    expect(span3.baselineOffset, 30.0 * 4.0);
    expect(span3.width, 40 * 4.0);
    expect(span3.height, 45 * 4.0);
    expect(
      span3.style,
      paragraphStyle.textStyle.mergeWith(textStyle2).mergeWith(defaultBackground),
    );
    expect(span3.start, 25);
    expect(span3.end, 25 + 1);
  });
}
