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
        expect(EngineTextStyle(fontFamily: 'BogusFontFamily').effectiveFontFamilies, testFonts);
        expect(
          const EngineParagraphStyle(fontFamily: 'BogusFontFamily')
              .getTextStyle()
              .effectiveFontFamilies,
          testFonts,
        );
        expect(
          const EngineStrutStyle(fontFamily: 'BogusFontFamily').effectiveFontFamilies,
          testFonts,
        );
        expect(
          ui.StrutStyle(fontFamily: 'BogusFontFamily'),
          isNot(ui.StrutStyle(fontFamily: testFonts.first)),
        );
      });

      test('The default test font is used when fontFamily is unspecified', () {
        expect(EngineTextStyle().effectiveFontFamilies, testFonts);
        expect(const EngineParagraphStyle().getTextStyle().effectiveFontFamilies, testFonts);
        expect(const EngineStrutStyle().effectiveFontFamilies, testFonts);
      });

      test('Can specify test fontFamily to use', () {
        for (final testFont in testFonts) {
          expect(EngineTextStyle(fontFamily: testFont).effectiveFontFamilies, <String>[testFont]);
          expect(
            EngineParagraphStyle(fontFamily: testFont).getTextStyle().effectiveFontFamilies,
            <String>[testFont],
          );
          expect(EngineStrutStyle(fontFamily: testFont).effectiveFontFamilies, <String>[testFont]);
        }
      });
    });

    test('effectiveFontFamilies deduplicates fontFamilyFallback against fontFamily', () {
      expect(
        EngineTextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: const <String>['Roboto', 'Noto Sans'],
        ).effectiveFontFamilies,
        const <String>['Roboto', 'Noto Sans'],
      );
      expect(
        const EngineStrutStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: <String>['Roboto'],
        ).effectiveFontFamilies,
        const <String>['Roboto'],
      );
    });
  });
}
