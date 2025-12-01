// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('Text', () {
    setUpUnitTests();

    test("doesn't crash when using shadows", () {
      final textStyleWithShadows = ui.TextStyle(
        fontSize: 16,
        shadows: <ui.Shadow>[
          const ui.Shadow(blurRadius: 3.0, offset: ui.Offset(3.0, 3.0)),
          const ui.Shadow(blurRadius: 3.0, offset: ui.Offset(-3.0, 3.0)),
          const ui.Shadow(blurRadius: 3.0, offset: ui.Offset(3.0, -3.0)),
          const ui.Shadow(blurRadius: 3.0, offset: ui.Offset(-3.0, -3.0)),
        ],
        fontFamily: 'Roboto',
      );

      for (var i = 0; i < 10; i++) {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 16));
        builder.pushStyle(textStyleWithShadows);
        builder.addText('test');
        final ui.Paragraph paragraph = builder.build();
        expect(paragraph, isNotNull);
      }
    });

    // Regression test for https://github.com/flutter/flutter/issues/78550
    test('getBoxesForRange works for LTR text in an RTL paragraph', () {
      // Create builder for an RTL paragraph.
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 16, textDirection: ui.TextDirection.rtl),
      );
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
      // Skia renders a tofu if the font does not have a glyph for a
      // character. However, Flutter opts-in to a Skia feature to render
      // tabs as a single space.
      // See: https://github.com/flutter/flutter/issues/79153
      Future<ui.Image> drawText(String text) {
        const bounds = ui.Rect.fromLTRB(0, 0, 100, 100);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder, bounds);
        final ui.Paragraph paragraph = makeSimpleText(text);

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
    }, skip: isWimp || isSafari || isFirefox); // https://github.com/flutter/flutter/issues/175371
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
  }, skip: isSafari || isFirefox);
}

/// Creates a pre-laid out one-line paragraph of text.
///
/// Useful in tests that need a simple label to annotate goldens.
ui.Paragraph makeSimpleText(
  String text, {
  String? fontFamily,
  double? fontSize,
  ui.FontStyle? fontStyle,
  ui.FontWeight? fontWeight,
  ui.Color? color,
}) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontFamily: fontFamily ?? 'Roboto',
      fontSize: fontSize ?? 14,
      fontStyle: fontStyle ?? ui.FontStyle.normal,
      fontWeight: fontWeight ?? ui.FontWeight.normal,
    ),
  );
  builder.pushStyle(ui.TextStyle(color: color ?? const ui.Color(0xFF000000)));
  builder.addText(text);
  builder.pop();
  final ui.Paragraph paragraph = builder.build();
  paragraph.layout(const ui.ParagraphConstraints(width: 10000));
  return paragraph;
}
