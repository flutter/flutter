// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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

ui.Paragraph build(ui.ParagraphStyle style, String text,
    {ui.TextStyle textStyle}) {
  final ui.ParagraphBuilder builder = ui.ParagraphBuilder(style);
  if (textStyle != null) {
    builder.pushStyle(textStyle);
  }
  builder.addText(text);
  return builder.build();
}

typedef MeasurementTestBody = void Function(TextMeasurementService instance);

/// Runs the same test twice - once with dom measurement and once with canvas
/// measurement.
void testMeasurements(String description, MeasurementTestBody body, {
  bool skipDom,
  bool skipCanvas,
}) {
  test(
    '$description (dom)',
    () => body(TextMeasurementService.domInstance),
    skip: skipDom,
  );
  test(
    '$description (canvas)',
    () => body(TextMeasurementService.canvasInstance),
    skip: skipCanvas,
  );
}

void main() async {
  await ui.webOnlyInitializeTestDomRenderer();

  group('$RulerManager', () {
    final ui.ParagraphStyle s1 = ui.ParagraphStyle(fontFamily: 'sans-serif');
    final ui.ParagraphStyle s2 = ui.ParagraphStyle(
      fontWeight: ui.FontWeight.bold,
    );
    final ui.ParagraphStyle s3 = ui.ParagraphStyle(fontSize: 22.0);

    ParagraphGeometricStyle style1, style2, style3;
    EngineParagraph style1Text1, style1Text2; // two paragraphs sharing style
    EngineParagraph style2Text1, style3Text3;

    setUp(() {
      style1Text1 = build(s1, '1');
      style1Text2 = build(s1, '2');
      style2Text1 = build(s2, '1');
      style3Text3 = build(s3, '3');

      style1 = style1Text1.geometricStyle;
      style2 = style2Text1.geometricStyle;
      style3 = style3Text3.geometricStyle;

      final ParagraphGeometricStyle style1_2 = style1Text2.geometricStyle;
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
        expect(result.lines, <EngineLineMetrics>[
          line('   abc', 0, 6, hardBreak: true, width: 60.0, lineNumber: 0, left: 0.0),
        ]);

        // trailing whitespaces
        text = build(ahemStyle, 'abc   ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 60);
        expect(result.minIntrinsicWidth, 30);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('abc   ', 0, 6, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement always includes trailing whitespace in the
          // width, while Flutter and Canvas-based measurement don't.
          expect(result.lines, <EngineLineMetrics>[
            line('abc   ', 0, 6, hardBreak: true, width: 60.0, lineNumber: 0, left: 0.0),
          ]);
        }

        // mixed whitespaces
        text = build(ahemStyle, '  ab   c  ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 100);
        expect(result.minIntrinsicWidth, 20);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('  ab   c  ', 0, 10, hardBreak: true, width: 80.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement always includes trailing whitespace in the
          // width, while Flutter and Canvas-based measurement don't.
          expect(result.lines, <EngineLineMetrics>[
            line('  ab   c  ', 0, 10, hardBreak: true, width: 100.0, lineNumber: 0, left: 0.0),
          ]);
        }

        // single whitespace
        text = build(ahemStyle, ' ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 10);
        expect(result.minIntrinsicWidth, 0);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line(' ', 0, 1, hardBreak: true, width: 0.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement always includes trailing whitespace in the
          // width, while Flutter and Canvas-based measurement don't.
          expect(result.lines, <EngineLineMetrics>[
            line(' ', 0, 1, hardBreak: true, width: 10.0, lineNumber: 0, left: 0.0),
          ]);
        }

        // whitespace only
        text = build(ahemStyle, '     ');
        result = instance.measure(text, infiniteConstraints);
        expect(result.maxIntrinsicWidth, 50);
        expect(result.minIntrinsicWidth, 0);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('     ', 0, 5, hardBreak: true, width: 0.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement always includes trailing whitespace in the
          // width, while Flutter and Canvas-based measurement don't.
          expect(result.lines, <EngineLineMetrics>[
            line('     ', 0, 5, hardBreak: true, width: 50.0, lineNumber: 0, left: 0.0),
          ]);
        }
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
        expect(result.lines, <EngineLineMetrics>[
          line('12345', 0, 5, hardBreak: true, width: 50.0, lineNumber: 0, left: 0.0),
        ]);
      },
    );

    testMeasurements(
      'simple multi-line text',
      (TextMeasurementService instance) {
        const ui.ParagraphConstraints constraints =
            ui.ParagraphConstraints(width: 70);
        MeasurementResult result;

        // The long text doesn't fit in 70px of width, so it needs to wrap.
        result = instance.measure(build(ahemStyle, 'foo bar baz'), constraints);
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 110);
        expect(result.minIntrinsicWidth, 30);
        expect(result.width, 70);
        expect(result.height, 20);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('foo bar ', 0, 8, hardBreak: false, width: 70.0, lineNumber: 0, left: 0.0),
            line('baz', 8, 11, hardBreak: true, width: 30.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }
      },
    );

    testMeasurements(
      'uses multi-line for long text',
      (TextMeasurementService instance) {
        MeasurementResult result;

        // The long text doesn't fit in 50px of width, so it needs to wrap.
        result = instance.measure(build(ahemStyle, '1234567890'), constraints);
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 100);
        expect(result.minIntrinsicWidth, 100);
        expect(result.width, 50);
        expect(result.height, 20);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('12345', 0, 5, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
            line('67890', 5, 10, hardBreak: true, width: 50.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // The first word is force-broken twice.
        result =
            instance.measure(build(ahemStyle, 'abcdefghijk lm'), constraints);
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 140);
        expect(result.minIntrinsicWidth, 110);
        expect(result.width, 50);
        expect(result.height, 30);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('abcde', 0, 5, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
            line('fghij', 5, 10, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
            line('k lm', 10, 14, hardBreak: true, width: 40.0, lineNumber: 2, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // Constraints aren't enough even for a single character. In this case,
        // we show a minimum of one character per line.
        const ui.ParagraphConstraints narrowConstraints =
            ui.ParagraphConstraints(width: 8);
        result = instance.measure(build(ahemStyle, 'AA'), narrowConstraints);
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 20);
        expect(result.minIntrinsicWidth, 20);
        expect(result.width, 8);
        expect(result.height, 20);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('A', 0, 1, hardBreak: false, width: 10.0, lineNumber: 0, left: 0.0),
            line('A', 1, 2, hardBreak: true, width: 10.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // Extremely narrow constraints with new line in the middle.
        result = instance.measure(build(ahemStyle, 'AA\nA'), narrowConstraints);
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 20);
        expect(result.minIntrinsicWidth, 20);
        expect(result.width, 8);
        expect(result.height, 30);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('A', 0, 1, hardBreak: false, width: 10.0, lineNumber: 0, left: 0.0),
            line('A', 1, 3, hardBreak: true, width: 10.0, lineNumber: 1, left: 0.0),
            line('A', 3, 4, hardBreak: true, width: 10.0, lineNumber: 2, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // Extremely narrow constraints with new line in the end.
        result = instance.measure(build(ahemStyle, 'AAA\n'), narrowConstraints);
        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 30);
        expect(result.minIntrinsicWidth, 30);
        expect(result.width, 8);
        expect(result.height, 40);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('A', 0, 1, hardBreak: false, width: 10.0, lineNumber: 0, left: 0.0),
            line('A', 1, 2, hardBreak: false, width: 10.0, lineNumber: 1, left: 0.0),
            line('A', 2, 4, hardBreak: true, width: 10.0, lineNumber: 2, left: 0.0),
            line('', 4, 4, hardBreak: true, width: 0.0, lineNumber: 3, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }
      },
      skipDom: browserEngine == BrowserEngine.webkit,
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
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('12', 0, 3, hardBreak: true, width: 20.0, lineNumber: 0, left: 0.0),
            line('34', 3, 5, hardBreak: true, width: 20.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }
      },
    );

    testMeasurements('empty lines', (TextMeasurementService instance) {
      MeasurementResult result;

      // Empty lines in the beginning.
      result = instance.measure(build(ahemStyle, '\n\n1234'), constraints);
      expect(result.maxIntrinsicWidth, 40);
      expect(result.minIntrinsicWidth, 40);
      expect(result.height, 30);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('', 0, 1, hardBreak: true, width: 0.0, lineNumber: 0, left: 0.0),
          line('', 1, 2, hardBreak: true, width: 0.0, lineNumber: 1, left: 0.0),
          line('1234', 2, 6, hardBreak: true, width: 40.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // Empty lines in the middle.
      result = instance.measure(build(ahemStyle, '12\n\n345'), constraints);
      expect(result.maxIntrinsicWidth, 30);
      expect(result.minIntrinsicWidth, 30);
      expect(result.height, 30);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('12', 0, 3, hardBreak: true, width: 20.0, lineNumber: 0, left: 0.0),
          line('', 3, 4, hardBreak: true, width: 0.0, lineNumber: 1, left: 0.0),
          line('345', 4, 7, hardBreak: true, width: 30.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // Empty lines in the end.
      result = instance.measure(build(ahemStyle, '1234\n\n'), constraints);
      expect(result.maxIntrinsicWidth, 40);
      expect(result.minIntrinsicWidth, 40);
      if (instance.isCanvas) {
        // This can only be done correctly in the canvas-based implementation.
        expect(result.height, 30);
        expect(result.lines, <EngineLineMetrics>[
          line('1234', 0, 5, hardBreak: true, width: 40.0, lineNumber: 0, left: 0.0),
          line('', 5, 6, hardBreak: true, width: 0.0, lineNumber: 1, left: 0.0),
          line('', 6, 6, hardBreak: true, width: 0.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }
    });

    testMeasurements(
      'wraps multi-line text correctly when constraint width is infinite',
      (TextMeasurementService instance) {
        final EngineParagraph paragraph = build(ahemStyle, '123\n456 789');
        final MeasurementResult result =
            instance.measure(paragraph, infiniteConstraints);

        expect(result.isSingleLine, false);
        expect(result.maxIntrinsicWidth, 70);
        expect(result.minIntrinsicWidth, 30);
        expect(result.width, double.infinity);
        expect(result.height, 20);

        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('123', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
            line('456 789', 4, 11, hardBreak: true, width: 70.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }
      },
    );

    testMeasurements(
      'takes letter spacing into account',
      (TextMeasurementService instance) {
        const ui.ParagraphConstraints constraints =
            ui.ParagraphConstraints(width: 100);
        final ui.TextStyle spacedTextStyle = ui.TextStyle(letterSpacing: 3);
        final ui.Paragraph spacedText =
            build(ahemStyle, 'abc', textStyle: spacedTextStyle);

        final MeasurementResult spacedResult =
            instance.measure(spacedText, constraints);

        expect(spacedResult.minIntrinsicWidth, 39);
        expect(spacedResult.maxIntrinsicWidth, 39);
      },
    );

    test('takes word spacing into account', () {
      const ui.ParagraphConstraints constraints =
          ui.ParagraphConstraints(width: 100);

      final ui.ParagraphBuilder normalBuilder = ui.ParagraphBuilder(ahemStyle);
      normalBuilder.addText('a b c');
      final ui.Paragraph normalText = normalBuilder.build();

      final ui.ParagraphBuilder spacedBuilder = ui.ParagraphBuilder(ahemStyle);
      spacedBuilder.pushStyle(ui.TextStyle(wordSpacing: 1.5));
      spacedBuilder.addText('a b c');
      final ui.Paragraph spacedText = spacedBuilder.build();

      // Word spacing is only supported via DOM measurement.
      final TextMeasurementService instance =
          TextMeasurementService.forParagraph(spacedText);
      expect(instance, const TypeMatcher<DomTextMeasurementService>());

      final MeasurementResult normalResult =
          instance.measure(normalText, constraints);
      final MeasurementResult spacedResult =
          instance.measure(spacedText, constraints);

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
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abc ', 0, 4, hardBreak: false, width: 30.0, lineNumber: 0, left: 0.0),
          line('de ', 4, 7, hardBreak: false, width: 20.0, lineNumber: 1, left: 0.0),
          line('fghi', 7, 11, hardBreak: true, width: 40.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With new lines.
      result = instance.measure(build(ahemStyle, 'abcd\nef\nghi'), constraints);
      expect(result.minIntrinsicWidth, 40);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abcd', 0, 5, hardBreak: true, width: 40.0, lineNumber: 0, left: 0.0),
          line('ef', 5, 8, hardBreak: true, width: 20.0, lineNumber: 1, left: 0.0),
          line('ghi', 8, 11, hardBreak: true, width: 30.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With trailing whitespace.
      result = instance.measure(build(ahemStyle, 'abcd      efg'), constraints);
      expect(result.minIntrinsicWidth, 40);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abcd      ', 0, 10, hardBreak: false, width: 40.0, lineNumber: 0, left: 0.0),
          line('efg', 10, 13, hardBreak: true, width: 30.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With trailing whitespace and new lines.
      result = instance.measure(build(ahemStyle, 'abc    \ndefg'), constraints);
      expect(result.minIntrinsicWidth, 40);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abc    ', 0, 8, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
          line('defg', 8, 12, hardBreak: true, width: 40.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // Very long text.
      result = instance.measure(build(ahemStyle, 'AAAAAAAAAAAA'), constraints);
      expect(result.minIntrinsicWidth, 120);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('AAAAA', 0, 5, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
          line('AAAAA', 5, 10, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('AA', 10, 12, hardBreak: true, width: 20.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }
    });

    testMeasurements('maxIntrinsicWidth', (TextMeasurementService instance) {
      MeasurementResult result;

      // Simple case.
      result = instance.measure(build(ahemStyle, 'abc de fghi'), constraints);
      expect(result.maxIntrinsicWidth, 110);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abc ', 0, 4, hardBreak: false, width: 30.0, lineNumber: 0, left: 0.0),
          line('de ', 4, 7, hardBreak: false, width: 20.0, lineNumber: 1, left: 0.0),
          line('fghi', 7, 11, hardBreak: true, width: 40.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With new lines.
      result = instance.measure(build(ahemStyle, 'abcd\nef\nghi'), constraints);
      expect(result.maxIntrinsicWidth, 40);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abcd', 0, 5, hardBreak: true, width: 40.0, lineNumber: 0, left: 0.0),
          line('ef', 5, 8, hardBreak: true, width: 20.0, lineNumber: 1, left: 0.0),
          line('ghi', 8, 11, hardBreak: true, width: 30.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With long whitespace.
      result = instance.measure(build(ahemStyle, 'abcd   efg'), constraints);
      expect(result.maxIntrinsicWidth, 100);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abcd   ', 0, 7, hardBreak: false, width: 40.0, lineNumber: 0, left: 0.0),
          line('efg', 7, 10, hardBreak: true, width: 30.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With trailing whitespace.
      result = instance.measure(build(ahemStyle, 'abc def   '), constraints);
      expect(result.maxIntrinsicWidth, 100);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abc ', 0, 4, hardBreak: false, width: 30.0, lineNumber: 0, left: 0.0),
          line('def   ', 4, 10, hardBreak: true, width: 30.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // With trailing whitespace and new lines.
      result = instance.measure(build(ahemStyle, 'abc \ndef   '), constraints);
      expect(result.maxIntrinsicWidth, 60);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('abc ', 0, 5, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
          line('def   ', 5, 11, hardBreak: true, width: 30.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // Very long text.
      result = instance.measure(build(ahemStyle, 'AAAAAAAAAAAA'), constraints);
      expect(result.maxIntrinsicWidth, 120);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('AAAAA', 0, 5, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
          line('AAAAA', 5, 10, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('AA', 10, 12, hardBreak: true, width: 20.0, lineNumber: 2, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }
    });

    testMeasurements(
      'respects text overflow',
      (TextMeasurementService instance) {
        final ui.ParagraphStyle overflowStyle = ui.ParagraphStyle(
          fontFamily: 'ahem',
          fontSize: 10,
          ellipsis: '...',
        );

        MeasurementResult result;

        // The text shouldn't be broken into multiple lines, so the height should
        // be equal to a height of a single line.
        final ui.Paragraph longText = build(
          overflowStyle,
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        );
        result = instance.measure(longText, constraints);
        expect(result.minIntrinsicWidth, 480);
        expect(result.maxIntrinsicWidth, 480);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('AA...', 0, 48, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't handle the ellipsis case very well. The
          // text wraps into multiple lines instead.
          expect(result.lines, isNull);
        }

        // The short prefix should make the text break into two lines, but the
        // second line should remain unbroken.
        final ui.Paragraph longTextShortPrefix = build(
          overflowStyle,
          'AAA\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        );
        result = instance.measure(longTextShortPrefix, constraints);
        expect(result.minIntrinsicWidth, 450);
        expect(result.maxIntrinsicWidth, 450);
        expect(result.height, 20);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('AAA', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
            line('AA...', 4, 49, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't handle the ellipsis case very well. The
          // text wraps into multiple lines instead.
          expect(result.lines, isNull);
        }

        // Tiny constraints.
        const ui.ParagraphConstraints tinyConstraints =
            ui.ParagraphConstraints(width: 30);
        final ui.Paragraph text = build(overflowStyle, 'AAAA');
        result = instance.measure(text, tinyConstraints);
        expect(result.minIntrinsicWidth, 40);
        expect(result.maxIntrinsicWidth, 40);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('...', 0, 4, hardBreak: false, width: 30.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't handle the ellipsis case very well. The
          // text wraps into multiple lines instead.
          expect(result.lines, isNull);
        }

        // Tinier constraints (not enough for the ellipsis).
        const ui.ParagraphConstraints tinierConstraints =
            ui.ParagraphConstraints(width: 10);
        result = instance.measure(text, tinierConstraints);
        expect(result.minIntrinsicWidth, 40);
        expect(result.maxIntrinsicWidth, 40);
        expect(result.height, 10);
        if (instance.isCanvas) {
          // TODO(flutter_web): https://github.com/flutter/flutter/issues/34346
          // expect(result.lines, <EngineLineMetrics>[
          //   line('.', 0, 4, hardBreak: false, width: 10.0, lineNumber: 0, left: 0.0),
          // ]);
          expect(result.lines, <EngineLineMetrics>[
            line('...', 0, 4, hardBreak: false, width: 30.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't handle the ellipsis case very well. The
          // text wraps into multiple lines instead.
          expect(result.lines, isNull);
        }
      },
      skipDom: browserEngine == BrowserEngine.webkit,
    );

    testMeasurements('respects max lines', (TextMeasurementService instance) {
      final ui.ParagraphStyle maxlinesStyle = ui.ParagraphStyle(
        fontFamily: 'ahem',
        fontSize: 10,
        maxLines: 2,
      );

      MeasurementResult result;

      // The height should be that of a single line.
      final ui.Paragraph oneline = build(maxlinesStyle, 'One line');
      result = instance.measure(oneline, infiniteConstraints);
      expect(result.height, 10);
      expect(result.lines, <EngineLineMetrics>[
        line('One line', 0, 8, hardBreak: true, width: 80.0, lineNumber: 0, left: 0.0),
      ]);

      // The height should respect max lines and be limited to two lines here.
      final ui.Paragraph threelines =
          build(maxlinesStyle, 'First\nSecond\nThird');
      result = instance.measure(threelines, infiniteConstraints);
      expect(result.height, 20);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('First', 0, 6, hardBreak: true, width: 50.0, lineNumber: 0, left: 0.0),
          line('Second', 6, 13, hardBreak: true, width: 60.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // The height should respect max lines and be limited to two lines here.
      final ui.Paragraph veryLong = build(
        maxlinesStyle,
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      );
      result = instance.measure(veryLong, constraints);
      expect(result.height, 20);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('Lorem ', 0, 6, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
          line('ipsum ', 6, 12, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }

      // Case when last line is a long unbreakable word.
      final ui.Paragraph veryLongLastLine = build(
        maxlinesStyle,
        'AAA AAAAAAAAAAAAAAAAAAA',
      );
      result = instance.measure(veryLongLastLine, constraints);
      expect(result.height, 20);
      if (instance.isCanvas) {
        expect(result.lines, <EngineLineMetrics>[
          line('AAA ', 0, 4, hardBreak: false, width: 30.0, lineNumber: 0, left: 0.0),
          line('AAAAA', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        ]);
      } else {
        // DOM-based measurement can't produce line metrics for multi-line
        // paragraphs.
        expect(result.lines, isNull);
      }
    });

    testMeasurements(
      'respects text overflow and max lines combined',
      (TextMeasurementService instance) {
        const ui.ParagraphConstraints constraints =
            ui.ParagraphConstraints(width: 60);
        final ui.ParagraphStyle onelineStyle = ui.ParagraphStyle(
          fontFamily: 'ahem',
          fontSize: 10,
          maxLines: 1,
          ellipsis: '...',
        );
        final ui.ParagraphStyle multilineStyle = ui.ParagraphStyle(
          fontFamily: 'ahem',
          fontSize: 10,
          maxLines: 2,
          ellipsis: '...',
        );

        ui.Paragraph p;
        MeasurementResult result;

        // Simple no overflow case.
        p = build(onelineStyle, 'abcdef');
        result = instance.measure(p, constraints);
        expect(result.height, 10);
        expect(result.lines, <EngineLineMetrics>[
          line('abcdef', 0, 6, hardBreak: true, width: 60.0, lineNumber: 0, left: 0.0),
        ]);

        // Simple overflow case.
        p = build(onelineStyle, 'abcd efg');
        result = instance.measure(p, constraints);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('abc...', 0, 8, hardBreak: false, width: 60.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't handle the ellipsis case very well. The
          // text wraps into multiple lines instead.
          expect(result.lines, isNull);
        }

        // Another simple overflow case.
        p = build(onelineStyle, 'a bcde fgh');
        result = instance.measure(p, constraints);
        expect(result.height, 10);
        if (instance.isCanvas) {
          expect(result.lines, <EngineLineMetrics>[
            line('a b...', 0, 10, hardBreak: false, width: 60.0, lineNumber: 0, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't handle the ellipsis case very well. The
          // text wraps into multiple lines instead.
          expect(result.lines, isNull);
        }

        // The ellipsis is supposed to go on the second line, but because the
        // 2nd line doesn't overflow, no ellipsis is shown.
        p = build(multilineStyle, 'abcdef ghijkl');
        result = instance.measure(p, constraints);
        // This can only be done correctly in the canvas-based implementation.
        if (instance.isCanvas) {
          expect(result.height, 20);

          expect(result.lines, <EngineLineMetrics>[
            line('abcdef ', 0, 7, hardBreak: false, width: 60.0, lineNumber: 0, left: 0.0),
            line('ghijkl', 7, 13, hardBreak: true, width: 60.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // But when the 2nd line is long enough, the ellipsis is shown.
        p = build(multilineStyle, 'abcd efghijkl');
        result = instance.measure(p, constraints);
        // This can only be done correctly in the canvas-based implementation.
        if (instance.isCanvas) {
          expect(result.height, 20);

          expect(result.lines, <EngineLineMetrics>[
            line('abcd ', 0, 5, hardBreak: false, width: 40.0, lineNumber: 0, left: 0.0),
            line('efg...', 5, 13, hardBreak: false, width: 60.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // Even if the second line can be broken, we don't break it, we just
        // insert the ellipsis.
        p = build(multilineStyle, 'abcde f gh ijk');
        result = instance.measure(p, constraints);
        // This can only be done correctly in the canvas-based implementation.
        if (instance.isCanvas) {
          expect(result.height, 20);

          expect(result.lines, <EngineLineMetrics>[
            line('abcde ', 0, 6, hardBreak: false, width: 50.0, lineNumber: 0, left: 0.0),
            line('f g...', 6, 14, hardBreak: false, width: 60.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // First line overflows but second line doesn't.
        p = build(multilineStyle, 'abcdefg hijk');
        result = instance.measure(p, constraints);
        // This can only be done correctly in the canvas-based implementation.
        if (instance.isCanvas) {
          expect(result.height, 20);

          expect(result.lines, <EngineLineMetrics>[
            line('abcdef', 0, 6, hardBreak: false, width: 60.0, lineNumber: 0, left: 0.0),
            line('g hijk', 6, 12, hardBreak: true, width: 60.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }

        // Both first and second lines overflow.
        p = build(multilineStyle, 'abcdefg hijklmnop');
        result = instance.measure(p, constraints);
        // This can only be done correctly in the canvas-based implementation.
        if (instance.isCanvas) {
          expect(result.height, 20);

          expect(result.lines, <EngineLineMetrics>[
            line('abcdef', 0, 6, hardBreak: false, width: 60.0, lineNumber: 0, left: 0.0),
            line('g h...', 6, 17, hardBreak: false, width: 60.0, lineNumber: 1, left: 0.0),
          ]);
        } else {
          // DOM-based measurement can't produce line metrics for multi-line
          // paragraphs.
          expect(result.lines, isNull);
        }
      },
    );

    test('handles textAlign', () {
      TextMeasurementService instance = TextMeasurementService.canvasInstance;
      ui.Paragraph p;
      MeasurementResult result;

      ui.ParagraphStyle createStyle(ui.TextAlign textAlign) {
        return ui.ParagraphStyle(
          fontFamily: 'ahem',
          fontSize: 10,
          textAlign: textAlign,
          textDirection: ui.TextDirection.ltr,
        );
      }

      p = build(createStyle(ui.TextAlign.start), 'abc\ndefghi');
      result = instance.measure(p, constraints);
      expect(result.lines, <EngineLineMetrics>[
        line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
        line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 0.0),
      ]);

      p = build(createStyle(ui.TextAlign.end), 'abc\ndefghi');
      result = instance.measure(p, constraints);
      expect(result.lines, <EngineLineMetrics>[
        line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 20.0),
        line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 40.0),
      ]);

      p = build(createStyle(ui.TextAlign.center), 'abc\ndefghi');
      result = instance.measure(p, constraints);
      expect(result.lines, <EngineLineMetrics>[
        line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 10.0),
        line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 20.0),
      ]);

      p = build(createStyle(ui.TextAlign.left), 'abc\ndefghi');
      result = instance.measure(p, constraints);
      expect(result.lines, <EngineLineMetrics>[
        line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
        line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 0.0),
      ]);

      p = build(createStyle(ui.TextAlign.right), 'abc\ndefghi');
      result = instance.measure(p, constraints);
      expect(result.lines, <EngineLineMetrics>[
        line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 20.0),
        line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
        line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 40.0),
      ]);
    });

    testMeasurements(
      'handles rtl with textAlign',
      (TextMeasurementService instance) {
        TextMeasurementService instance = TextMeasurementService.canvasInstance;
        ui.Paragraph p;
        MeasurementResult result;

        ui.ParagraphStyle createStyle(ui.TextAlign textAlign) {
          return ui.ParagraphStyle(
            fontFamily: 'ahem',
            fontSize: 10,
            textAlign: textAlign,
            textDirection: ui.TextDirection.rtl,
          );
        }

        p = build(createStyle(ui.TextAlign.start), 'abc\ndefghi');
        result = instance.measure(p, constraints);
        expect(result.lines, <EngineLineMetrics>[
          line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 20.0),
          line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 40.0),
        ]);

        p = build(createStyle(ui.TextAlign.end), 'abc\ndefghi');
        result = instance.measure(p, constraints);
        expect(result.lines, <EngineLineMetrics>[
          line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
          line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 0.0),
        ]);

        p = build(createStyle(ui.TextAlign.center), 'abc\ndefghi');
        result = instance.measure(p, constraints);
        expect(result.lines, <EngineLineMetrics>[
          line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 10.0),
          line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 20.0),
        ]);

        p = build(createStyle(ui.TextAlign.left), 'abc\ndefghi');
        result = instance.measure(p, constraints);
        expect(result.lines, <EngineLineMetrics>[
          line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 0.0),
          line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 0.0),
        ]);

        p = build(createStyle(ui.TextAlign.right), 'abc\ndefghi');
        result = instance.measure(p, constraints);
        expect(result.lines, <EngineLineMetrics>[
          line('abc', 0, 4, hardBreak: true, width: 30.0, lineNumber: 0, left: 20.0),
          line('defgh', 4, 9, hardBreak: false, width: 50.0, lineNumber: 1, left: 0.0),
          line('i', 9, 10, hardBreak: true, width: 10.0, lineNumber: 2, left: 40.0),
        ]);
      },
    );
  });
}

/// Shortcut to avoid many line wraps in the tests above.
EngineLineMetrics line(
  String displayText,
  int startIndex,
  int endIndex, {
  double width,
  int lineNumber,
  bool hardBreak,
  double left,
}) {
  return EngineLineMetrics.withText(
    displayText,
    startIndex: startIndex,
    endIndex: endIndex,
    hardBreak: hardBreak,
    width: width,
    lineNumber: lineNumber,
    left: left,
    endIndexWithoutNewlines: -1,
  );
}
