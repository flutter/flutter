// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Color _green = ui.Color(0xFF00FF00);
const ui.Color _red = ui.Color(0xFFFF0000);
const ui.Color _white = ui.Color(0xFFFFFFFF);

/// Pixel values as read back from `toByteData`, packed as 0xRRGGBBAA.
const int _greenPixel = 0x00FF00FF;
const int _redPixel = 0xFF0000FF;
const int _whitePixel = 0xFFFFFFFF;
const int _bluePixel = 0x0000FFFF;

/// Renders [picture] to a [width]x[height] image and returns the RGBA pixel at
/// each of [points], packed as 0xRRGGBBAA.
Future<List<int>> _readPixels(
  ui.Picture picture,
  int width,
  int height,
  List<(int, int)> points,
) async {
  final ui.Image image = await picture.toImage(width, height);
  final ByteData data = (await image.toByteData())!;
  image.dispose();
  picture.dispose();
  return <int>[for (final (int x, int y) in points) data.getUint32((y * width + x) * 4)];
}

/// Creates an [EngineColorFilter] that is a distinct instance from any const
/// filter used elsewhere, so no backend state is shared with other tests.
EngineColorFilter _freshColorFilter(ui.Color color) =>
    // ignore: prefer_const_constructors
    ui.ColorFilter.mode(color, ui.BlendMode.srcIn) as EngineColorFilter;

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  test('ui.Paint creates an EnginePaint', () {
    final paint = ui.Paint()..color = _green;
    expect(paint, isA<EnginePaint>());
    expect(
      ui.Paint.from(paint),
      isA<EnginePaint>().having((p) => p.colorValue, 'colorValue', 0xFF00FF00),
    );
  });

  test('backend getters reflect the fields that were set', () {
    final defaults = EnginePaint();
    expect(defaults.colorValue, 0xFF000000);
    expect(defaults.engineColorFilter, isNull);
    expect(defaults.engineShader, isNull);
    expect(defaults.effectiveMaskFilter, isNull);
    expect(defaults.effectiveImageFilter, isNull);

    final EngineColorFilter colorFilter = _freshColorFilter(_green);
    final shader = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(10, 0), const <ui.Color>[
      _red,
      _green,
    ]);
    final paint = EnginePaint()
      ..color = const ui.Color(0xAABBCCDD)
      ..colorFilter = colorFilter
      ..shader = shader;
    expect(paint.colorValue, 0xAABBCCDD);
    expect(paint.engineColorFilter, same(colorFilter));
    expect(paint.engineShader, same(shader));
  });

  test('createBackendPaint returns a new paint on every call', () {
    final paint = EnginePaint()..color = _green;
    final BackendPaint first = paint.createBackendPaint();
    final BackendPaint second = paint.createBackendPaint(defaultBlurTileMode: ui.TileMode.clamp);
    expect(second, isNot(same(first)));

    first.dispose();
    second.dispose();
    // Disposing again is a no-op.
    expect(first.dispose, returnsNormally);
    expect(second.dispose, returnsNormally);
  });

  test('effectiveMaskFilter is only set for a finite positive blur sigma', () async {
    const cases = <({double sigma, bool blurs})>[
      (sigma: 0, blurs: false),
      (sigma: -1, blurs: false),
      (sigma: double.infinity, blurs: false),
      (sigma: 5, blurs: true),
    ];
    for (final (:double sigma, :bool blurs) in cases) {
      final maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma);
      final paint = EnginePaint()
        ..color = const ui.Color(0xFF0000FF)
        ..maskFilter = maskFilter;
      expect(paint.effectiveMaskFilter, blurs ? same(maskFilter) : isNull, reason: 'sigma $sigma');

      // A 20x20 rect in the middle of a 40x40 image. Without a blur, the
      // center is exactly the paint color and 5px outside the rect is empty.
      final List<int> pixels = await _readPixels(
        drawPicture((ui.Canvas canvas) {
          canvas.drawRect(const ui.Rect.fromLTRB(10, 10, 30, 30), paint);
        }),
        40,
        40,
        <(int, int)>[(20, 20), (5, 20)],
      );
      if (blurs) {
        expect(pixels[1] & 0xFF, greaterThan(0), reason: 'sigma $sigma blurs outside the rect');
      } else {
        expect(pixels, <int>[_bluePixel, 0x00000000], reason: 'sigma $sigma draws a sharp rect');
      }
    }
  });

  test('a ColorFilter used as imageFilter is applied when drawing', () async {
    final List<int> pixels = await _readPixels(
      drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
          const ui.Rect.fromLTRB(0, 0, 20, 20),
          ui.Paint()
            ..color = _white
            ..imageFilter = _freshColorFilter(_green),
        );
      }),
      20,
      20,
      <(int, int)>[(10, 10)],
    );
    expect(pixels, <int>[_greenPixel]);
  });

  test('effectiveImageFilter follows imageFilter and is cached between changes', () {
    final paint = EnginePaint();
    expect(paint.effectiveImageFilter, isNull);

    final blur = ui.ImageFilter.blur(sigmaX: 2, sigmaY: 3);
    paint.imageFilter = blur;
    expect(paint.effectiveImageFilter, same(blur));

    final EngineColorFilter green = _freshColorFilter(_green);
    paint.imageFilter = green;
    final EngineImageFilter? wrapped = paint.effectiveImageFilter;
    expect(
      wrapped,
      isA<EngineColorFilterImageFilter>().having((f) => f.colorFilter, 'colorFilter', same(green)),
    );
    expect(paint.effectiveImageFilter, same(wrapped));

    // Setting the same filter, or an equal one, keeps the cached wrapper.
    paint.imageFilter = green;
    expect(paint.effectiveImageFilter, same(wrapped));
    paint.imageFilter = _freshColorFilter(_green);
    expect(paint.effectiveImageFilter, same(wrapped));

    final EngineColorFilter red = _freshColorFilter(_red);
    paint.imageFilter = red;
    expect(
      paint.effectiveImageFilter,
      isA<EngineColorFilterImageFilter>().having((f) => f.colorFilter, 'colorFilter', same(red)),
    );

    paint.imageFilter = null;
    expect(paint.effectiveImageFilter, isNull);
  });

  test(
    'ColorFilter image filter wrappers for one ColorFilter share a live backend filter',
    () async {
      final EngineColorFilter colorFilter = _freshColorFilter(_green);
      BackendImageFilter backendFilterOfNewWrapper() =>
          EngineColorFilterImageFilter(colorFilter: colorFilter)
              .getBackendFilter(defaultBlurTileMode: ui.TileMode.decal);

      final BackendImageFilter first = backendFilterOfNewWrapper();
      final BackendImageFilter second = backendFilterOfNewWrapper();
      expect(second, same(first));
      const bounds = ui.Rect.fromLTWH(1, 2, 3, 4);
      expect(second.filterBounds(bounds), bounds);

      // The shared backend filter still draws after the wrappers are gone.
      final List<int> pixels = await _readPixels(
        drawPicture((ui.Canvas canvas) {
          canvas.drawRect(
            const ui.Rect.fromLTRB(0, 0, 20, 20),
            ui.Paint()
              ..color = _white
              ..imageFilter = colorFilter,
          );
        }),
        20,
        20,
        <(int, int)>[(10, 10)],
      );
      expect(pixels, <int>[_greenPixel]);
    },
  );

  test('paragraph styles with only a foreground or only a background paint draw both', () async {
    final cases = <({String name, ui.TextStyle style, int glyph, int space})>[
      (
        name: 'background only',
        style: ui.TextStyle(color: _green, background: ui.Paint()..color = _red),
        glyph: _greenPixel,
        space: _redPixel,
      ),
      (
        name: 'foreground only',
        style: ui.TextStyle(foreground: ui.Paint()..color = _green),
        glyph: _greenPixel,
        space: _whitePixel,
      ),
    ];
    for (final (:String name, :ui.TextStyle style, :int glyph, :int space) in cases) {
      final builder =
          ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Ahem', fontSize: 20))
            ..pushStyle(style)
            ..addText('A A');
      final ui.Paragraph paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 100));

      // Ahem glyphs are 20x20 squares, so 'A A' covers x 0..60, y 0..20.
      final List<int> pixels = await _readPixels(
        drawPicture((ui.Canvas canvas) {
          canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 60, 20), ui.Paint()..color = _white);
          canvas.drawParagraph(paragraph, ui.Offset.zero);
        }),
        60,
        20,
        <(int, int)>[(10, 10), (30, 10)],
      );
      paragraph.dispose();
      expect(pixels, <int>[glyph, space], reason: name);
    }
  });
}
