// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kDefaultRegion = ui.Rect.fromLTRB(0, 0, 500, 250);

void testMain() {
  group('flutter_tester emulation', () {
    setUpUnitTests(
      withImplicitView: true,
      setUpTestViewDimensions: false,
      testEnvironment: const ui_web.TestEnvironment.flutterTester(),
    );

    test('defaults to FlutterTest font family', () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, kDefaultRegion);
      canvas.translate(10, 10);

      void drawTextWithOutline(
        String text, {
        String? paragraphFontFamily,
        String? textFontFamily,
        List<String>? textFontFallbacks,
        String? strutStyleFontFamily,
        List<String>? strutStyleFontFallbacks,
        double? strutStyleFontSize,
      }) {
        final ui.StrutStyle? strutStyle;

        if (strutStyleFontFamily != null ||
            strutStyleFontFallbacks != null ||
            strutStyleFontSize != null) {
          strutStyle = ui.StrutStyle(
            fontFamily: strutStyleFontFamily,
            fontFamilyFallback: strutStyleFontFallbacks,
            fontSize: strutStyleFontSize,
          );
        } else {
          strutStyle = null;
        }

        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontFamily: paragraphFontFamily, strutStyle: strutStyle),
        );

        final bool needsTextStyle = textFontFamily != null || textFontFallbacks != null;

        if (needsTextStyle) {
          builder.pushStyle(
            ui.TextStyle(fontFamily: textFontFamily, fontFamilyFallback: textFontFallbacks),
          );
        }

        builder.addText(text);

        if (needsTextStyle) {
          builder.pop();
        }

        final ui.Paragraph paragraph = builder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 10000));
        canvas.drawParagraph(paragraph, ui.Offset.zero);
        canvas.drawRect(
          ui.Rect.fromLTWH(-4, -4, paragraph.maxIntrinsicWidth + 8, paragraph.height + 8),
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        canvas.translate(0, paragraph.height + 16);
      }

      drawTextWithOutline('default');
      drawTextWithOutline('roboto paragraph', paragraphFontFamily: 'Roboto');
      drawTextWithOutline('roboto text', textFontFamily: 'Roboto');
      drawTextWithOutline('roboto text fallback', textFontFallbacks: <String>['Roboto']);
      drawTextWithOutline(
        'roboto strut style',
        strutStyleFontFamily: 'Roboto',
        strutStyleFontSize: 40,
      );
      drawTextWithOutline(
        'roboto strut style fallback',
        strutStyleFontFallbacks: <String>['Roboto'],
        strutStyleFontSize: 40,
      );

      await drawPictureUsingCurrentRenderer(recorder.endRecording());
      await matchGoldenFile('ui_flutter_tester_emulation.png', region: kDefaultRegion);
    });
    // TODO(yjbanov): https://github.com/flutter/flutter/issues/71520
  }, skip: isSafari || isFirefox);
}
