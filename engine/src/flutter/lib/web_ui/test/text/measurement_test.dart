// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

final ui.ParagraphStyle ahemStyle = ui.ParagraphStyle(
  fontFamily: 'ahem',
  fontSize: 10,
);
const ui.ParagraphConstraints constraints = ui.ParagraphConstraints(width: 50);
const ui.ParagraphConstraints infiniteConstraints =
    ui.ParagraphConstraints(width: double.infinity);

ui.Paragraph build(ui.ParagraphStyle style, String text) {
  var builder = ui.ParagraphBuilder(style);
  builder.addText(text);
  return builder.build();
}

typedef MeasurementTestBody = void Function(TextMeasurementService instance);

/// Runs the same test twice - once with dom measurement and once with canvas
/// measurement.
void testMeasurements(String description, MeasurementTestBody body) {
  test(
    '$description (dom)',
    () => body(TextMeasurementService.domInstance),
  );
  test(
    '$description (canvas)',
    () => body(TextMeasurementService.canvasInstance),
  );
}

void main() {
  group('$RulerManager', () {
    ui.ParagraphStyle s1 = ui.ParagraphStyle(fontFamily: 'sans-serif');
    ui.ParagraphStyle s2 = ui.ParagraphStyle(
      fontWeight: ui.FontWeight.bold,
    );
    ui.ParagraphStyle s3 = ui.ParagraphStyle(fontSize: 22.0);

    ParagraphGeometricStyle style1, style2, style3;
    ui.Paragraph style1Text1, style1Text2; // two paragraphs sharing style
    ui.Paragraph style2Text1, style3Text3;

    setUp(() {
      style1Text1 = build(s1, '1');
      style1Text2 = build(s1, '2');
      style2Text1 = build(s2, '1');
      style3Text3 = build(s3, '3');

      style1 = style1Text1.webOnlyGetParagraphGeometricStyle();
      style2 = style2Text1.webOnlyGetParagraphGeometricStyle();
      style3 = style3Text3.webOnlyGetParagraphGeometricStyle();

      ParagraphGeometricStyle style1_2 =
          style1Text2.webOnlyGetParagraphGeometricStyle();
      expect(style1_2, style1); // styles must be equal despite different text
    });

    test('caches rulers', () {
      final RulerManager rulerManager = RulerManager(rulerCacheCapacity: 2);
      ParagraphRuler ruler1, ruler2, ruler3;

      expect(rulerManager.rulerCacheCapacity, 2);
      expect(rulerManager.rulers.length, 0);

      // First ruler cached
      ruler1 = rulerManager.findOrCreateRuler(style1);
      expect(rulerManager.rulers.length, 1);
      expect(ruler1.hitCount, 1);

      // Increase hit count for style 1
      ruler1 = rulerManager.findOrCreateRuler(style1);
      expect(rulerManager.rulers.length, 1);
      expect(ruler1.hitCount, 2);

      // Previous ruler reused
      rulerManager.findOrCreateRuler(style1);
      expect(rulerManager.rulers.length, 1);
      expect(ruler1.hitCount, 3);

      // Second ruler created and cached
      ruler2 = rulerManager.findOrCreateRuler(style2);
      expect(rulerManager.rulers.length, 2);
      expect(ruler1.hitCount, 3);
      expect(ruler2.hitCount, 1);

      // Increase hit count for style 2
      rulerManager.findOrCreateRuler(style2);
      rulerManager.findOrCreateRuler(style2);
      rulerManager.findOrCreateRuler(style2);
      expect(rulerManager.rulers.length, 2);
      expect(ruler2.hitCount, 4);

      // Third ruler cached: it is ok to store more rulers that the cache
      // capacity because the cache is cleaned-up at the next microtask.
      ruler3 = rulerManager.findOrCreateRuler(style3);

      // Final ruler states
      expect(rulerManager.rulers.length, 3);
      expect(ruler1.hitCount, 3);
      expect(ruler2.hitCount, 4);
      expect(ruler3.hitCount, 1);
      // The least hit ruler isn't disposed yet.
      expect(ruler3.debugIsDisposed, isFalse);

      // Cleaning up the cache should bring its size down to capacity limit.
      rulerManager.cleanUpRulerCache();
      expect(rulerManager.rulers.length, 2);
      expect(rulerManager.rulers, containsValue(ruler1)); // retained
      expect(rulerManager.rulers, containsValue(ruler2)); // retained
      expect(rulerManager.rulers, isNot(containsValue(ruler3))); // evicted
      expect(ruler1.debugIsDisposed, isFalse);
      expect(ruler2.debugIsDisposed, isFalse);
      expect(ruler3.debugIsDisposed, isTrue);

      ruler1 = rulerManager.rulers[style1];
      expect(ruler1.style, style1);
      expect(ruler1.hitCount, 0); // hit counts are reset

      ruler2 = rulerManager.rulers[style2];
      expect(ruler2.style, style2);
      expect(ruler2.hitCount, 0); // hit counts are reset
    });
  });

  group('$TextMeasurementService', () {
    setUp(() {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
    });
    tearDown(() {
      TextMeasurementService.clearCache();
    });

    testMeasurements(
      'preserves whitespace when measuring',
      (TextMeasurementService instance) {
        ui.Paragraph text;
        MeasurementResult result;

        // leading whitespaces
        text = build(ahemStyle, '   abc');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 60);
        expect(result.minIntrinsicWidth, 30);
        expect(result.height, 10);

        // trailing whitespaces
        text = build(ahemStyle, 'abc   ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 60);
        expect(result.minIntrinsicWidth, 30);
        expect(result.height, 10);

        // mixed whitespaces
        text = build(ahemStyle, '  ab   c  ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 100);
        expect(result.minIntrinsicWidth, 20);
        expect(result.height, 10);

        // single whitespace
        text = build(ahemStyle, ' ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 10);
        expect(result.minIntrinsicWidth, 0);
        expect(result.height, 10);

        // whitespace only
        text = build(ahemStyle, '     ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 50);
        expect(result.minIntrinsicWidth, 0);
        expect(result.height, 10);
      },
    );

    testMeasurements(
      'uses single-line when text can fit without wrapping',
      (TextMeasurementService instance) {
        final MeasurementResult result =
            instance.measure(build(ahemStyle, '12345'), constraints);

        // Should fit on a single line.
        expect(result.isSingleLine, true);
        expect(result.maxIntrinsicWidth, 50);
        expect(result.minIntrinsicWidth, 50);
        expect(result.width, 50);
        expect(result.height, 10);
      },
    );

    testMeasurements(
      'uses multi-line for long text',
      (TextMeasurementService instance) {
        final MeasurementResult result =
            instance.measure(build(ahemStyle, '1234567890'), constraints);

        // The long text doesn't fit in 50px of width, so it needs to wrap.
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 100);
        expect(result.minIntrinsicWidth, 100);
        expect(result.width, 50);
        expect(result.height, 20);
      },
    );

    testMeasurements(
      'uses multi-line for text that contains new-line',
      (TextMeasurementService instance) {
        final MeasurementResult result =
            instance.measure(build(ahemStyle, '12\n34'), constraints);

        // Text containing newlines should always be drawn in multi-line mode.
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 20);
        expect(result.minIntrinsicWidth, 20);
        expect(result.width, 50);
        expect(result.height, 20);
      },
    );

    testMeasurements('empty lines', (TextMeasurementService instance) {
      MeasurementResult result;

      // Empty lines in the beginning.
      result = instance.measure(build(ahemStyle, '\n\n1234'), constraints);
      expect(result.maxIntrinsicWidth, 40);
      expect(result.minIntrinsicWidth, 40);
      expect(result.height, 30);

      // Empty lines in the middle.
      result = instance.measure(build(ahemStyle, '12\n\n345'), constraints);
      expect(result.maxIntrinsicWidth, 30);
      expect(result.minIntrinsicWidth, 30);
      expect(result.height, 30);

      // This can only be done correctly in the canvas-based implementation.
      if (instance is CanvasTextMeasurementService) {
        // Empty lines in the end.
        result = instance.measure(build(ahemStyle, '1234\n\n'), constraints);
        expect(result.maxIntrinsicWidth, 40);
        expect(result.minIntrinsicWidth, 40);
        expect(result.height, 30);
      }
    });

    test('takes letter spacing into account', () {
      final constraints = ui.ParagraphConstraints(width: 100);

      final normalBuilder = ui.ParagraphBuilder(ahemStyle);
      normalBuilder.addText('abc');
      final normalText = normalBuilder.build();

      final spacedBuilder = ui.ParagraphBuilder(ahemStyle);
      spacedBuilder.pushStyle(ui.TextStyle(letterSpacing: 1.5));
      spacedBuilder.addText('abc');
      final spacedText = spacedBuilder.build();

      // Letter spacing is only supported via DOM measurement.
      final TextMeasurementService instance =
          TextMeasurementService.forParagraph(spacedText);
      expect(instance, isInstanceOf<DomTextMeasurementService>());

      final normalResult = instance.measure(normalText, constraints);
      final spacedResult = instance.measure(spacedText, constraints);

      expect(
        normalResult.maxIntrinsicWidth < spacedResult.maxIntrinsicWidth,
        isTrue,
      );
    });

    test('takes word spacing into account', () {
      final constraints = ui.ParagraphConstraints(width: 100);

      final normalBuilder = ui.ParagraphBuilder(ahemStyle);
      normalBuilder.addText('a b c');
      final normalText = normalBuilder.build();

      final spacedBuilder = ui.ParagraphBuilder(ahemStyle);
      spacedBuilder.pushStyle(ui.TextStyle(wordSpacing: 1.5));
      spacedBuilder.addText('a b c');
      final spacedText = spacedBuilder.build();

      // Word spacing is only supported via DOM measurement.
      final TextMeasurementService instance =
          TextMeasurementService.forParagraph(spacedText);
      expect(instance, isInstanceOf<DomTextMeasurementService>());

      final normalResult = instance.measure(normalText, constraints);
      final spacedResult = instance.measure(spacedText, constraints);

      expect(
        normalResult.maxIntrinsicWidth < spacedResult.maxIntrinsicWidth,
        isTrue,
      );
    });

    testMeasurements('minIntrinsicWidth', (TextMeasurementService instance) {
      MeasurementResult result;

      // Simple case.
      result = instance.measure(build(ahemStyle, 'abc de fghi'), constraints);
      expect(result.minIntrinsicWidth, 40);

      // With new lines.
      result = instance.measure(build(ahemStyle, 'abcd\nef\nghi'), constraints);
      expect(result.minIntrinsicWidth, 40);

      // With trailing whitespace.
      result = instance.measure(build(ahemStyle, 'abcd      efg'), constraints);
      expect(result.minIntrinsicWidth, 40);

      // With trailing whitespace and new lines.
      result = instance.measure(build(ahemStyle, 'abc    \ndefg'), constraints);
      expect(result.minIntrinsicWidth, 40);

      // Very long text.
      result = instance.measure(build(ahemStyle, 'AAAAAAAAAAAA'), constraints);
      expect(result.minIntrinsicWidth, 120);
    });

    testMeasurements('maxIntrinsicWidth', (TextMeasurementService instance) {
      MeasurementResult result;

      // Simple case.
      result = instance.measure(build(ahemStyle, 'abc de fghi'), constraints);
      expect(result.maxIntrinsicWidth, 110);

      // With new lines.
      result = instance.measure(build(ahemStyle, 'abcd\nef\nghi'), constraints);
      expect(result.maxIntrinsicWidth, 40);

      // With long whitespace.
      result = instance.measure(build(ahemStyle, 'abcd   efg'), constraints);
      expect(result.maxIntrinsicWidth, 100);

      // With trailing whitespace.
      result = instance.measure(build(ahemStyle, 'abc def   '), constraints);
      expect(result.maxIntrinsicWidth, 100);

      // With trailing whitespace and new lines.
      result = instance.measure(build(ahemStyle, 'abc \ndef   '), constraints);
      expect(result.maxIntrinsicWidth, 60);

      // Very long text.
      result = instance.measure(build(ahemStyle, 'AAAAAAAAAAAA'), constraints);
      expect(result.maxIntrinsicWidth, 120);
    });

    // TODO(mdebbar): The canvas-based measurement doesn't handle this yet.
    test('respects text overflow', () {
      final TextMeasurementService instance =
          TextMeasurementService.domInstance;

      final overflowStyle = ui.ParagraphStyle(
        fontFamily: 'ahem',
        fontSize: 10,
        ellipsis: '...',
      );

      final constraints = ui.ParagraphConstraints(width: 50);

      MeasurementResult result;

      // The text shouldn't be broken into multiple lines, so the height should
      // be equal to a height of a single line.
      final longText = build(
        overflowStyle,
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      );
      result = instance.measure(longText, constraints);
      expect(result.height, 10);

      // The short prefix should make the text break into two lines, but the
      // second line should remain unbroken.
      final longTextShortPrefix = build(
        overflowStyle,
        'AAA\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      );
      result = instance.measure(longTextShortPrefix, constraints);
      expect(result.height, 20);

      // This can only be done correctly in the canvas-based implementation.
      // TODO(flutter_web): https://github.com/flutter/flutter/issues/33223
      // The first line is overflowing so we should stop the measurement there
      // and there should be no second line (the short suffix shouldn't be rendered).
      // final longTextShortSuffix = build(
      //   overflowStyle,
      //   'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\nAAA',
      // );
      // result = instance.measure(longTextShortSuffix, constraints);
      // expect(result.height, 10);
    });

    // TODO(mdebbar): The canvas-based measurement doesn't handle this yet.
    // https://github.com/flutter/flutter/issues/33223
    test('respects max lines', () {
      final TextMeasurementService instance =
          TextMeasurementService.domInstance;

      final maxlinesStyle = ui.ParagraphStyle(
        fontFamily: 'ahem',
        fontSize: 10,
        maxLines: 2,
      );

      MeasurementResult result;

      // The height should be that of a single line.
      final oneline = build(maxlinesStyle, 'One line');
      result = instance.measure(oneline, infiniteConstraints);
      expect(result.height, 10);

      // This can only be done correctly in the canvas-based implementation.
      // TODO(mdebbar): https://github.com/flutter/flutter/issues/33223
      // The height should respect max lines and be limited to two lines here.
      // final threelines = build(maxlinesStyle, 'First\nSecond\nThird');
      // result = instance.measure(threelines, infiniteConstraints);
      // expect(result.height, 20);
    });

    test('canvas line breaks', () {
      // TODO(mdebbar): Add tests and make sure to cover the following edge cases:
      // 1. First chunk already overflows the width constraint.
      // 2. maxIntrinsicWidth in the presence of mandatory line breaks.
      // 3. minIntrinsicWidth in the presence of optional line breaks.
      // 4. empty lines in the middle.
      // 5. long text with a short prefix.
      // 6. long text with a short suffix.
      // 7. whitespace at end of line (shouldn't count towards minIntWidth, but counts towards max).
      // 8. long whitespace should still cause line break if not enough space for it.
    });
  });
}
