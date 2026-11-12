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
    expect(defaults.colorFilter, isNull);
    expect(defaults.shader, isNull);
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
    expect(paint.colorFilter, same(colorFilter));
    expect(paint.shader, same(shader));
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
      expect(
        paint.effectiveMaskFilter,
        blurs ? same(maskFilter) : isNull,
        reason: 'Skia can only build a blur mask filter for a finite, positive sigma ($sigma).',
      );

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
        expect(
          pixels[1] & 0xFF,
          greaterThan(0),
          reason: 'A blur with sigma $sigma spreads the color past the edge of the rect.',
        );
      } else {
        expect(
          pixels,
          <int>[_bluePixel, 0x00000000],
          reason:
              'With sigma $sigma the rect is drawn without a mask filter, so its edge is sharp.',
        );
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

  test(
    'changing a paint between draws in one picture does not change shapes already drawn',
    () async {
      final paint = ui.Paint();
      final List<int> pixels = await _readPixels(
        drawPicture((ui.Canvas canvas) {
          // 10x10 squares, 10px apart, on a 120x20 image.
          void drawSquare(int index) =>
              canvas.drawRect(ui.Rect.fromLTWH(index * 20.0, 5, 10, 10), paint);

          paint
            ..color = _red
            ..colorFilter = _freshColorFilter(_green);
          drawSquare(0);
          paint
            ..colorFilter = null
            ..shader = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(120, 0), const <ui.Color>[
              ui.Color(0xFF0000FF),
              ui.Color(0xFF0000FF),
            ]);
          drawSquare(1);
          paint
            ..shader = null
            ..color = _white
            ..imageFilter = _freshColorFilter(_green);
          drawSquare(2);
          paint
            ..imageFilter = null
            ..color = _red
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
          drawSquare(3);
          paint
            ..maskFilter = null
            ..invertColors = true;
          drawSquare(4);
          paint.invertColors = false;
          drawSquare(5);
        }),
        120,
        20,
        <(int, int)>[(5, 10), (25, 10), (45, 10), (58, 10), (85, 10), (92, 10), (105, 10)],
      );
      expect(pixels, <Object>[
        _greenPixel,
        // Gradients are dithered, so allow a small error.
        predicate<int>(
          (int p) => (p >> 24) <= 2 && (p >> 16 & 0xFF) <= 2 && (p >> 8 & 0xFF) >= 0xFD,
          'close to blue',
        ),
        _greenPixel,
        predicate<int>((int p) => (p & 0xFF) > 0 && (p & 0xFF) < 0xFF, 'a blurred edge'),
        // Red with inverted colors.
        0x00FFFFFF,
        // The mask filter was cleared, so nothing is drawn outside the square.
        0x00000000,
        _redPixel,
      ]);
    },
  );

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

  test('a ColorFilter image filter is finalized with its ColorFilter', () {
    final Finalizer originalFinalizer = EngineImageFilter.finalizer;
    final mockFinalizer = _MockFinalizer();
    EngineImageFilter.finalizer = mockFinalizer;
    addTearDown(() => EngineImageFilter.finalizer = originalFinalizer);

    final EngineColorFilter colorFilter = _freshColorFilter(_green);
    final BackendImageFilter backendFilter = EngineColorFilterImageFilter(colorFilter: colorFilter)
        .getBackendFilter(defaultBlurTileMode: ui.TileMode.decal);

    // The wrapper is thrown away every frame, so the backend filter must be
    // tied to the lifetime of the ColorFilter it is cached on.
    expect(mockFinalizer.registeredPairs.single.target, same(colorFilter));
    expect(mockFinalizer.registeredPairs.single.value, same(backendFilter));
  });

  test('paragraph styles with only a foreground or only a background paint draw both', () async {
    final cases = <({String reason, ui.TextStyle style, int glyph, int space})>[
      (
        reason:
            'With only a background paint, glyphs are drawn in the style color over the '
            'background paint.',
        style: ui.TextStyle(color: _green, background: ui.Paint()..color = _red),
        glyph: _greenPixel,
        space: _redPixel,
      ),
      (
        reason:
            'With only a foreground paint, glyphs are drawn with the foreground paint over a '
            'transparent background.',
        style: ui.TextStyle(foreground: ui.Paint()..color = _green),
        glyph: _greenPixel,
        space: _whitePixel,
      ),
    ];
    for (final (:String reason, :ui.TextStyle style, :int glyph, :int space) in cases) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Ahem', fontSize: 20))
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
      expect(pixels, <int>[glyph, space], reason: reason);
    }
  });
}

class _MockFinalizer implements Finalizer {
  final List<({Object target, Object value, Object? detach})> _registeredPairs = [];

  List<({Object target, Object value, Object? detach})> get registeredPairs => _registeredPairs;

  @override
  void attach(Object target, Object value, {Object? detach}) {
    _registeredPairs.add((target: target, value: value, detach: detach));
  }

  @override
  void detach(Object detach) {
    _registeredPairs.removeWhere((pair) => pair.detach == detach);
  }
}
