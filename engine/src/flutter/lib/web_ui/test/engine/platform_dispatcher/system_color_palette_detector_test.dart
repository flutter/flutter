// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('parseCssColor(rgb)', () {
    final ui.Color? color1 = parseCssRgb('rgb(12, 34, 56)');
    expect(color1, const ui.Color(0xff0c2238));

    final ui.Color? color2 = parseCssRgb('rgb(255, 0, 0)');
    expect(color2, const ui.Color(0xffff0000));

    final ui.Color? color3 = parseCssRgb('rgb(0, 255, 0)');
    expect(color3, const ui.Color(0xff00ff00));

    final ui.Color? color4 = parseCssRgb('rgb(0, 0, 255)');
    expect(color4, const ui.Color(0xff0000ff));

    final ui.Color? color5 = parseCssRgb('rgb(255,255,255)');
    expect(color5, const ui.Color(0xffffffff));

    final ui.Color? color6 = parseCssRgb('rgb(0,0,0)');
    expect(color6, const ui.Color(0xff000000));

    final ui.Color? color7 = parseCssRgb('  rgb( 10, 20 ,30 )  ');
    expect(color7, const ui.Color(0xff0a141e));

    // Invalid input:
    expect(parseCssRgb('rgb(256, 0, 0)'), isNull);
    expect(parseCssRgb('rgb(255, 0)'), isNull);
    expect(parseCssRgb('rgb255,0,0'), isNull);
  });

  test('parseCssColor(rgba)', () {
    final ui.Color? color1 = parseCssRgb('rgba(12, 34, 56, 0.5)');
    expect(color1?.toCssString(), const ui.Color.fromRGBO(12, 34, 56, 0.5).toCssString());

    final ui.Color? color2 = parseCssRgb('rgba(255, 0, 0, 0.0)');
    expect(color2, const ui.Color.fromRGBO(255, 0, 0, 0.0));

    final ui.Color? color3 = parseCssRgb('rgba(0, 255, 0, 1.0)');
    expect(color3, const ui.Color.fromRGBO(0, 255, 0, 1.0));

    final ui.Color? color4 = parseCssRgb('rgba(0, 0, 255, 0.7)');
    expect(color4, const ui.Color.fromRGBO(0, 0, 255, 0.7));

    final ui.Color? color5 = parseCssRgb('rgba(255,255,255,0.2)');
    expect(color5, const ui.Color.fromRGBO(255, 255, 255, 0.2));

    final ui.Color? color6 = parseCssRgb('rgba(0,0,0,1.0)');
    expect(color6, const ui.Color.fromRGBO(0, 0, 0, 1.0));

    final ui.Color? color7 = parseCssRgb('  rgba( 10, 20 ,30,     0.8 )  ');
    expect(color7, const ui.Color.fromRGBO(10, 20, 30, 0.8));

    // Invalid input:
    expect(parseCssRgb('rgba(256, 0, 0, 0.1)'), isNull);
    expect(parseCssRgb('rgba(255, 0, 0.1)'), isNull);
    expect(parseCssRgb('rgb255,0,0,0.1'), isNull);
    expect(parseCssRgb('rgba(12, 34, 56, -0.1)'), isNull);
    expect(parseCssRgb('rgba(12, 34, 56, 1.1)'), isNull);
  });

  test('ForcedColorPaletteDetector', () {
    const systemColorNames = <String>[
      'AccentColor',
      'AccentColorText',
      'ActiveText',
      'ButtonBorder',
      'ButtonFace',
      'ButtonText',
      'Canvas',
      'CanvasText',
      'Field',
      'FieldText',
      'GrayText',
      'Highlight',
      'HighlightText',
      'LinkText',
      'Mark',
      'MarkText',
      'SelectedItem',
      'SelectedItemText',
      'VisitedText',
    ];

    final detectorLight = SystemColorPaletteDetector(ui.Brightness.light);
    expect(detectorLight.systemColors.keys, containsAll(systemColorNames));

    final detectorDark = SystemColorPaletteDetector(ui.Brightness.dark);
    expect(detectorDark.systemColors.keys, containsAll(systemColorNames));

    expect(
      detectorLight.systemColors.values.where((color) => color.isSupported),
      // Different browser/OS combinations support different colors. It's
      // impractical to encode the precise number for each combo. Instead, this
      // test only makes sure that at least some "reasonable" number of colors
      // were detected successfully. If the number is too low, it's a red flag.
      // Perhaps the parsing logic is flawed, or the logic that enumerates the
      // colors.
      hasLength(greaterThan(15)),
    );
    expect(
      detectorDark.systemColors.values.where((color) => color.isSupported),
      hasLength(greaterThan(15)),
    );

    // Ensure that at least some colors are different between light and dark mode.
    var differentCount = 0;
    for (final colorName in systemColorNames) {
      final ui.SystemColor? lightColor = detectorLight.systemColors[colorName];
      final ui.SystemColor? darkColor = detectorDark.systemColors[colorName];
      if (lightColor != null &&
          darkColor != null &&
          lightColor.isSupported &&
          darkColor.isSupported &&
          lightColor.value != darkColor.value) {
        differentCount++;
      }
    }
    // The number 3 has no special meaning. It's just to ensure that "some" colors are different.
    expect(differentCount, greaterThan(3));
  });

  test('SystemColor', () {
    const supportedColor = ui.SystemColor(
      name: 'SupportedColor',
      value: ui.Color.fromRGBO(1, 2, 3, 0.5),
    );
    expect(supportedColor.name, 'SupportedColor');
    expect(supportedColor.value, isNotNull);
    expect(supportedColor.isSupported, isTrue);

    const unsupportedColor = ui.SystemColor(name: 'UnsupportedColor');
    expect(unsupportedColor.name, 'UnsupportedColor');
    expect(unsupportedColor.value, isNull);
    expect(unsupportedColor.isSupported, isFalse);
  });

  group('SystemColorPalette', () {
    test('.light', () {
      testPalette(ui.SystemColor.light);
    });

    test('.dark', () {
      testPalette(ui.SystemColor.dark);
    });
  });
}

void testPalette(ui.SystemColorPalette palette) {
  expect(palette.accentColor.name, 'AccentColor');
  expect(palette.accentColorText.name, 'AccentColorText');
  expect(palette.activeText.name, 'ActiveText');
  expect(palette.buttonBorder.name, 'ButtonBorder');
  expect(palette.buttonFace.name, 'ButtonFace');
  expect(palette.buttonText.name, 'ButtonText');
  expect(palette.canvas.name, 'Canvas');
  expect(palette.canvasText.name, 'CanvasText');
  expect(palette.field.name, 'Field');
  expect(palette.fieldText.name, 'FieldText');
  expect(palette.grayText.name, 'GrayText');
  expect(palette.highlight.name, 'Highlight');
  expect(palette.highlightText.name, 'HighlightText');
  expect(palette.linkText.name, 'LinkText');
  expect(palette.mark.name, 'Mark');
  expect(palette.markText.name, 'MarkText');
  expect(palette.selectedItem.name, 'SelectedItem');
  expect(palette.selectedItemText.name, 'SelectedItemText');
  expect(palette.visitedText.name, 'VisitedText');

  final allColors = <ui.SystemColor>[
    palette.accentColor,
    palette.accentColorText,
    palette.activeText,
    palette.buttonBorder,
    palette.buttonFace,
    palette.buttonText,
    palette.canvas,
    palette.canvasText,
    palette.field,
    palette.fieldText,
    palette.grayText,
    palette.highlight,
    palette.highlightText,
    palette.linkText,
    palette.mark,
    palette.markText,
    palette.selectedItem,
    palette.selectedItemText,
    palette.visitedText,
  ];

  for (final color in allColors) {
    expect(color.value != null, color.isSupported);
  }
}
