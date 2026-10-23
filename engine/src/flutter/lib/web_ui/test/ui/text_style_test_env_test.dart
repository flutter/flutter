// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
    setUpTestViewDimensions: false,
    testEnvironment: const ui_web.TestEnvironment.flutterTester(),
  );

  // Previously the logic that set the effective font family would forget the
  // original value and would print incorrect value in toString.
  test('TextStyle remembers original fontFamily value', () {
    final style1 = ui.TextStyle();
    expect(style1.toString(), contains('fontFamily: unspecified'));

    final style2 = ui.TextStyle(fontFamily: 'Hello');
    expect(style2.toString(), contains('fontFamily: Hello'));
  });

  test('ParagraphStyle remembers original fontFamily value', () {
    final style1 = ui.ParagraphStyle();
    expect(style1.toString(), contains('fontFamily: unspecified'));

    final style2 = ui.ParagraphStyle(fontFamily: 'Hello');
    expect(style2.toString(), contains('fontFamily: Hello'));
  });

  test('StrutStyle remembers original fontFamily value', () {
    final style1 = ui.StrutStyle();
    expect(style1.toString(), contains('fontFamily: unspecified'));

    final style2 = ui.StrutStyle(fontFamily: 'Hello');
    expect(style2.toString(), contains('fontFamily: Hello'));
  });

  group('test fonts in flutterTester environment', () {
    const testFonts = <String>['FlutterTest', 'Ahem'];
    final String defaultTestFontFamily = testFonts.first;

    test('The default test font is used when a non-test fontFamily is specified', () {
      final textStyle = EngineTextStyle(
        fontFamily: 'BogusFontFamily',
        fontFamilyFallback: const <String>['BogusFallback'],
      );
      expect(textStyle.effectiveFontFamily, defaultTestFontFamily);
      expect(textStyle.effectiveFontFamilyFallback, isNull);
      expect(textStyle.effectiveFontFamilies, testFonts);

      final EngineTextStyle paragraphTextStyle = EngineParagraphStyle(fontFamily: 'BogusFontFamily')
          .getTextStyle();
      expect(paragraphTextStyle.effectiveFontFamily, defaultTestFontFamily);
      expect(paragraphTextStyle.effectiveFontFamilies, testFonts);

      final strutStyle = EngineStrutStyle(
        fontFamily: 'BogusFontFamily',
        fontFamilyFallback: const <String>['BogusFallback'],
      );
      expect(strutStyle.effectiveFontFamily, defaultTestFontFamily);
      expect(strutStyle.effectiveFontFamilyFallback, isNull);
      expect(strutStyle.effectiveFontFamilies, testFonts);
      expect(
        ui.StrutStyle(fontFamily: 'BogusFontFamily'),
        isNot(ui.StrutStyle(fontFamily: defaultTestFontFamily)),
      );
    });

    test('The default test font is used when fontFamily is unspecified', () {
      expect(EngineTextStyle().effectiveFontFamily, defaultTestFontFamily);
      expect(EngineTextStyle().effectiveFontFamilies, testFonts);
      expect(EngineParagraphStyle().getTextStyle().effectiveFontFamily, defaultTestFontFamily);
      expect(EngineParagraphStyle().getTextStyle().effectiveFontFamilies, testFonts);
      expect(EngineStrutStyle().effectiveFontFamily, defaultTestFontFamily);
      expect(EngineStrutStyle().effectiveFontFamilies, testFonts);
    });

    test('Can specify test fontFamily to use', () {
      for (final testFont in testFonts) {
        expect(EngineTextStyle(fontFamily: testFont).effectiveFontFamily, testFont);
        expect(EngineTextStyle(fontFamily: testFont).effectiveFontFamilies, <String>[testFont]);
        expect(
          EngineParagraphStyle(fontFamily: testFont).getTextStyle().effectiveFontFamily,
          testFont,
        );
        expect(
          EngineParagraphStyle(fontFamily: testFont).getTextStyle().effectiveFontFamilies,
          <String>[testFont],
        );
        expect(EngineStrutStyle(fontFamily: testFont).effectiveFontFamily, testFont);
        expect(EngineStrutStyle(fontFamily: testFont).effectiveFontFamilies, <String>[testFont]);
      }
    });
  });
}
