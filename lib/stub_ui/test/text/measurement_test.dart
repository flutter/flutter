// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

void main() {
  group('$TextMeasurementService', () {
    ui.ParagraphStyle s1 = ui.ParagraphStyle(fontFamily: 'sans-serif');
    ui.ParagraphStyle s2 = ui.ParagraphStyle(
      fontWeight: ui.FontWeight.bold,
    );
    ui.ParagraphStyle s3 = ui.ParagraphStyle(fontSize: 22.0);
    ui.ParagraphStyle ahemStyle = ui.ParagraphStyle(
      fontFamily: 'ahem',
      fontSize: 10,
    );

    ParagraphGeometricStyle style1, style2, style3;
    ui.Paragraph style1Text1, style1Text2; // two paragraphs sharing style
    ui.Paragraph style2Text1, style3Text3;
    const ui.ParagraphConstraints constraints =
        ui.ParagraphConstraints(width: 50.0);

    ui.Paragraph build(ui.ParagraphStyle style, String text) {
      var builder = ui.ParagraphBuilder(style);
      builder.addText(text);
      return builder.build();
    }

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
      var instance = TextMeasurementService.initialize(rulerCacheCapacity: 2);
      expect(instance.rulerCacheCapacity, 2);
      expect(instance.rulers.length, 0);

      // First ruler cached
      instance.measure(style1Text1, constraints);
      expect(instance.rulers.length, 1);
      expect(instance.rulers[style1].hitCount, 1);

      // Increase hit count for style 1
      instance.measure(style1Text1, constraints);
      expect(instance.rulers.length, 1);
      expect(instance.rulers[style1].hitCount, 2);

      // Previous ruler reused
      instance.measure(style1Text2, constraints);
      expect(instance.rulers.length, 1);
      expect(instance.rulers[style1].hitCount, 3);

      // Second ruler cached
      instance.measure(style2Text1, constraints);
      expect(instance.rulers.length, 2);
      expect(instance.rulers[style1].hitCount, 3);
      expect(instance.rulers[style2].hitCount, 1);

      // Increase hit count for style 2
      instance.measure(style2Text1, constraints);
      instance.measure(style2Text1, constraints);
      instance.measure(style2Text1, constraints);
      expect(instance.rulers.length, 2);
      expect(instance.rulers[style2].hitCount, 4);

      // Third ruler cached: it is ok to store more rulers that the cache capacity
      //                     because the cache is cleaned-up at the end of frame.
      instance.measure(style3Text3, constraints);

      // Final ruler states
      expect(instance.rulers.length, 3);
      expect(instance.rulers[style1].hitCount, 3);
      expect(instance.rulers[style2].hitCount, 4);
      expect(instance.rulers[style3].hitCount, 1);

      ParagraphRuler ruler3 = instance.rulers[style3];
      expect(ruler3.debugIsDisposed, isFalse);

      // Cleaning up the cache should bring its size down to capacity limit.
      instance.cleanUpRulerCache();
      expect(instance.rulers.length, 2);
      expect(instance.rulers, contains(style1)); // retained
      expect(instance.rulers, contains(style2)); // retained
      expect(instance.rulers, isNot(contains(style3))); // evicted
      expect(ruler3.debugIsDisposed, isTrue);

      ParagraphRuler style1Ruler = instance.rulers[style1];
      expect(style1Ruler.style, style1);
      expect(style1Ruler.hitCount, 0); // hit counts are reset

      ParagraphRuler style2Ruler = instance.rulers[style2];
      expect(style2Ruler.style, style2);
      expect(style2Ruler.hitCount, 0); // hit counts are reset
    });

    test('preserves whitespace when measuring', () {
      final TextMeasurementService instance =
          TextMeasurementService.initialize(rulerCacheCapacity: 10);
      const infiniteConstraints =
          ui.ParagraphConstraints(width: double.infinity);
      ui.Paragraph text;

      // leading whitespaces
      text = build(ahemStyle, '   abc');
      instance.measure(text, infiniteConstraints);
      expect(text.maxIntrinsicWidth, 60);
      expect(text.minIntrinsicWidth, 30);
      expect(text.height, 10);

      // trailing whitespaces
      text = build(ahemStyle, 'abc   ');
      instance.measure(text, infiniteConstraints);
      expect(text.maxIntrinsicWidth, 60);
      expect(text.minIntrinsicWidth, 30);
      expect(text.height, 10);

      // mixed whitespaces
      text = build(ahemStyle, '  ab   c  ');
      instance.measure(text, infiniteConstraints);
      expect(text.maxIntrinsicWidth, 100);
      expect(text.minIntrinsicWidth, 20);
      expect(text.height, 10);

      // single whitespace
      text = build(ahemStyle, ' ');
      instance.measure(text, infiniteConstraints);
      expect(text.maxIntrinsicWidth, 10);
      expect(text.minIntrinsicWidth, 0);
      expect(text.height, 10);

      // whitespace only
      text = build(ahemStyle, '     ');
      instance.measure(text, infiniteConstraints);
      expect(text.maxIntrinsicWidth, 50);
      expect(text.minIntrinsicWidth, 0);
      expect(text.height, 10);
    }, skip: true);

    test('uses single-line when text can fit without wrapping', () {
      final TextMeasurementService instance =
          TextMeasurementService.initialize(rulerCacheCapacity: 2);
      final ui.Paragraph longText = build(ahemStyle, '12345');

      instance.measure(longText, constraints);

      // Should fit on a single line.
      expect(longText.webOnlyDrawOnCanvas, true);
      expect(longText.maxIntrinsicWidth, 50);
      expect(longText.minIntrinsicWidth, 50);
      expect(longText.width, 50);
      expect(longText.height, 10);
    }, skip: true);

    test('uses multi-line for long text', () {
      final TextMeasurementService instance =
          TextMeasurementService.initialize(rulerCacheCapacity: 2);
      final ui.Paragraph longText = build(ahemStyle, '1234567890');

      instance.measure(longText, constraints);

      // The long text doesn't fit in 50px of width, so it needs to wrap.
      expect(longText.webOnlyDrawOnCanvas, false);
      expect(longText.maxIntrinsicWidth, 100);
      expect(longText.minIntrinsicWidth, 100);
      expect(longText.width, 50);
      expect(longText.height, 10);
    }, skip: true);

    test('uses multi-line for text that contains new-line', () {
      final TextMeasurementService instance =
          TextMeasurementService.initialize(rulerCacheCapacity: 2);
      final ui.Paragraph textWithNewline = build(ahemStyle, '12\n34');

      instance.measure(textWithNewline, constraints);

      // Text containing newlines should always be drawn in multi-line mode.
      expect(textWithNewline.webOnlyDrawOnCanvas, false);
      expect(textWithNewline.maxIntrinsicWidth, 20);
      expect(textWithNewline.minIntrinsicWidth, 20);
      expect(textWithNewline.width, 50);
      expect(textWithNewline.height, 20);
    }, skip: true);

    test('takes letter spacing into account', () {
      final TextMeasurementService instance =
          TextMeasurementService.initialize(rulerCacheCapacity: 2);

      final constraints = ui.ParagraphConstraints(width: 100);

      final normalBuilder = ui.ParagraphBuilder(ahemStyle);
      normalBuilder.addText('abc');
      final normalText = normalBuilder.build();

      final spacedBuilder = ui.ParagraphBuilder(ahemStyle);
      spacedBuilder.pushStyle(ui.TextStyle(letterSpacing: 1.5));
      spacedBuilder.addText('abc');
      final spacedText = spacedBuilder.build();

      instance.measure(normalText, constraints);
      instance.measure(spacedText, constraints);

      expect(
          normalText.maxIntrinsicWidth < spacedText.maxIntrinsicWidth, isTrue);
    });

    test('takes word spacing into account', () {
      final TextMeasurementService instance =
          TextMeasurementService.initialize(rulerCacheCapacity: 2);

      final constraints = ui.ParagraphConstraints(width: 100);

      final normalBuilder = ui.ParagraphBuilder(ahemStyle);
      normalBuilder.addText('a b c');
      final normalText = normalBuilder.build();

      final spacedBuilder = ui.ParagraphBuilder(ahemStyle);
      spacedBuilder.pushStyle(ui.TextStyle(wordSpacing: 1.5));
      spacedBuilder.addText('a b c');
      final spacedText = spacedBuilder.build();

      instance.measure(normalText, constraints);
      instance.measure(spacedText, constraints);

      expect(
          normalText.maxIntrinsicWidth < spacedText.maxIntrinsicWidth, isTrue);
    });
  });
}
