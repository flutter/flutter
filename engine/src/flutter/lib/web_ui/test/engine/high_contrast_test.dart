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
    final color1 = parseCssRgb('rgb(12, 34, 56)');
    expect(color1, const ui.Color(0xff0c2238));

    final color2 = parseCssRgb('rgb(255, 0, 0)');
    expect(color2, const ui.Color(0xffff0000));

    final color3 = parseCssRgb('rgb(0, 255, 0)');
    expect(color3, const ui.Color(0xff00ff00));

    final color4 = parseCssRgb('rgb(0, 0, 255)');
    expect(color4, const ui.Color(0xff0000ff));

    final color5 = parseCssRgb('rgb(255,255,255)');
    expect(color5, const ui.Color(0xffffffff));

    final color6 = parseCssRgb('rgb(0,0,0)');
    expect(color6, const ui.Color(0xff000000));

    final color7 = parseCssRgb('  rgb( 10, 20 ,30 )  ');
    expect(color7, const ui.Color(0xff0a141e));

    // Invalid input:
    expect(parseCssRgb('rgb(256, 0, 0)'), isNull);
    expect(parseCssRgb('rgb(255, 0)'), isNull);
    expect(parseCssRgb('rgb255,0,0'), isNull);
  });

  test('parseCssColor(rgba)', () {
    final color1 = parseCssRgb('rgba(12, 34, 56, 0.5)');
    expect(color1?.toCssString(), const ui.Color.fromRGBO(12, 34, 56, 0.5).toCssString());

    final color2 = parseCssRgb('rgba(255, 0, 0, 0.0)');
    expect(color2, const ui.Color.fromRGBO(255, 0, 0, 0.0));

    final color3 = parseCssRgb('rgba(0, 255, 0, 1.0)');
    expect(color3, const ui.Color.fromRGBO(0, 255, 0, 1.0));

    final color4 = parseCssRgb('rgba(0, 0, 255, 0.7)');
    expect(color4, const ui.Color.fromRGBO(0, 0, 255, 0.7));

    final color5 = parseCssRgb('rgba(255,255,255,0.2)');
    expect(color5, const ui.Color.fromRGBO(255, 255, 255, 0.2));

    final color6 = parseCssRgb('rgba(0,0,0,1.0)');
    expect(color6, const ui.Color.fromRGBO(0, 0, 0, 1.0));

    final color7 = parseCssRgb('  rgba( 10, 20 ,30,     0.8 )  ');
    expect(color7, const ui.Color.fromRGBO(10, 20, 30, 0.8));

    // Invalid input:
    expect(parseCssRgb('rgba(256, 0, 0, 0.1)'), isNull);
    expect(parseCssRgb('rgba(255, 0, 0.1)'), isNull);
    expect(parseCssRgb('rgb255,0,0,0.1'), isNull);
    expect(parseCssRgb('rgba(12, 34, 56, -0.1)'), isNull);
    expect(parseCssRgb('rgba(12, 34, 56, 1.1)'), isNull);
  });

  test('ForcedColorPaletteDetector', () {
    final detector = SystemColorPaletteDetector();
    expect(detector.systemColors.keys, containsAll(ui.PlatformDispatcher.systemColorNames));

    expect(
      detector.systemColors.values.where((color) => color.isSupported),
      // Different browser/OS combinations support different colors. It's
      // impractical to encode the precise number for each combo. Instead, this
      // test only makes sure that at least some "reasonable" number of colors
      // were detected successfully. If the number is too low, it's a red flag.
      // Perhaps the parsing logic is flawed, or the logic that enumerates the
      // colors.
      hasLength(greaterThan(15)),
    );
  });
}
