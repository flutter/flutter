// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  group('CanvasKit API', () {
    setUpAll(() async {
      await ui.webOnlyInitializePlatform();
    });

    test('Using CanvasKit', () {
      expect(experimentalUseSkia, true);
    });

    _blendModeTests();
    _paintStyleTests();
    _strokeCapTests();
    _strokeJoinTests();
    _filterQualityTests();
    _blurStyleTests();
    _tileModeTests();
    _imageTests();
    _shaderTests();
    _paintTests();
    _maskFilterTests();
    _colorFilterTests();
    _imageFilterTests();
  },
      // This test failed on iOS Safari.
      // TODO: https://github.com/flutter/flutter/issues/60040
      skip: (browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs));
}

void _blendModeTests() {
  test('blend mode mapping is correct', () {
    expect(canvasKitJs.BlendMode.Clear.value, ui.BlendMode.clear.index);
    expect(canvasKitJs.BlendMode.Src.value, ui.BlendMode.src.index);
    expect(canvasKitJs.BlendMode.Dst.value, ui.BlendMode.dst.index);
    expect(canvasKitJs.BlendMode.SrcOver.value, ui.BlendMode.srcOver.index);
    expect(canvasKitJs.BlendMode.DstOver.value, ui.BlendMode.dstOver.index);
    expect(canvasKitJs.BlendMode.SrcIn.value, ui.BlendMode.srcIn.index);
    expect(canvasKitJs.BlendMode.DstIn.value, ui.BlendMode.dstIn.index);
    expect(canvasKitJs.BlendMode.SrcOut.value, ui.BlendMode.srcOut.index);
    expect(canvasKitJs.BlendMode.DstOut.value, ui.BlendMode.dstOut.index);
    expect(canvasKitJs.BlendMode.SrcATop.value, ui.BlendMode.srcATop.index);
    expect(canvasKitJs.BlendMode.DstATop.value, ui.BlendMode.dstATop.index);
    expect(canvasKitJs.BlendMode.Xor.value, ui.BlendMode.xor.index);
    expect(canvasKitJs.BlendMode.Plus.value, ui.BlendMode.plus.index);
    expect(canvasKitJs.BlendMode.Modulate.value, ui.BlendMode.modulate.index);
    expect(canvasKitJs.BlendMode.Screen.value, ui.BlendMode.screen.index);
    expect(canvasKitJs.BlendMode.Overlay.value, ui.BlendMode.overlay.index);
    expect(canvasKitJs.BlendMode.Darken.value, ui.BlendMode.darken.index);
    expect(canvasKitJs.BlendMode.Lighten.value, ui.BlendMode.lighten.index);
    expect(canvasKitJs.BlendMode.ColorDodge.value, ui.BlendMode.colorDodge.index);
    expect(canvasKitJs.BlendMode.ColorBurn.value, ui.BlendMode.colorBurn.index);
    expect(canvasKitJs.BlendMode.HardLight.value, ui.BlendMode.hardLight.index);
    expect(canvasKitJs.BlendMode.SoftLight.value, ui.BlendMode.softLight.index);
    expect(canvasKitJs.BlendMode.Difference.value, ui.BlendMode.difference.index);
    expect(canvasKitJs.BlendMode.Exclusion.value, ui.BlendMode.exclusion.index);
    expect(canvasKitJs.BlendMode.Multiply.value, ui.BlendMode.multiply.index);
    expect(canvasKitJs.BlendMode.Hue.value, ui.BlendMode.hue.index);
    expect(canvasKitJs.BlendMode.Saturation.value, ui.BlendMode.saturation.index);
    expect(canvasKitJs.BlendMode.Color.value, ui.BlendMode.color.index);
    expect(canvasKitJs.BlendMode.Luminosity.value, ui.BlendMode.luminosity.index);
  });

  test('ui.BlendMode converts to SkBlendMode', () {
    for (ui.BlendMode blendMode in ui.BlendMode.values) {
      expect(toSkBlendMode(blendMode).value, blendMode.index);
    }
  });
}

void _paintStyleTests() {
  test('paint style mapping is correct', () {
    expect(canvasKitJs.PaintStyle.Fill.value, ui.PaintingStyle.fill.index);
    expect(canvasKitJs.PaintStyle.Stroke.value, ui.PaintingStyle.stroke.index);
  });

  test('ui.PaintingStyle converts to SkPaintStyle', () {
    for (ui.PaintingStyle style in ui.PaintingStyle.values) {
      expect(toSkPaintStyle(style).value, style.index);
    }
  });
}

void _strokeCapTests() {
  test('stroke cap mapping is correct', () {
    expect(canvasKitJs.StrokeCap.Butt.value, ui.StrokeCap.butt.index);
    expect(canvasKitJs.StrokeCap.Round.value, ui.StrokeCap.round.index);
    expect(canvasKitJs.StrokeCap.Square.value, ui.StrokeCap.square.index);
  });

  test('ui.StrokeCap converts to SkStrokeCap', () {
    for (ui.StrokeCap cap in ui.StrokeCap.values) {
      expect(toSkStrokeCap(cap).value, cap.index);
    }
  });
}

void _strokeJoinTests() {
  test('stroke cap mapping is correct', () {
    expect(canvasKitJs.StrokeJoin.Miter.value, ui.StrokeJoin.miter.index);
    expect(canvasKitJs.StrokeJoin.Round.value, ui.StrokeJoin.round.index);
    expect(canvasKitJs.StrokeJoin.Bevel.value, ui.StrokeJoin.bevel.index);
  });

  test('ui.StrokeJoin converts to SkStrokeJoin', () {
    for (ui.StrokeJoin join in ui.StrokeJoin.values) {
      expect(toSkStrokeJoin(join).value, join.index);
    }
  });
}

void _filterQualityTests() {
  test('filter quality mapping is correct', () {
    expect(canvasKitJs.FilterQuality.None.value, ui.FilterQuality.none.index);
    expect(canvasKitJs.FilterQuality.Low.value, ui.FilterQuality.low.index);
    expect(canvasKitJs.FilterQuality.Medium.value, ui.FilterQuality.medium.index);
    expect(canvasKitJs.FilterQuality.High.value, ui.FilterQuality.high.index);
  });

  test('ui.FilterQuality converts to SkFilterQuality', () {
    for (ui.FilterQuality cap in ui.FilterQuality.values) {
      expect(toSkFilterQuality(cap).value, cap.index);
    }
  });
}

void _blurStyleTests() {
  test('blur style mapping is correct', () {
    expect(canvasKitJs.BlurStyle.Normal.value, ui.BlurStyle.normal.index);
    expect(canvasKitJs.BlurStyle.Solid.value, ui.BlurStyle.solid.index);
    expect(canvasKitJs.BlurStyle.Outer.value, ui.BlurStyle.outer.index);
    expect(canvasKitJs.BlurStyle.Inner.value, ui.BlurStyle.inner.index);
  });

  test('ui.BlurStyle converts to SkBlurStyle', () {
    for (ui.BlurStyle style in ui.BlurStyle.values) {
      expect(toSkBlurStyle(style).value, style.index);
    }
  });
}

void _tileModeTests() {
  test('tile mode mapping is correct', () {
    expect(canvasKitJs.TileMode.Clamp.value, ui.TileMode.clamp.index);
    expect(canvasKitJs.TileMode.Repeat.value, ui.TileMode.repeated.index);
    expect(canvasKitJs.TileMode.Mirror.value, ui.TileMode.mirror.index);
  });

  test('ui.TileMode converts to SkTileMode', () {
    for (ui.TileMode mode in ui.TileMode.values) {
      expect(toSkTileMode(mode).value, mode.index);
    }
  });
}

void _imageTests() {
  test('MakeAnimatedImageFromEncoded makes a non-animated image', () {
    final SkAnimatedImage nonAnimated = canvasKitJs.MakeAnimatedImageFromEncoded(kTransparentImage);
    expect(nonAnimated.getFrameCount(), 1);
    expect(nonAnimated.getRepetitionCount(), 0);
    expect(nonAnimated.width(), 1);
    expect(nonAnimated.height(), 1);

    final SkImage frame = nonAnimated.getCurrentFrame();
    expect(frame.width(), 1);
    expect(frame.height(), 1);

    expect(nonAnimated.decodeNextFrame(), -1);
    expect(frame.makeShader(canvasKitJs.TileMode.Repeat, canvasKitJs.TileMode.Mirror), isNotNull);
  });

  test('MakeAnimatedImageFromEncoded makes an animated image', () {
    final SkAnimatedImage animated = canvasKitJs.MakeAnimatedImageFromEncoded(kAnimatedGif);
    expect(animated.getFrameCount(), 3);
    expect(animated.getRepetitionCount(), -1);  // animates forever
    expect(animated.width(), 1);
    expect(animated.height(), 1);
    for (int i = 0; i < 100; i++) {
      final SkImage frame = animated.getCurrentFrame();
      expect(frame.width(), 1);
      expect(frame.height(), 1);
      expect(animated.decodeNextFrame(), 100);
    }
  });
}

void _shaderTests() {
  test('MakeLinearGradient', () {
    expect(_makeTestShader(), isNotNull);
  });

  test('MakeRadialGradient', () {
    expect(canvasKitJs.SkShader.MakeRadialGradient(
      Float32List.fromList([1, 1]),
      10.0,
      <Float32List>[
        Float32List.fromList([0, 0, 0, 1]),
        Float32List.fromList([1, 1, 1, 1]),
      ],
      Float32List.fromList([0, 1]),
      canvasKitJs.TileMode.Repeat,
      toSkMatrixFromFloat32(Matrix4.identity().storage),
      0,
    ), isNotNull);
  });

  test('MakeTwoPointConicalGradient', () {
    expect(canvasKitJs.SkShader.MakeTwoPointConicalGradient(
      Float32List.fromList([1, 1]),
      10.0,
      Float32List.fromList([1, 1]),
      10.0,
      <Float32List>[
        Float32List.fromList([0, 0, 0, 1]),
        Float32List.fromList([1, 1, 1, 1]),
      ],
      Float32List.fromList([0, 1]),
      canvasKitJs.TileMode.Repeat,
      toSkMatrixFromFloat32(Matrix4.identity().storage),
      0,
    ), isNotNull);
  });
}

SkShader _makeTestShader() {
  return canvasKitJs.SkShader.MakeLinearGradient(
    Float32List.fromList([0, 0]),
    Float32List.fromList([1, 1]),
    <Float32List>[
      Float32List.fromList([0, 0, 0, 1]),
      Float32List.fromList([1, 1, 1, 1]),
    ],
    Float32List.fromList([0, 1]),
    canvasKitJs.TileMode.Repeat,
  );
}

void _paintTests() {
  test('can make SkPaint', () async {
    final SkPaint paint = SkPaint();
    paint.setBlendMode(canvasKitJs.BlendMode.SrcOut);
    paint.setStyle(canvasKitJs.PaintStyle.Stroke);
    paint.setStrokeWidth(3.0);
    paint.setStrokeCap(canvasKitJs.StrokeCap.Round);
    paint.setStrokeJoin(canvasKitJs.StrokeJoin.Bevel);
    paint.setAntiAlias(true);
    paint.setColorInt(0x00FFCCAA);
    paint.setShader(_makeTestShader());
    // TODO(yjbanov): paint.setMaskFilter
    paint.setFilterQuality(canvasKitJs.FilterQuality.High);
    // TODO(yjbanov): paint.setColorFilter
    paint.setStrokeMiter(1.4);
    // TODO(yjbanov): paint.setImageFilter
  });
}

void _maskFilterTests() {
  test('MakeBlurMaskFilter', () {
    expect(canvasKitJs.MakeBlurMaskFilter(
      canvasKitJs.BlurStyle.Outer,
      5.0,
      false,
    ), isNotNull);
  });
}

void _colorFilterTests() {
  test('MakeBlend', () {
    expect(
      canvasKitJs.SkColorFilter.MakeBlend(
        Float32List.fromList([0, 0, 0, 1]),
        canvasKitJs.BlendMode.SrcATop,
      ),
      isNotNull,
    );
  });

  test('MakeMatrix', () {
    expect(
      canvasKitJs.SkColorFilter.MakeMatrix(
        Float32List(20),
      ),
      isNotNull,
    );
  });

  test('MakeSRGBToLinearGamma', () {
    expect(
      canvasKitJs.SkColorFilter.MakeSRGBToLinearGamma(),
      isNotNull,
    );
  });

  test('MakeLinearToSRGBGamma', () {
    expect(
      canvasKitJs.SkColorFilter.MakeLinearToSRGBGamma(),
      isNotNull,
    );
  });
}

void _imageFilterTests() {
  test('MakeBlur', () {
    expect(
      canvasKitJs.SkImageFilter.MakeBlur(1, 2, canvasKitJs.TileMode.Repeat, null),
      isNotNull,
    );
  });

  test('MakeMatrixTransform', () {
    expect(
      canvasKitJs.SkImageFilter.MakeMatrixTransform(
        toSkMatrixFromFloat32(Matrix4.identity().storage),
        canvasKitJs.FilterQuality.Medium,
        null,
      ),
      isNotNull,
    );
  });
}

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
]);

/// An animated GIF image with 3 1x1 pixel frames (a red, green, and blue
/// frames). The GIF animates forever, and each frame has a 100ms delay.
final Uint8List kAnimatedGif = Uint8List.fromList(<int> [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0xa1, 0x03, 0x00,
  0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00, 0xff, 0x00, 0xff, 0xff, 0xff, 0x21,
  0xff, 0x0b, 0x4e, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2e, 0x30,
  0x03, 0x01, 0x00, 0x00, 0x00, 0x21, 0xf9, 0x04, 0x00, 0x0a, 0x00, 0xff, 0x00,
  0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x4c,
  0x01, 0x00, 0x21, 0xf9, 0x04, 0x00, 0x0a, 0x00, 0xff, 0x00, 0x2c, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x54, 0x01, 0x00, 0x21,
  0xf9, 0x04, 0x00, 0x0a, 0x00, 0xff, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01,
  0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b,
]);
