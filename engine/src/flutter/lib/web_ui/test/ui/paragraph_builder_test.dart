// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  // The embedded FlutterTest font is only loaded with `forceTestFonts`; without it
  // `fontFamily: 'FlutterTest'` silently falls back to another font.
  setUpUnitTests(
    withImplicitView: true,
    setUpTestViewDimensions: false,
    testEnvironment: const ui_web.TestEnvironment(forceTestFonts: true),
  );

  test('Should be able to build and layout a paragraph', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    builder.addText('Hello');
    final Paragraph paragraph = builder.build();
    expect(paragraph, isNotNull);

    paragraph.layout(const ParagraphConstraints(width: 800.0));
    expect(paragraph.width, isNonZero);
    expect(paragraph.height, isNonZero);
  });

  test('the presence of foreground style should not throw', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    builder.pushStyle(TextStyle(foreground: Paint()..color = const Color(0xFFABCDEF)));
    builder.addText('hi');

    expect(() => builder.build(), returnsNormally);
  });

  test('getWordBoundary respects position affinity', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    builder.addText('hello world');

    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));

    final TextRange downstreamWordBoundary = paragraph.getWordBoundary(
      const TextPosition(offset: 5),
    );
    expect(downstreamWordBoundary, const TextRange(start: 5, end: 6));

    final TextRange upstreamWordBoundary = paragraph.getWordBoundary(
      const TextPosition(offset: 5, affinity: TextAffinity.upstream),
    );
    expect(upstreamWordBoundary, const TextRange(start: 0, end: 5));
  });

  test('getLineBoundary at the last character position gives correct results', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    builder.addText('hello world');

    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));

    final TextRange lineBoundary = paragraph.getLineBoundary(const TextPosition(offset: 11));
    expect(lineBoundary, const TextRange(start: 0, end: 11));
  });

  test('build and layout a paragraph with an empty addText', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    builder.addText('');
    final Paragraph paragraph = builder.build();
    expect(
      () => paragraph.layout(const ParagraphConstraints(width: double.infinity)),
      returnsNormally,
    );
  });

  test('kTextHeightNone unsets the height multiplier', () {
    const double fontSize = 10;
    const text = 'A';
    final builder = ParagraphBuilder(ParagraphStyle(fontSize: fontSize, height: 10));
    builder.pushStyle(TextStyle(height: kTextHeightNone));
    builder.addText(text);
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    // The height should be much smaller than fontSize * 10.
    expect(paragraph.height, lessThan(2 * fontSize));
  });

  test('kTextHeightNone ParagraphStyle', () {
    const double fontSize = 10;
    final builder = ParagraphBuilder(
      ParagraphStyle(fontSize: fontSize, height: kTextHeightNone, fontFamily: 'FlutterTest'),
    );
    builder.addText('A');
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    // The height should be much smaller than fontSize * 10.
    expect(paragraph.height, lessThan(2 * fontSize));
  });

  test('kTextHeightNone StrutStyle', () {
    const double fontSize = 10;
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontSize: 100,
        fontFamily: 'FlutterTest',
        strutStyle: StrutStyle(forceStrutHeight: true, height: kTextHeightNone, fontSize: fontSize),
      ),
    );
    builder.addText('A');
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    // The height should be much smaller than fontSize * 10.
    expect(paragraph.height, lessThan(2 * fontSize));
  });

  test('StrutStyle applies to empty paragraph', () {
    // Empty paragraph must respect StrutStyle height (10 * 10 = 100), matching SkParagraph.
    const double fontSize = 10;
    const double strutHeight = 10;
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontFamily: 'FlutterTest',
        strutStyle: StrutStyle(fontFamily: 'FlutterTest', fontSize: fontSize, height: strutHeight),
      ),
    );
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.height, 100);
  });

  test('TextHeightBehavior applies to an empty paragraph like to a single line', () {
    // With both flags off the only line (first and last at once) falls back to the unscaled font
    // metrics, whether the paragraph has text, an empty string or no text at all.
    const double fontSize = 7;
    const double heightMultiplier = 11;
    const textHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );

    Paragraph layout({double? height, TextHeightBehavior? textHeightBehavior, String? text}) {
      final builder = ParagraphBuilder(
        ParagraphStyle(
          fontFamily: 'FlutterTest',
          fontSize: fontSize,
          height: height,
          textHeightBehavior: textHeightBehavior,
        ),
      );
      if (text != null) {
        builder.addText(text);
      }
      return builder.build()..layout(const ParagraphConstraints(width: 1000));
    }

    final Paragraph unscaled = layout(text: 'x');
    final Paragraph scaled = layout(height: heightMultiplier, text: 'x');
    expect(scaled.height, greaterThan(unscaled.height));

    final Paragraph withText = layout(
      height: heightMultiplier,
      textHeightBehavior: textHeightBehavior,
      text: 'x',
    );
    final Paragraph withEmptyString = layout(
      height: heightMultiplier,
      textHeightBehavior: textHeightBehavior,
      text: '',
    );
    final Paragraph empty = layout(
      height: heightMultiplier,
      textHeightBehavior: textHeightBehavior,
    );
    expect(withText.height, closeTo(unscaled.height, 1e-3));
    expect(withEmptyString.height, closeTo(unscaled.height, 1e-3));
    expect(empty.height, closeTo(unscaled.height, 1e-3));
  });

  test('Empty paragraph with an even strut keeps the extra leading', () {
    // SkParagraph computes the metrics of an empty paragraph differently from a line with text:
    // with half-leading the extra leading is kept apart from the ascent and the descent, so
    // `TextHeightBehavior` does not remove it and a taller non-forced strut does not absorb it.
    // WebParagraph mirrors that on purpose. FlutterTest has an ascent of 0.75 and a descent of
    // 0.25 of the font size.
    const double fontSize = 10;
    const double heightMultiplier = 3;
    const double extraLeading = (heightMultiplier - 1) * fontSize;
    const textHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );

    Paragraph layout({
      required double strutFontSize,
      double? height,
      TextHeightBehavior? textHeightBehavior,
      String? text,
    }) {
      final builder = ParagraphBuilder(
        ParagraphStyle(
          fontFamily: 'FlutterTest',
          fontSize: fontSize,
          height: height,
          textHeightBehavior: textHeightBehavior,
          strutStyle: StrutStyle(
            fontFamily: 'FlutterTest',
            fontSize: strutFontSize,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      );
      if (text != null) {
        builder.addText(text);
      }
      return builder.build()..layout(const ParagraphConstraints(width: 1000));
    }

    // A line with text goes back to the font height, the empty paragraph keeps the extra leading.
    final Paragraph withText = layout(
      strutFontSize: fontSize,
      height: heightMultiplier,
      textHeightBehavior: textHeightBehavior,
      text: 'x',
    );
    expect(withText.height, closeTo(fontSize, 1e-3));
    final Paragraph empty = layout(
      strutFontSize: fontSize,
      height: heightMultiplier,
      textHeightBehavior: textHeightBehavior,
    );
    expect(empty.height, closeTo(heightMultiplier * fontSize, 1e-3));
    expect(empty.alphabeticBaseline, closeTo(0.75 * fontSize + extraLeading / 2, 1e-3));

    // A strut 1.5 times taller than the font replaces the unscaled ascent and descent, and the
    // extra leading is added on top of it.
    final Paragraph strutOnly = layout(strutFontSize: 1.5 * fontSize);
    expect(strutOnly.height, closeTo(1.5 * fontSize, 1e-3));
    final Paragraph strutAndHeight = layout(
      strutFontSize: 1.5 * fontSize,
      height: heightMultiplier,
    );
    expect(strutAndHeight.height, closeTo(1.5 * fontSize + extraLeading, 1e-3));
    expect(
      strutAndHeight.alphabeticBaseline,
      closeTo(0.75 * 1.5 * fontSize + extraLeading / 2, 1e-3),
    );
  });
}
