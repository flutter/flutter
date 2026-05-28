// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kBlueSquareRegion = ui.Rect.fromLTRB(0, 0, 25, 25);
const ui.Rect kRedCircleRegion = ui.Rect.fromLTRB(25, 0, 50, 25);
const ui.Rect kMagentaStarRegion = ui.Rect.fromLTRB(0, 25, 30, 55);
const ui.Rect kGreenSquiggleRegion = ui.Rect.fromLTRB(30, 25, 50, 55);
const ui.Rect kTotalAtlasRegion = ui.Rect.fromLTRB(0, 0, 55, 55);

ui.Image generateAtlas() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawColor(const ui.Color(0), ui.BlendMode.src);

  // Draw the square
  canvas.save();
  canvas.clipRect(kBlueSquareRegion);
  canvas.drawRect(
    // Inset the square by one pixel so it doesn't bleed into the other sprites.
    kBlueSquareRegion.deflate(1.0),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  canvas.restore();

  // Draw the circle
  canvas.save();
  canvas.clipRect(kRedCircleRegion);
  canvas.drawCircle(
    kRedCircleRegion.center,
    // Make the circle one pixel smaller than the bounds to it doesn't bleed
    // into the other shapes.
    (kRedCircleRegion.width / 2.0) - 1.0,
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.restore();

  // Draw the star
  canvas.save();
  canvas.clipRect(kMagentaStarRegion);
  final ui.Offset starCenter = kMagentaStarRegion.center;

  // Make the star one pixel smaller than the bounds so that it doesn't bleed
  // into the other shapes.
  final double radius = (kMagentaStarRegion.height / 2.0) - 1.0;

  // Start at the top (rotated 90 degrees)
  double theta = -math.pi / 2.0;

  // Rotate two fifths of the circle each time
  const double rotation = 4.0 * math.pi / 5.0;
  final starPath = ui.Path();
  starPath.moveTo(
    starCenter.dx + radius * math.cos(theta),
    starCenter.dy + radius * math.sin(theta),
  );
  for (var i = 0; i < 5; i++) {
    theta += rotation;
    starPath.lineTo(
      starCenter.dx + radius * math.cos(theta),
      starCenter.dy + radius * math.sin(theta),
    );
  }
  canvas.drawPath(
    starPath,
    ui.Paint()
      ..color = const ui.Color(0xFFFF00FF)
      ..style = ui.PaintingStyle.fill,
  );
  canvas.restore();

  // Draw the Squiggle
  canvas.save();
  canvas.clipRect(kGreenSquiggleRegion);
  final squigglePath = ui.Path();
  squigglePath.moveTo(kGreenSquiggleRegion.topCenter.dx, kGreenSquiggleRegion.topCenter.dy + 2.0);
  squigglePath.cubicTo(
    kGreenSquiggleRegion.left - 10.0,
    kGreenSquiggleRegion.top + kGreenSquiggleRegion.height * 0.33,
    kGreenSquiggleRegion.right + 10.0,
    kGreenSquiggleRegion.top + kGreenSquiggleRegion.height * 0.66,
    kGreenSquiggleRegion.bottomCenter.dx,
    kGreenSquiggleRegion.bottomCenter.dy - 2.0,
  );
  canvas.drawPath(
    squigglePath,
    ui.Paint()
      ..color = const ui.Color(0xFF00FF00)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 5.0,
  );
  canvas.restore();

  final ui.Picture picture = recorder.endRecording();
  return picture.toImageSync(kTotalAtlasRegion.width.toInt(), kTotalAtlasRegion.height.toInt());
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  const region = ui.Rect.fromLTWH(0, 0, 300, 300);

  test('render atlas', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, region);
    final ui.Image atlas = generateAtlas();
    canvas.drawImage(atlas, ui.Offset.zero, ui.Paint());
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('ui_atlas.png', region: region);
  });

  test('drawAtlas', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, region);
    final ui.Image atlas = generateAtlas();
    final transforms = List<ui.RSTransform>.generate(12, (int index) {
      const double radius = 100;
      const double rotation = math.pi / 6.0;
      final double angle = rotation * index;
      final double scos = math.sin(angle);
      final double ssin = math.cos(angle);
      return ui.RSTransform(
        scos,
        ssin,
        region.center.dx + radius * scos,
        region.center.dy + radius * ssin,
      );
    });
    final rects = <ui.Rect>[
      kBlueSquareRegion,
      kRedCircleRegion,
      kMagentaStarRegion,
      kGreenSquiggleRegion,
      kBlueSquareRegion,
      kRedCircleRegion,
      kMagentaStarRegion,
      kGreenSquiggleRegion,
      kBlueSquareRegion,
      kRedCircleRegion,
      kMagentaStarRegion,
      kGreenSquiggleRegion,
    ];
    canvas.drawAtlas(atlas, transforms, rects, null, null, null, ui.Paint());

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('ui_draw_atlas.png', region: region);
  });

  test('drawAtlasRaw', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, region);
    final ui.Image atlas = generateAtlas();
    final transforms = Float32List(12 * 4);
    for (var i = 0; i < 12; i++) {
      const double radius = 100;
      const double rotation = math.pi / 6.0;
      final double angle = rotation * i;
      final double scos = math.sin(angle);
      final double ssin = math.cos(angle);
      transforms[i * 4] = scos;
      transforms[i * 4 + 1] = ssin;
      transforms[i * 4 + 2] = region.center.dx + radius * scos;
      transforms[i * 4 + 3] = region.center.dy + radius * ssin;
    }
    final rects = <ui.Rect>[
      kBlueSquareRegion,
      kRedCircleRegion,
      kMagentaStarRegion,
      kGreenSquiggleRegion,
      kBlueSquareRegion,
      kRedCircleRegion,
      kMagentaStarRegion,
      kGreenSquiggleRegion,
      kBlueSquareRegion,
      kRedCircleRegion,
      kMagentaStarRegion,
      kGreenSquiggleRegion,
    ];
    final rawRects = Float32List(rects.length * 4);
    for (var i = 0; i < rects.length; i++) {
      rawRects[i * 4] = rects[i].left;
      rawRects[i * 4 + 1] = rects[i].top;
      rawRects[i * 4 + 2] = rects[i].right;
      rawRects[i * 4 + 3] = rects[i].bottom;
    }

    final colors = Int32List(12);
    for (var i = 0; i < 12; i++) {
      final int rgb = 0xFF << (8 * (i % 3));
      colors[i] = 0xFF000000 | rgb;
    }
    canvas.drawRawAtlas(atlas, transforms, rawRects, colors, ui.BlendMode.dstIn, null, ui.Paint());

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('ui_draw_atlas_raw.png', region: region);
  });

  // Regression test for skwasm hardcoding linear/mipmap sampling on
  // drawAtlas regardless of Paint.filterQuality. Uses a tiny 2x2
  // checker atlas drawn at a large non-integer scale: the
  // non-integer factor lines up the source texel boundary with a
  // destination pixel *center*, so linear filtering produces a
  // single perfectly 50/50 gray pixel that no nearest-neighbour
  // pass can ever produce — a strong discriminator between
  // FilterQuality.none and the filtered modes. One golden per
  // FilterQuality value protects all four code paths.
  for (final ui.FilterQuality filterQuality in ui.FilterQuality.values) {
    test('drawAtlas honors Paint.filterQuality.${filterQuality.name}', () async {
      // 2x2 black/white checker atlas.
      final atlasRecorder = ui.PictureRecorder();
      final atlasCanvas = ui.Canvas(atlasRecorder);
      atlasCanvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
      final blackFill = ui.Paint()..color = const ui.Color(0xFF000000);
      atlasCanvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), blackFill);
      atlasCanvas.drawRect(const ui.Rect.fromLTWH(1, 1, 1, 1), blackFill);
      final ui.Image checker = atlasRecorder.endRecording().toImageSync(2, 2);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, region);
      // Single sprite scaled ~72.5x via RSTransform. The .5 is
      // intentional: it places the source texel boundary at source
      // y=1.0 onto destination y=16+72.5=88.5 — exactly the centre
      // of destination pixel 88 — so bilinear sampling emits one
      // mathematically perfect 50/50 gray pixel surrounded by pure
      // black/white. That single gray pixel cannot be produced by
      // nearest-neighbour sampling and is what the goldens lock in.
      const scale = 72.5;
      final transforms = <ui.RSTransform>[ui.RSTransform(scale, 0.0, 16.0, 16.0)];
      const rects = <ui.Rect>[ui.Rect.fromLTWH(0, 0, 2, 2)];
      canvas.drawAtlas(
        checker,
        transforms,
        rects,
        null,
        null,
        null,
        ui.Paint()..filterQuality = filterQuality,
      );

      await drawPictureUsingCurrentRenderer(recorder.endRecording());
      await matchGoldenFile('ui_draw_atlas_filter_${filterQuality.name}.png', region: region);
    });
  }

  // Regression test for the pre-existing null-`colors` deref in
  // skwasm's `canvas_drawAtlas`. The dart wrapper passes nullptr
  // when the caller's `colors` list is null, but the C++ side used
  // to loop `colors[i]` regardless — only saved from crashing by
  // WASM reads at address 0 returning zero. Three stacked sprites
  // with null colors force the loop bound past index 0, so any
  // future regression that reintroduces the unguarded read would
  // surface here.
  test('drawAtlas with null colors does not read past nullptr', () async {
    final atlasRecorder = ui.PictureRecorder();
    final atlasCanvas = ui.Canvas(atlasRecorder);
    atlasCanvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    final blackFill = ui.Paint()..color = const ui.Color(0xFF000000);
    atlasCanvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), blackFill);
    atlasCanvas.drawRect(const ui.Rect.fromLTWH(1, 1, 1, 1), blackFill);
    final ui.Image checker = atlasRecorder.endRecording().toImageSync(2, 2);

    const scale = 40.0;
    final transforms = <ui.RSTransform>[
      ui.RSTransform(scale, 0.0, 16.0, 16.0),
      ui.RSTransform(scale, 0.0, 16.0, 110.0),
      ui.RSTransform(scale, 0.0, 16.0, 204.0),
    ];
    const rects = <ui.Rect>[
      ui.Rect.fromLTWH(0, 0, 2, 2),
      ui.Rect.fromLTWH(0, 0, 2, 2),
      ui.Rect.fromLTWH(0, 0, 2, 2),
    ];
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, region);
    canvas.drawAtlas(
      checker,
      transforms,
      rects,
      null,
      null,
      null,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('ui_draw_atlas_null_colors.png', region: region);
  });
}
