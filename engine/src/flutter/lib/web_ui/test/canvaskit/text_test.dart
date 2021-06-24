// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
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
          ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(3.0, 3.0),
          ),
          ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(-3.0, 3.0),
          ),
          ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(3.0, -3.0),
          ),
          ui.Shadow(
            color: ui.Color.fromARGB(255, 0, 0, 0),
            blurRadius: 3.0,
            offset: ui.Offset(-3.0, -3.0),
          ),
        ],
        fontFamily: 'Roboto',
      );

      for (int i = 0; i < 10; i++) {
        ui.ParagraphBuilder builder =
            ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 16));
        builder.pushStyle(textStyleWithShadows);
        builder.addText('test');
        final ui.Paragraph paragraph = builder.build();
        expect(paragraph, isNotNull);
      }
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
