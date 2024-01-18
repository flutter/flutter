// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
    emulateTesterEnvironment: false,
    setUpTestViewDimensions: false,
  );

  test('toString()', () {
    final ui.Paint paint = ui.Paint();
    paint.blendMode = ui.BlendMode.darken;
    paint.style = ui.PaintingStyle.fill;
    paint.strokeWidth = 1.2;
    paint.strokeCap = ui.StrokeCap.square;
    paint.strokeJoin = ui.StrokeJoin.bevel;
    paint.isAntiAlias = true;
    paint.color = const ui.Color(0xaabbccdd);
    paint.invertColors = true;
    paint.shader = ui.Gradient.linear(
      const ui.Offset(0.1, 0.2),
      const ui.Offset(1.5, 1.6),
      const <ui.Color>[
        ui.Color(0xaabbccdd),
        ui.Color(0xbbccddee),
      ],
      <double>[0.3, 0.4],
      ui.TileMode.decal,
    );
    paint.maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.7);
    paint.filterQuality = ui.FilterQuality.high;
    paint.colorFilter = const ui.ColorFilter.linearToSrgbGamma();
    paint.strokeMiterLimit = 1.8;
    paint.imageFilter = ui.ImageFilter.blur(
      sigmaX: 1.9,
      sigmaY: 2.1,
      tileMode: ui.TileMode.mirror,
    );

    if (!isSkwasm) {
      expect(
        paint.toString(),
        'Paint('
        'Color(0xaabbccdd); '
        'BlendMode.darken; '
        'colorFilter: ColorFilter.linearToSrgbGamma(); '
        'maskFilter: MaskFilter.blur(BlurStyle.normal, 1.7); '
        'filterQuality: FilterQuality.high; '
        'shader: Gradient(); '
        'imageFilter: ImageFilter.blur(1.9, 2.1, mirror); '
        'invert: true'
        ')',
      );
    } else {
      // TODO(yjbanov): https://github.com/flutter/flutter/issues/141639
      expect(paint.toString(), 'Paint()');
    }
  });
}
