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
  group('Text', () {
    setUpCanvasKitTest();
    group('test fonts in flutterTester environment', () {
      setUpAll(() {
        ui_web.TestEnvironment.setUp(const ui_web.TestEnvironment.flutterTester());
      });
      tearDownAll(() {
        ui_web.TestEnvironment.tearDown();
      });
      const testFonts = <String>['FlutterTest', 'Ahem'];

      test('The default test font is used when a non-test fontFamily is specified', () {
        final String defaultTestFontFamily = testFonts.first;

        expect(
          EngineTextStyle(fontFamily: 'BogusFontFamily').effectiveFontFamily,
          defaultTestFontFamily,
        );
        expect(
          EngineParagraphStyle(fontFamily: 'BogusFontFamily').getTextStyle().effectiveFontFamily,
          defaultTestFontFamily,
        );
        expect(
          EngineStrutStyle(fontFamily: 'BogusFontFamily').effectiveFontFamily,
          defaultTestFontFamily,
        );
        expect(
          ui.StrutStyle(fontFamily: 'BogusFontFamily'),
          isNot(ui.StrutStyle(fontFamily: defaultTestFontFamily)),
        );
      });

      test('The default test font is used when fontFamily is unspecified', () {
        final String defaultTestFontFamily = testFonts.first;

        expect(EngineTextStyle().effectiveFontFamily, defaultTestFontFamily);
        expect(EngineParagraphStyle().getTextStyle().effectiveFontFamily, defaultTestFontFamily);
        expect(EngineStrutStyle().effectiveFontFamily, defaultTestFontFamily);
      });

      test('Can specify test fontFamily to use', () {
        for (final testFont in testFonts) {
          expect(EngineTextStyle(fontFamily: testFont).effectiveFontFamily, testFont);
          expect(
            EngineParagraphStyle(fontFamily: testFont).getTextStyle().effectiveFontFamily,
            testFont,
          );
          expect(EngineStrutStyle(fontFamily: testFont).effectiveFontFamily, testFont);
        }
      });
    });
  });
}
