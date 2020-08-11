// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';
import 'test_data.dart';

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
    _fillTypeTests();
    _pathOpTests();
    _clipOpTests();
    _pointModeTests();
    _vertexModeTests();
    _imageTests();
    _shaderTests();
    _paintTests();
    _maskFilterTests();
    _colorFilterTests();
    _imageFilterTests();
    _mallocTests();
    _sharedColorTests();
    _toSkPointTests();
    _toSkColorStopsTests();
    _toSkMatrixFromFloat32Tests();
    _skSkRectTests();
    _skVerticesTests();
    group('SkPath', () {
      _pathTests();
    });
    group('SkCanvas', () {
      _canvasTests();
    });
  // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

void _blendModeTests() {
  test('blend mode mapping is correct', () {
    expect(canvasKit.BlendMode.Clear.value, ui.BlendMode.clear.index);
    expect(canvasKit.BlendMode.Src.value, ui.BlendMode.src.index);
    expect(canvasKit.BlendMode.Dst.value, ui.BlendMode.dst.index);
    expect(canvasKit.BlendMode.SrcOver.value, ui.BlendMode.srcOver.index);
    expect(canvasKit.BlendMode.DstOver.value, ui.BlendMode.dstOver.index);
    expect(canvasKit.BlendMode.SrcIn.value, ui.BlendMode.srcIn.index);
    expect(canvasKit.BlendMode.DstIn.value, ui.BlendMode.dstIn.index);
    expect(canvasKit.BlendMode.SrcOut.value, ui.BlendMode.srcOut.index);
    expect(canvasKit.BlendMode.DstOut.value, ui.BlendMode.dstOut.index);
    expect(canvasKit.BlendMode.SrcATop.value, ui.BlendMode.srcATop.index);
    expect(canvasKit.BlendMode.DstATop.value, ui.BlendMode.dstATop.index);
    expect(canvasKit.BlendMode.Xor.value, ui.BlendMode.xor.index);
    expect(canvasKit.BlendMode.Plus.value, ui.BlendMode.plus.index);
    expect(canvasKit.BlendMode.Modulate.value, ui.BlendMode.modulate.index);
    expect(canvasKit.BlendMode.Screen.value, ui.BlendMode.screen.index);
    expect(canvasKit.BlendMode.Overlay.value, ui.BlendMode.overlay.index);
    expect(canvasKit.BlendMode.Darken.value, ui.BlendMode.darken.index);
    expect(canvasKit.BlendMode.Lighten.value, ui.BlendMode.lighten.index);
    expect(canvasKit.BlendMode.ColorDodge.value, ui.BlendMode.colorDodge.index);
    expect(canvasKit.BlendMode.ColorBurn.value, ui.BlendMode.colorBurn.index);
    expect(canvasKit.BlendMode.HardLight.value, ui.BlendMode.hardLight.index);
    expect(canvasKit.BlendMode.SoftLight.value, ui.BlendMode.softLight.index);
    expect(canvasKit.BlendMode.Difference.value, ui.BlendMode.difference.index);
    expect(canvasKit.BlendMode.Exclusion.value, ui.BlendMode.exclusion.index);
    expect(canvasKit.BlendMode.Multiply.value, ui.BlendMode.multiply.index);
    expect(canvasKit.BlendMode.Hue.value, ui.BlendMode.hue.index);
    expect(canvasKit.BlendMode.Saturation.value, ui.BlendMode.saturation.index);
    expect(canvasKit.BlendMode.Color.value, ui.BlendMode.color.index);
    expect(canvasKit.BlendMode.Luminosity.value, ui.BlendMode.luminosity.index);
  });

  test('ui.BlendMode converts to SkBlendMode', () {
    for (ui.BlendMode blendMode in ui.BlendMode.values) {
      expect(toSkBlendMode(blendMode).value, blendMode.index);
    }
  });
}

void _paintStyleTests() {
  test('paint style mapping is correct', () {
    expect(canvasKit.PaintStyle.Fill.value, ui.PaintingStyle.fill.index);
    expect(canvasKit.PaintStyle.Stroke.value, ui.PaintingStyle.stroke.index);
  });

  test('ui.PaintingStyle converts to SkPaintStyle', () {
    for (ui.PaintingStyle style in ui.PaintingStyle.values) {
      expect(toSkPaintStyle(style).value, style.index);
    }
  });
}

void _strokeCapTests() {
  test('stroke cap mapping is correct', () {
    expect(canvasKit.StrokeCap.Butt.value, ui.StrokeCap.butt.index);
    expect(canvasKit.StrokeCap.Round.value, ui.StrokeCap.round.index);
    expect(canvasKit.StrokeCap.Square.value, ui.StrokeCap.square.index);
  });

  test('ui.StrokeCap converts to SkStrokeCap', () {
    for (ui.StrokeCap cap in ui.StrokeCap.values) {
      expect(toSkStrokeCap(cap).value, cap.index);
    }
  });
}

void _strokeJoinTests() {
  test('stroke cap mapping is correct', () {
    expect(canvasKit.StrokeJoin.Miter.value, ui.StrokeJoin.miter.index);
    expect(canvasKit.StrokeJoin.Round.value, ui.StrokeJoin.round.index);
    expect(canvasKit.StrokeJoin.Bevel.value, ui.StrokeJoin.bevel.index);
  });

  test('ui.StrokeJoin converts to SkStrokeJoin', () {
    for (ui.StrokeJoin join in ui.StrokeJoin.values) {
      expect(toSkStrokeJoin(join).value, join.index);
    }
  });
}

void _filterQualityTests() {
  test('filter quality mapping is correct', () {
    expect(canvasKit.FilterQuality.None.value, ui.FilterQuality.none.index);
    expect(canvasKit.FilterQuality.Low.value, ui.FilterQuality.low.index);
    expect(canvasKit.FilterQuality.Medium.value, ui.FilterQuality.medium.index);
    expect(canvasKit.FilterQuality.High.value, ui.FilterQuality.high.index);
  });

  test('ui.FilterQuality converts to SkFilterQuality', () {
    for (ui.FilterQuality cap in ui.FilterQuality.values) {
      expect(toSkFilterQuality(cap).value, cap.index);
    }
  });
}

void _blurStyleTests() {
  test('blur style mapping is correct', () {
    expect(canvasKit.BlurStyle.Normal.value, ui.BlurStyle.normal.index);
    expect(canvasKit.BlurStyle.Solid.value, ui.BlurStyle.solid.index);
    expect(canvasKit.BlurStyle.Outer.value, ui.BlurStyle.outer.index);
    expect(canvasKit.BlurStyle.Inner.value, ui.BlurStyle.inner.index);
  });

  test('ui.BlurStyle converts to SkBlurStyle', () {
    for (ui.BlurStyle style in ui.BlurStyle.values) {
      expect(toSkBlurStyle(style).value, style.index);
    }
  });
}

void _tileModeTests() {
  test('tile mode mapping is correct', () {
    expect(canvasKit.TileMode.Clamp.value, ui.TileMode.clamp.index);
    expect(canvasKit.TileMode.Repeat.value, ui.TileMode.repeated.index);
    expect(canvasKit.TileMode.Mirror.value, ui.TileMode.mirror.index);
  });

  test('ui.TileMode converts to SkTileMode', () {
    for (ui.TileMode mode in ui.TileMode.values) {
      expect(toSkTileMode(mode).value, mode.index);
    }
  });
}

void _fillTypeTests() {
  test('fill type mapping is correct', () {
    expect(canvasKit.FillType.Winding.value, ui.PathFillType.nonZero.index);
    expect(canvasKit.FillType.EvenOdd.value, ui.PathFillType.evenOdd.index);
  });

  test('ui.PathFillType converts to SkFillType', () {
    for (ui.PathFillType type in ui.PathFillType.values) {
      expect(toSkFillType(type).value, type.index);
    }
  });
}

void _pathOpTests() {
  // TODO(yjbanov): https://github.com/flutter/flutter/issues/61403
  // test('path op mapping is correct', () {
  //   expect(canvasKit.PathOp.Difference.value, ui.PathOperation.difference.index);
  //   expect(canvasKit.PathOp.Intersect.value, ui.PathOperation.intersect.index);
  //   expect(canvasKit.PathOp.Union.value, ui.PathOperation.union.index);
  //   expect(canvasKit.PathOp.XOR.value, ui.PathOperation.xor.index);
  //   expect(canvasKit.PathOp.ReverseDifference, ui.PathOperation.reverseDifference.index);
  // });

  // test('ui.PathOperation converts to SkPathOp', () {
  //   for (ui.PathOperation op in ui.PathOperation.values) {
  //     expect(toSkPathOp(op).value, op.index);
  //   }
  // });
}

void _clipOpTests() {
  test('clip op mapping is correct', () {
    expect(canvasKit.ClipOp.Difference.value, ui.ClipOp.difference.index);
    expect(canvasKit.ClipOp.Intersect.value, ui.ClipOp.intersect.index);
  });

  test('ui.ClipOp converts to SkClipOp', () {
    for (ui.ClipOp op in ui.ClipOp.values) {
      expect(toSkClipOp(op).value, op.index);
    }
  });
}

void _pointModeTests() {
  test('point mode mapping is correct', () {
    expect(canvasKit.PointMode.Points.value, ui.PointMode.points.index);
    expect(canvasKit.PointMode.Lines.value, ui.PointMode.lines.index);
    expect(canvasKit.PointMode.Polygon.value, ui.PointMode.polygon.index);
  });

  test('ui.PointMode converts to SkPointMode', () {
    for (ui.PointMode op in ui.PointMode.values) {
      expect(toSkPointMode(op).value, op.index);
    }
  });
}

void _vertexModeTests() {
  test('vertex mode mapping is correct', () {
    expect(canvasKit.VertexMode.Triangles.value, ui.VertexMode.triangles.index);
    expect(canvasKit.VertexMode.TrianglesStrip.value, ui.VertexMode.triangleStrip.index);
    expect(canvasKit.VertexMode.TriangleFan.value, ui.VertexMode.triangleFan.index);
  });

  test('ui.VertexMode converts to SkVertexMode', () {
    for (ui.VertexMode op in ui.VertexMode.values) {
      expect(toSkVertexMode(op).value, op.index);
    }
  });
}

void _imageTests() {
  test('MakeAnimatedImageFromEncoded makes a non-animated image', () {
    final SkAnimatedImage nonAnimated = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
    expect(nonAnimated.getFrameCount(), 1);
    expect(nonAnimated.getRepetitionCount(), 0);
    expect(nonAnimated.width(), 1);
    expect(nonAnimated.height(), 1);

    final SkImage frame = nonAnimated.getCurrentFrame();
    expect(frame.width(), 1);
    expect(frame.height(), 1);

    expect(nonAnimated.decodeNextFrame(), -1);
    expect(
      frame.makeShader(
        canvasKit.TileMode.Repeat,
        canvasKit.TileMode.Mirror,
        toSkMatrixFromFloat32(Matrix4.identity().storage),
      ),
      isNotNull,
    );
  });

  test('MakeAnimatedImageFromEncoded makes an animated image', () {
    final SkAnimatedImage animated = canvasKit.MakeAnimatedImageFromEncoded(kAnimatedGif);
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
    expect(canvasKit.SkShader.MakeRadialGradient(
      Float32List.fromList([1, 1]),
      10.0,
      <Float32List>[
        Float32List.fromList([0, 0, 0, 1]),
        Float32List.fromList([1, 1, 1, 1]),
      ],
      Float32List.fromList([0, 1]),
      canvasKit.TileMode.Repeat,
      toSkMatrixFromFloat32(Matrix4.identity().storage),
      0,
    ), isNotNull);
  });

  test('MakeTwoPointConicalGradient', () {
    expect(canvasKit.SkShader.MakeTwoPointConicalGradient(
      Float32List.fromList([1, 1]),
      10.0,
      Float32List.fromList([1, 1]),
      10.0,
      <Float32List>[
        Float32List.fromList([0, 0, 0, 1]),
        Float32List.fromList([1, 1, 1, 1]),
      ],
      Float32List.fromList([0, 1]),
      canvasKit.TileMode.Repeat,
      toSkMatrixFromFloat32(Matrix4.identity().storage),
      0,
    ), isNotNull);
  });
}

SkShader _makeTestShader() {
  return canvasKit.SkShader.MakeLinearGradient(
    Float32List.fromList([0, 0]),
    Float32List.fromList([1, 1]),
    [
      Float32List.fromList([255, 0, 0, 255]),
    ],
    Float32List.fromList([0, 1]),
    canvasKit.TileMode.Repeat,
  );
}

void _paintTests() {
  test('can make SkPaint', () async {
    final SkPaint paint = SkPaint();
    paint.setBlendMode(canvasKit.BlendMode.SrcOut);
    paint.setStyle(canvasKit.PaintStyle.Stroke);
    paint.setStrokeWidth(3.0);
    paint.setStrokeCap(canvasKit.StrokeCap.Round);
    paint.setStrokeJoin(canvasKit.StrokeJoin.Bevel);
    paint.setAntiAlias(true);
    paint.setColorInt(0x00FFCCAA);
    paint.setShader(_makeTestShader());
    paint.setMaskFilter(canvasKit.MakeBlurMaskFilter(
      canvasKit.BlurStyle.Outer,
      2.0,
      true,
    ));
    paint.setFilterQuality(canvasKit.FilterQuality.High);
    paint.setColorFilter(canvasKit.SkColorFilter.MakeLinearToSRGBGamma());
    paint.setStrokeMiter(1.4);
    paint.setImageFilter(canvasKit.SkImageFilter.MakeBlur(
      1,
      2,
      canvasKit.TileMode.Repeat,
      null,
    ));
  });
}

void _maskFilterTests() {
  test('MakeBlurMaskFilter', () {
    expect(canvasKit.MakeBlurMaskFilter(
      canvasKit.BlurStyle.Outer,
      5.0,
      false,
    ), isNotNull);
  });
}

void _colorFilterTests() {
  test('MakeBlend', () {
    expect(
      canvasKit.SkColorFilter.MakeBlend(
        Float32List.fromList([0, 0, 0, 1]),
        canvasKit.BlendMode.SrcATop,
      ),
      isNotNull,
    );
  });

  test('MakeMatrix', () {
    expect(
      canvasKit.SkColorFilter.MakeMatrix(
        Float32List(20),
      ),
      isNotNull,
    );
  });

  test('MakeSRGBToLinearGamma', () {
    expect(
      canvasKit.SkColorFilter.MakeSRGBToLinearGamma(),
      isNotNull,
    );
  });

  test('MakeLinearToSRGBGamma', () {
    expect(
      canvasKit.SkColorFilter.MakeLinearToSRGBGamma(),
      isNotNull,
    );
  });
}

void _imageFilterTests() {
  test('MakeBlur', () {
    expect(
      canvasKit.SkImageFilter.MakeBlur(1, 2, canvasKit.TileMode.Repeat, null),
      isNotNull,
    );
  });

  test('MakeMatrixTransform', () {
    expect(
      canvasKit.SkImageFilter.MakeMatrixTransform(
        toSkMatrixFromFloat32(Matrix4.identity().storage),
        canvasKit.FilterQuality.Medium,
        null,
      ),
      isNotNull,
    );
  });
}

void _mallocTests() {
  test('SkFloat32List', () {
    for (int size = 0; size < 1000; size++) {
      final SkFloat32List skList = mallocFloat32List(4);
      expect(skList, isNotNull);
      expect(skList.toTypedArray().length, 4);
    }
  });
}

void _sharedColorTests() {
  test('toSharedSkColor1', () {
    expect(
      toSharedSkColor1(const ui.Color(0xAABBCCDD)),
      Float32List(4)
        ..[0] = 0xBB / 255.0
        ..[1] = 0xCC / 255.0
        ..[2] = 0xDD / 255.0
        ..[3] = 0xAA / 255.0,
    );
  });
  test('toSharedSkColor2', () {
    expect(
      toSharedSkColor2(const ui.Color(0xAABBCCDD)),
      Float32List(4)
        ..[0] = 0xBB / 255.0
        ..[1] = 0xCC / 255.0
        ..[2] = 0xDD / 255.0
        ..[3] = 0xAA / 255.0,
    );
  });
  test('toSharedSkColor3', () {
    expect(
      toSharedSkColor3(const ui.Color(0xAABBCCDD)),
      Float32List(4)
        ..[0] = 0xBB / 255.0
        ..[1] = 0xCC / 255.0
        ..[2] = 0xDD / 255.0
        ..[3] = 0xAA / 255.0,
    );
  });
}

void _toSkPointTests() {
  test('toSkPoint', () {
    expect(
      toSkPoint(const ui.Offset(4, 5)),
      Float32List(2)
        ..[0] = 4.0
        ..[1] = 5.0,
    );
  });
}

void _toSkColorStopsTests() {
  test('toSkColorStops default', () {
    expect(
      toSkColorStops(null),
      Float32List(2)
        ..[0] = 0
        ..[1] = 1,
    );
  });

  test('toSkColorStops custom', () {
    expect(
      toSkColorStops(<double>[1, 2, 3, 4]),
      Float32List(4)
        ..[0] = 1
        ..[1] = 2
        ..[2] = 3
        ..[3] = 4,
    );
  });
}

void _toSkMatrixFromFloat32Tests() {
  test('toSkMatrixFromFloat32', () {
    final Matrix4 matrix = Matrix4.identity()
      ..translate(1, 2, 3)
      ..rotateZ(4);
    expect(
      toSkMatrixFromFloat32(matrix.storage),
      Float32List.fromList(<double>[
        -0.6536436080932617,
        0.756802499294281,
        1,
        -0.756802499294281,
        -0.6536436080932617,
        2,
        -0.0,
        0,
        1,
      ])
    );
  });
}

SkPath _testClosedSkPath() {
  return SkPath()
    ..moveTo(10, 10)
    ..lineTo(20, 10)
    ..lineTo(20, 20)
    ..lineTo(10, 20)
    ..close();
}

void _pathTests() {
  SkPath path;

  setUp(() {
    path = SkPath();
  });

  test('setFillType', () {
    path.setFillType(canvasKit.FillType.Winding);
  });

  test('addArc', () {
    path.addArc(
      SkRect(fLeft: 10, fTop: 20, fRight: 30, fBottom: 40),
      1,
      5,
    );
  });

  test('addOval', () {
    path.addOval(
      SkRect(fLeft: 10, fTop: 20, fRight: 30, fBottom: 40),
      false,
      1,
    );
  });

  test('addPath', () {
    path.addPath(_testClosedSkPath(), 1, 0, 0, 0, 1, 0, 0, 0, 0, false);
  });

  test('addPoly', () {
    final SkFloat32List encodedPoints = toMallocedSkPoints(const <ui.Offset>[
      ui.Offset.zero,
      ui.Offset(10, 10),
    ]);
    path.addPoly(encodedPoints.toTypedArray(), true);
    freeFloat32List(encodedPoints);
  });

  test('addRoundRect', () {
    final ui.RRect rrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTRB(10, 10, 20, 20),
      ui.Radius.circular(3),
    );
    final SkFloat32List skRadii = mallocFloat32List(8);
    final Float32List radii = skRadii.toTypedArray();
    radii[0] = rrect.tlRadiusX;
    radii[1] = rrect.tlRadiusY;
    radii[2] = rrect.trRadiusX;
    radii[3] = rrect.trRadiusY;
    radii[4] = rrect.brRadiusX;
    radii[5] = rrect.brRadiusY;
    radii[6] = rrect.blRadiusX;
    radii[7] = rrect.blRadiusY;
    path.addRoundRect(
      toOuterSkRect(rrect),
      radii,
      false,
    );
    freeFloat32List(skRadii);
  });

  test('addRect', () {
    path.addRect(SkRect(fLeft: 1, fTop: 2, fRight: 3, fBottom: 4));
  });

  test('arcTo', () {
    path.arcToOval(
      SkRect(fLeft: 1, fTop: 2, fRight: 3, fBottom: 4),
      5,
      40,
      false,
    );
  });

  test('overloaded arcTo (used for arcToPoint)', () {
    path.arcToRotated(
      1,
      2,
      3,
      false,
      true,
      4,
      5,
    );
  });

  test('close', () {
    _testClosedSkPath();
  });

  test('conicTo', () {
    path.conicTo(1, 2, 3, 4, 5);
  });

  test('contains', () {
    final SkPath testPath = _testClosedSkPath();
    expect(testPath.contains(15, 15), true);
    expect(testPath.contains(100, 100), false);
  });

  test('cubicTo', () {
    path.cubicTo(1, 2, 3, 4, 5, 6);
  });

  test('getBounds', () {
    final SkPath testPath = _testClosedSkPath();
    final ui.Rect bounds = testPath.getBounds().toRect();
    expect(bounds, const ui.Rect.fromLTRB(10, 10, 20, 20));
  });

  test('lineTo', () {
    path.lineTo(10, 10);
  });

  test('moveTo', () {
    path.moveTo(10, 10);
  });

  test('quadTo', () {
    path.quadTo(10, 10, 20, 20);
  });

  test('rArcTo', () {
    path.rArcTo(
      10,
      20,
      30,
      false,
      true,
      40,
      50,
    );
  });

  test('rConicTo', () {
    path.rConicTo(1, 2, 3, 4, 5);
  });

  test('rCubicTo', () {
    path.rCubicTo(1, 2, 3, 4, 5, 6);
  });

  test('rLineTo', () {
    path.rLineTo(10, 10);
  });

  test('rMoveTo', () {
    path.rMoveTo(10, 10);
  });

  test('rQuadTo', () {
    path.rQuadTo(10, 10, 20, 20);
  });

  test('reset', () {
    final SkPath testPath = _testClosedSkPath();
    expect(testPath.getBounds().toRect(), const ui.Rect.fromLTRB(10, 10, 20, 20));
    testPath.reset();
    expect(testPath.getBounds().toRect(), ui.Rect.zero);
  });

  test('toSVGString', () {
    expect(_testClosedSkPath().toSVGString(), 'M10 10L20 10L20 20L10 20L10 10Z');
  });

  test('isEmpty', () {
    expect(SkPath().isEmpty(), true);
    expect(_testClosedSkPath().isEmpty(), false);
  });

  test('copy', () {
    final SkPath original = _testClosedSkPath();
    final SkPath copy = original.copy();
    expect(original.getBounds().toRect(), copy.getBounds().toRect());
  });

  test('transform', () {
    path = _testClosedSkPath();
    path.transform(2, 0, 10, 0, 2, 10, 0, 0, 0);
    final ui.Rect transformedBounds = path.getBounds().toRect();
    expect(transformedBounds, ui.Rect.fromLTRB(30, 30, 50, 50));
  });

  test('SkContourMeasureIter/SkContourMeasure', () {
    final SkContourMeasureIter iter = SkContourMeasureIter(_testClosedSkPath(), false, 0);
    final SkContourMeasure measure1 = iter.next();
    expect(measure1.length(), 40);
    expect(measure1.getPosTan(5), Float32List.fromList(<double>[15, 10, 1, 0]));
    expect(measure1.getPosTan(15), Float32List.fromList(<double>[20, 15, 0, 1]));
    expect(measure1.isClosed(), true);

    // Starting with a box path:
    //
    //    10         20
    // 10 +-----------+
    //    |           |
    //    |           |
    //    |           |
    //    |           |
    //    |           |
    // 20 +-----------+
    //
    // Cut out the top-right quadrant:
    //
    //    10    15   20
    // 10 +-----+=====+
    //    |     ║+++++║
    //    |     ║+++++║
    //    |     +=====+ 15
    //    |           |
    //    |           |
    // 20 +-----------+
    final SkPath segment = measure1.getSegment(5, 15, true);
    expect(segment.getBounds().toRect(), ui.Rect.fromLTRB(15, 10, 20, 15));

    final SkContourMeasure measure2 = iter.next();
    expect(measure2, isNull);
  });
}

void _skSkRectTests() {
  test('SkRect', () {
    final SkRect rect = SkRect(fLeft: 1, fTop: 2, fRight: 3, fBottom: 4);
    expect(rect.fLeft, 1);
    expect(rect.fTop, 2);
    expect(rect.fRight, 3);
    expect(rect.fBottom, 4);

    final ui.Rect uiRect = rect.toRect();
    expect(uiRect.left, 1);
    expect(uiRect.top, 2);
    expect(uiRect.right, 3);
    expect(uiRect.bottom, 4);
  });
}

SkVertices _testVertices() {
  return canvasKit.MakeSkVertices(
    canvasKit.VertexMode.Triangles,
    [
      Float32List.fromList([0, 0]),
      Float32List.fromList([10, 10]),
      Float32List.fromList([0, 20]),
    ],
    [
      Float32List.fromList([0, 0]),
      Float32List.fromList([10, 10]),
      Float32List.fromList([0, 20]),
    ],
    [
      Float32List.fromList([255, 0, 0, 255]),
      Float32List.fromList([0, 255, 0, 255]),
      Float32List.fromList([0, 0, 255, 255]),
    ],
    Uint16List.fromList([0, 1, 2]),
  );
}

void _skVerticesTests() {
  test('SkVertices', () {
    expect(_testVertices(), isNotNull);
  });
}

void _canvasTests() {
  SkPictureRecorder recorder;
  SkCanvas canvas;

  setUp(() {
    recorder = SkPictureRecorder();
    canvas = recorder.beginRecording(SkRect(
      fLeft: 0,
      fTop: 0,
      fRight: 100,
      fBottom: 100,
    ));
  });

  tearDown(() {
    expect(recorder.finishRecordingAsPicture(), isNotNull);
  });

  test('save/getSaveCount/restore/restoreToCount', () {
    expect(canvas.save(), 1);
    expect(canvas.save(), 2);
    expect(canvas.save(), 3);
    expect(canvas.save(), 4);
    expect(canvas.getSaveCount(), 5);
    canvas.restoreToCount(2);
    expect(canvas.getSaveCount(), 2);
    canvas.restore();
    expect(canvas.getSaveCount(), 1);
  });

  test('saveLayer', () {
    canvas.saveLayer(
      SkRect(
        fLeft: 0,
        fTop: 0,
        fRight: 100,
        fBottom: 100,
      ),
      SkPaint(),
    );
  });

  test('SkCanvasSaveLayerWithoutBoundsOverload.saveLayer', () {
    final SkCanvasSaveLayerWithoutBoundsOverload override = canvas as SkCanvasSaveLayerWithoutBoundsOverload;
    override.saveLayer(SkPaint());
  });

  test('SkCanvasSaveLayerWithFilterOverload.saveLayer', () {
    final SkCanvasSaveLayerWithFilterOverload override = canvas as SkCanvasSaveLayerWithFilterOverload;
    override.saveLayer(
      SkPaint(),
      canvasKit.SkImageFilter.MakeBlur(1, 2, canvasKit.TileMode.Repeat, null),
      0,
      SkRect(
        fLeft: 0,
        fTop: 0,
        fRight: 100,
        fBottom: 100,
      ),
    );
  });

  test('clear', () {
    canvas.clear(Float32List.fromList([0, 0, 0, 0]));
  });

  test('clipPath', () {
    canvas.clipPath(
      _testClosedSkPath(),
      canvasKit.ClipOp.Intersect,
      true,
    );
  });

  test('clipRRect', () {
    canvas.clipRRect(
      SkRRect(
        rect: SkRect(
          fLeft: 0,
          fTop: 0,
          fRight: 100,
          fBottom: 100,
        ),
        rx1: 1,
        ry1: 2,
        rx2: 3,
        ry2: 4,
        rx3: 5,
        ry3: 6,
        rx4: 7,
        ry4: 8,
      ),
      canvasKit.ClipOp.Intersect,
      true,
    );
  });

  test('clipRect', () {
    canvas.clipRect(
      SkRect(
        fLeft: 0,
        fTop: 0,
        fRight: 100,
        fBottom: 100,
      ),
      canvasKit.ClipOp.Intersect,
      true,
    );
  });

  test('drawArc', () {
    canvas.drawArc(
      SkRect(
        fLeft: 0,
        fTop: 0,
        fRight: 100,
        fBottom: 50,
      ),
      0,
      100,
      true,
      SkPaint(),
    );
  });

  test('drawAtlas', () {
    final SkAnimatedImage image = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
    canvas.drawAtlas(
      image.getCurrentFrame(),
      Float32List.fromList([0, 0, 1, 1]),
      Float32List.fromList([1, 0, 2, 3]),
      SkPaint(),
      canvasKit.BlendMode.SrcOver,
      [
        Float32List.fromList([0, 0, 0, 1]),
        Float32List.fromList([1, 1, 1, 1]),
      ],
    );
  });

  test('drawCircle', () {
    canvas.drawCircle(1, 2, 3, SkPaint());
  });

  test('drawColorInt', () {
    canvas.drawColorInt(0xFFFFFFFF, canvasKit.BlendMode.SoftLight);
  });

  test('drawDRRect', () {
    canvas.drawDRRect(
      SkRRect(
        rect: SkRect(
          fLeft: 0,
          fTop: 0,
          fRight: 100,
          fBottom: 100,
        ),
        rx1: 1,
        ry1: 2,
        rx2: 3,
        ry2: 4,
        rx3: 5,
        ry3: 6,
        rx4: 7,
        ry4: 8,
      ),
      SkRRect(
        rect: SkRect(
          fLeft: 20,
          fTop: 20,
          fRight: 80,
          fBottom: 80,
        ),
        rx1: 1,
        ry1: 2,
        rx2: 3,
        ry2: 4,
        rx3: 5,
        ry3: 6,
        rx4: 7,
        ry4: 8,
      ),
      SkPaint(),
    );
  });

  test('drawImage', () {
    final SkAnimatedImage image = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
    canvas.drawImage(
      image.getCurrentFrame(),
      10,
      20,
      SkPaint(),
    );
  });

  test('drawImageRect', () {
    final SkAnimatedImage image = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
    canvas.drawImageRect(
      image.getCurrentFrame(),
      SkRect(fLeft: 0, fTop: 0, fRight: 1, fBottom: 1),
      SkRect(fLeft: 0, fTop: 0, fRight: 1, fBottom: 1),
      SkPaint(),
      false,
    );
  });

  test('drawImageNine', () {
    final SkAnimatedImage image = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
    canvas.drawImageNine(
      image.getCurrentFrame(),
      SkRect(fLeft: 0, fTop: 0, fRight: 1, fBottom: 1),
      SkRect(fLeft: 0, fTop: 0, fRight: 1, fBottom: 1),
      SkPaint(),
    );
  });

  test('drawLine', () {
    canvas.drawLine(0, 1, 2, 3, SkPaint());
  });

  test('drawOval', () {
    canvas.drawOval(SkRect(fLeft: 0, fTop: 0, fRight: 1, fBottom: 1), SkPaint());
  });

  test('drawPaint', () {
    canvas.drawPaint(SkPaint());
  });

  test('drawPath', () {
    canvas.drawPath(
      _testClosedSkPath(),
      SkPaint(),
    );
  });

  test('drawPoints', () {
    canvas.drawPoints(
      canvasKit.PointMode.Lines,
      Float32List.fromList([0, 0, 10, 10, 0, 10]),
      SkPaint(),
    );
  });

  test('drawRRect', () {
    canvas.drawRRect(
      SkRRect(
        rect: SkRect(
          fLeft: 0,
          fTop: 0,
          fRight: 100,
          fBottom: 100,
        ),
        rx1: 1,
        ry1: 2,
        rx2: 3,
        ry2: 4,
        rx3: 5,
        ry3: 6,
        rx4: 7,
        ry4: 8,
      ),
      SkPaint(),
    );
  });

  test('drawRect', () {
    canvas.drawRect(
      SkRect(
        fLeft: 0,
        fTop: 0,
        fRight: 100,
        fBottom: 100,
      ),
      SkPaint(),
    );
  });

  test('drawShadow', () {
    for (int flags in const <int>[0x01, 0x00]) {
      const double devicePixelRatio = 2.0;
      const double elevation = 4.0;
      const double ambientAlpha = 0.039;
      const double spotAlpha = 0.25;

      final SkPath path = _testClosedSkPath();
      final ui.Rect bounds = path.getBounds().toRect();
      final double shadowX = (bounds.left + bounds.right) / 2.0;
      final double shadowY = bounds.top - 600.0;

      const ui.Color color = ui.Color(0xAABBCCDD);
      ui.Color inAmbient = color.withAlpha((color.alpha * ambientAlpha).round());
      ui.Color inSpot = color.withAlpha((color.alpha * spotAlpha).round());

      final SkTonalColors inTonalColors = SkTonalColors(
        ambient: makeFreshSkColor(inAmbient),
        spot: makeFreshSkColor(inSpot),
      );

      final SkTonalColors tonalColors =
          canvasKit.computeTonalColors(inTonalColors);

      canvas.drawShadow(
        path,
        Float32List(3)
          ..[2] = devicePixelRatio * elevation,
        Float32List(3)
          ..[0] = shadowX
          ..[1] = shadowY
          ..[2] = devicePixelRatio * kLightHeight,
        devicePixelRatio * kLightRadius,
        tonalColors.ambient,
        tonalColors.spot,
        flags,
      );
    }
  });

  test('drawVertices', () {
    canvas.drawVertices(
      _testVertices(),
      canvasKit.BlendMode.SrcOver,
      SkPaint(),
    );
  });

  test('rotate', () {
    canvas.rotate(5, 10, 20);
  });

  test('scale', () {
    canvas.scale(2, 3);
  });

  test('skew', () {
    canvas.skew(4, 5);
  });

  test('concat', () {
    canvas.concat(toSkMatrixFromFloat32(Matrix4.identity().storage));
  });

  test('translate', () {
    canvas.translate(4, 5);
  });

  test('flush', () {
    canvas.flush();
  });

  test('drawPicture', () {
    final SkPictureRecorder otherRecorder = SkPictureRecorder();
    final SkCanvas otherCanvas = otherRecorder.beginRecording(SkRect(
      fLeft: 0,
      fTop: 0,
      fRight: 100,
      fBottom: 100,
    ));
    otherCanvas.drawLine(0, 0, 10, 10, SkPaint());
    canvas.drawPicture(otherRecorder.finishRecordingAsPicture());
  });

  test('drawParagraph', () {
    final CkParagraphBuilder builder = CkParagraphBuilder(
      CkParagraphStyle(),
    );
    builder.addText('Hello');
    final CkParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 100));
    canvas.drawParagraph(
      paragraph.skiaObject,
      10,
      20,
    );
  });
}
