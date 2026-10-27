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

  test('StrutStyle inherits leadingDistribution from ParagraphStyle.textHeightBehavior', () {
    LineMetrics layoutWithStrut({
      TextHeightBehavior? textHeightBehavior,
      TextLeadingDistribution? strutLeadingDistribution,
    }) {
      final builder = ParagraphBuilder(
        ParagraphStyle(
          fontSize: 10,
          fontFamily: 'FlutterTest',
          textHeightBehavior: textHeightBehavior,
          strutStyle: StrutStyle(
            fontFamily: 'FlutterTest',
            fontSize: 10,
            height: 3,
            forceStrutHeight: true,
            leadingDistribution: strutLeadingDistribution,
          ),
        ),
      );
      builder.addText('A');
      final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
      final LineMetrics metrics = paragraph.computeLineMetrics().single;
      paragraph.dispose();
      return metrics;
    }

    final LineMetrics proportional = layoutWithStrut();
    final LineMetrics inheritedEven = layoutWithStrut(
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
    final LineMetrics explicitEven = layoutWithStrut(
      strutLeadingDistribution: TextLeadingDistribution.even,
    );
    final LineMetrics overriddenProportional = layoutWithStrut(
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
      strutLeadingDistribution: TextLeadingDistribution.proportional,
    );

    expect(inheritedEven.baseline, explicitEven.baseline);
    expect(inheritedEven.baseline, isNot(proportional.baseline));
    expect(overriddenProportional.baseline, proportional.baseline);
  });

  test('tracks placeholderCount and placeholderScales', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    expect(builder.placeholderCount, 0);
    expect(builder.placeholderScales, isEmpty);

    builder.addPlaceholder(10, 20, PlaceholderAlignment.top, scale: 1.5);
    builder.addPlaceholder(
      30,
      40,
      PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      scale: 2.0,
    );

    expect(builder.placeholderCount, 2);
    expect(builder.placeholderScales, <double>[1.5, 2.0]);

    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.getBoxesForPlaceholders(), hasLength(2));
    paragraph.dispose();
    expect(paragraph.debugDisposed, isTrue);
  });

  test('pop at root style does not throw', () {
    final builder = ParagraphBuilder(ParagraphStyle());
    expect(() => builder.pop(), returnsNormally);
    builder.addText('Hello');
    final Paragraph paragraph = builder.build();
    paragraph.dispose();
  });

  group('hyphens', () {
    const text = 'abcd\u00ADe';

    Paragraph layoutParagraph(Hyphens? hyphens, double width) {
      final builder = ParagraphBuilder(
        ParagraphStyle(fontSize: 10, fontFamily: 'FlutterTest', hyphens: hyphens),
      );
      builder.addText(text);
      return builder.build()..layout(ParagraphConstraints(width: width));
    }

    // Just narrower than the unbroken text, so the line breaks at the soft hyphen.
    double breakingWidth() => layoutParagraph(null, double.infinity).longestLine - 1;

    test('manual renders a hyphen at a soft hyphen line break', () {
      final Paragraph manual = layoutParagraph(Hyphens.manual, breakingWidth());
      final Paragraph hidden = layoutParagraph(Hyphens.hidden, breakingWidth());

      expect(manual.numberOfLines, 2);
      expect(hidden.numberOfLines, 2);
      expect(manual.longestLine, 50);
      expect(hidden.longestLine, 40);
    });

    test('unspecified behaves like manual', () {
      final Paragraph unspecified = layoutParagraph(null, breakingWidth());
      final Paragraph manual = layoutParagraph(Hyphens.manual, breakingWidth());

      expect(unspecified.longestLine, manual.longestLine);
    });
  });
}
