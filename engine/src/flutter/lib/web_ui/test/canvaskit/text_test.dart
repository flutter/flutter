// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit text', () {
    setUpCanvasKitTest();

    test("doesn't crash when using shadows", () {
      final ui.TextStyle textStyleWithShadows = ui.TextStyle(
        fontSize: 16,
        shadows: <ui.Shadow>[
          const ui.Shadow(
            blurRadius: 3.0,
            offset: ui.Offset(3.0, 3.0),
          ),
          const ui.Shadow(
            blurRadius: 3.0,
            offset: ui.Offset(-3.0, 3.0),
          ),
          const ui.Shadow(
            blurRadius: 3.0,
            offset: ui.Offset(3.0, -3.0),
          ),
          const ui.Shadow(
            blurRadius: 3.0,
            offset: ui.Offset(-3.0, -3.0),
          ),
        ],
        fontFamily: 'Roboto',
      );

      for (int i = 0; i < 10; i++) {
        final ui.ParagraphBuilder builder =
            ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 16));
        builder.pushStyle(textStyleWithShadows);
        builder.addText('test');
        final ui.Paragraph paragraph = builder.build();
        expect(paragraph, isNotNull);
      }
    });

    // Regression test for https://github.com/flutter/flutter/issues/78550
    test('getBoxesForRange works for LTR text in an RTL paragraph', () {
      // Create builder for an RTL paragraph.
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontSize: 16, textDirection: ui.TextDirection.rtl));
      builder.addText('hello');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 100));
      expect(paragraph, isNotNull);
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 1);
      expect(boxes, hasLength(1));
      // The direction for this span is LTR even though the paragraph is RTL
      // because the directionality of the 'h' is LTR.
      expect(boxes.single.direction, equals(ui.TextDirection.ltr));
    });

    test('Renders tab as space instead of tofu', () async {
      // CanvasKit renders a tofu if the font does not have a glyph for a
      // character. However, Flutter opts-in to a CanvasKit feature to render
      // tabs as a single space.
      // See: https://github.com/flutter/flutter/issues/79153
      Future<ui.Image> drawText(String text) {
        const ui.Rect bounds = ui.Rect.fromLTRB(0, 0, 100, 100);
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(bounds);
        final CkParagraph paragraph = makeSimpleText(text);

        canvas.drawParagraph(paragraph, ui.Offset.zero);
        final ui.Picture picture = recorder.endRecording();
        return picture.toImage(100, 100);
      }

      // The backspace character, \b, does not have a corresponding glyph and
      // is rendered as a tofu.
      final ui.Image tabImage = await drawText('>\t<');
      final ui.Image spaceImage = await drawText('> <');
      final ui.Image tofuImage = await drawText('>\b<');

      expect(await matchImage(tabImage, spaceImage), isTrue);
      expect(await matchImage(tabImage, tofuImage), isFalse);
    });

    group('test fonts in flutterTester environment', () {
      final bool resetValue = ui_web.debugEmulateFlutterTesterEnvironment;
      ui_web.debugEmulateFlutterTesterEnvironment = true;
      tearDownAll(() {
        ui_web.debugEmulateFlutterTesterEnvironment = resetValue;
      });
      const List<String> testFonts = <String>['FlutterTest', 'Ahem'];

      test('The default test font is used when a non-test fontFamily is specified', () {
        final String defaultTestFontFamily = testFonts.first;

        expect(CkTextStyle(fontFamily: 'BogusFontFamily').effectiveFontFamily, defaultTestFontFamily);
        expect(CkParagraphStyle(fontFamily: 'BogusFontFamily').getTextStyle().effectiveFontFamily, defaultTestFontFamily);
        expect(CkStrutStyle(fontFamily: 'BogusFontFamily'), CkStrutStyle(fontFamily: defaultTestFontFamily));
      });

      test('The default test font is used when fontFamily is unspecified', () {
        final String defaultTestFontFamily = testFonts.first;

        expect(CkTextStyle().effectiveFontFamily, defaultTestFontFamily);
        expect(CkParagraphStyle().getTextStyle().effectiveFontFamily, defaultTestFontFamily);
        expect(CkStrutStyle(), CkStrutStyle(fontFamily: defaultTestFontFamily));
      });

      test('Can specify test fontFamily to use', () {
        for (final String testFont in testFonts) {
          expect(CkTextStyle(fontFamily: testFont).effectiveFontFamily, testFont);
          expect(CkParagraphStyle(fontFamily: testFont).getTextStyle().effectiveFontFamily, testFont);
        }
      });
    });

    test('empty paragraph', () {
      const double fontSize = 10.0;
      final ui.Paragraph paragraph = ui.ParagraphBuilder(CkParagraphStyle(
        fontSize: fontSize,
      )).build();
      paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

      expect(paragraph.getLineMetricsAt(0), isNull);
      expect(paragraph.numberOfLines, 0);
      expect(paragraph.getLineNumberAt(0), isNull);
    });

    test('Basic line related metrics', () {
      const double fontSize = 10;
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(CkParagraphStyle(
        fontStyle: ui.FontStyle.normal,
        fontWeight: ui.FontWeight.normal,
        fontSize: fontSize,
        maxLines: 1,
        ellipsis: 'BBB',
      ))..addText('A' * 100);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 100.0));

      expect(paragraph.numberOfLines, 1);

      expect(paragraph.getLineMetricsAt(-1), isNull);
      expect(paragraph.getLineMetricsAt(0)?.lineNumber, 0);
      expect(paragraph.getLineMetricsAt(1), isNull);

      expect(paragraph.getLineNumberAt(-1), isNull);
      expect(paragraph.getLineNumberAt(0), 0);
      expect(paragraph.getLineNumberAt(6), 0);
      // The last 3 characters on the first line are ellipsized with BBB.
      expect(paragraph.getLineMetricsAt(7), isNull);
    });

    test('Basic glyph metrics', () {
      const double fontSize = 10;
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(CkParagraphStyle(
        fontStyle: ui.FontStyle.normal,
        fontWeight: ui.FontWeight.normal,
        fontFamily: 'FlutterTest',
        fontSize: fontSize,
        maxLines: 1,
        ellipsis: 'BBB',
      ))..addText('A' * 100);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 100.0));

      expect(paragraph.getGlyphInfoAt(-1), isNull);

      // The last 3 characters on the first line are ellipsized with BBB.
      expect(paragraph.getGlyphInfoAt(0)?.graphemeClusterCodeUnitRange, const ui.TextRange(start: 0, end: 1));
      expect(paragraph.getGlyphInfoAt(6)?.graphemeClusterCodeUnitRange, const ui.TextRange(start: 6, end: 7));
      expect(paragraph.getGlyphInfoAt(7), isNull);
      expect(paragraph.getGlyphInfoAt(200), isNull);
    });

    test('Basic glyph metrics - hit test', () {
      const double fontSize = 10.0;
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(CkParagraphStyle(
        fontSize: fontSize,
        fontFamily: 'FlutterTest',
      ))..addText('Test\nTest');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

      final ui.GlyphInfo? bottomRight = paragraph.getClosestGlyphInfoForOffset(const ui.Offset(99.0, 99.0));
      final ui.GlyphInfo? last = paragraph.getGlyphInfoAt(8);
      expect(bottomRight, equals(last));
      expect(bottomRight, isNot(paragraph.getGlyphInfoAt(0)));

      expect(bottomRight?.graphemeClusterLayoutBounds, const ui.Rect.fromLTWH(30, 10, 10, 10));
      expect(bottomRight?.graphemeClusterCodeUnitRange, const ui.TextRange(start: 8, end: 9));
      expect(bottomRight?.writingDirection, ui.TextDirection.ltr);
    });

    test('rounding hack disabled', () {
      const double fontSize = 1.25;
      const String text = '12345';
      assert((fontSize * text.length).truncate() != fontSize * text.length);
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: fontSize, fontFamily: 'FlutterTest'),
      );
      builder.addText(text);
      final ui.Paragraph paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: text.length * fontSize));

      expect(paragraph.maxIntrinsicWidth, text.length * fontSize);
      switch (paragraph.computeLineMetrics()) {
        case [ui.LineMetrics(width: final double width)]:
          expect(width, text.length * fontSize);
        case final List<ui.LineMetrics> metrics:
          expect(metrics, hasLength(1));
      }
    });

    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
  }, skip: isSafari || isFirefox);
}
