// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';
import 'package:ui/ui.dart' as ui;

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
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(3.0, 3.0),
          ),
          const ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(-3.0, 3.0),
          ),
          const ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(3.0, -3.0),
          ),
          const ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
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
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
