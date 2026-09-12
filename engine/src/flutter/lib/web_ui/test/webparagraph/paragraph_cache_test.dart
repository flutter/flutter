// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  const region = Rect.fromLTWH(0, 0, 500, 500);
  const epsilon = 1e-5;
  final Float64List identityTransform = Matrix4.identity().toFloat64();
  setUpUnitTests();

  test('WebParagraph snaps physical offset to integer device pixels and renders 1:1', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      for (final dpr in <double>[1.0, 1.5, 2.0, 2.5]) {
        EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(dpr);

        final arialStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
        final builder = WebParagraphBuilder(arialStyle);
        builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
        builder.addText('Pixel snapped text');
        final WebParagraph paragraph = builder.build();
        paragraph.layout(const ParagraphConstraints(width: double.infinity));

        // Test positive fractional offset
        const positiveOffset = Offset(10.25, 20.75);
        final (Rect sourceRect, Rect targetRect, Offset canvas2dShift) = calculateParagraph(
          paragraph,
          positiveOffset,
          ParagraphTransform.from(identityTransform, dpr),
        );

        // Verify sourceRect dimensions are exact integers in physical pixels
        expect(sourceRect.width % 1.0, closeTo(0.0, epsilon));
        expect(sourceRect.height % 1.0, closeTo(0.0, epsilon));

        // Verify targetRect in logical units matches sourceRect physical dimensions when scaled by dpr
        expect(targetRect.width * dpr, closeTo(sourceRect.width, epsilon));
        expect(targetRect.height * dpr, closeTo(sourceRect.height, epsilon));

        // Verify canvas2dShift corresponds to an exact integer physical shift
        final double sourcePhysicalShiftX = canvas2dShift.dx * dpr;
        expect(sourcePhysicalShiftX % 1.0, closeTo(0.0, epsilon));

        final double sourcePhysicalShiftY = canvas2dShift.dy * dpr;
        expect(sourcePhysicalShiftY % 1.0, closeTo(0.0, epsilon));

        // Verify destination screen physical coordinates are exact integers
        final double targetPhysicalX = targetRect.left * dpr;
        final double targetPhysicalY = targetRect.top * dpr;
        expect(targetPhysicalX % 1.0, closeTo(0.0, epsilon));
        expect(targetPhysicalY % 1.0, closeTo(0.0, epsilon));

        // Test negative fractional offset (e.g. text scrolling partially off screen)
        const negativeOffset = Offset(-5.65, -10.25);
        final (
          Rect negSourceRect,
          Rect negTargetRect,
          Offset negCanvas2dShift,
        ) = calculateParagraph(
          paragraph,
          negativeOffset,
          ParagraphTransform.from(identityTransform, dpr),
        );

        expect(negSourceRect.width % 1.0, closeTo(0.0, epsilon));
        expect(negSourceRect.height % 1.0, closeTo(0.0, epsilon));
        expect(negTargetRect.width * dpr, closeTo(negSourceRect.width, epsilon));
        expect(negTargetRect.height * dpr, closeTo(negSourceRect.height, epsilon));
        expect((negTargetRect.left * dpr) % 1.0, closeTo(0.0, epsilon));
        expect((negTargetRect.top * dpr) % 1.0, closeTo(0.0, epsilon));
        expect((negCanvas2dShift.dx * dpr) % 1.0, closeTo(0.0, epsilon));
        expect((negCanvas2dShift.dy * dpr) % 1.0, closeTo(0.0, epsilon));
      }
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('WebParagraph calculateParagraph with transform scales and translations', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      const dpr = 1.0;
      final arialStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
      final builder = WebParagraphBuilder(arialStyle);
      builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
      builder.addText('Test scaling and translation');
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 200));

      const offset = Offset(10.35, 20.65);

      // Matrix with scale 1.5x, 2.0y and translation (30.25, 40.75)
      final transform = Float64List.fromList(<double>[
        1.5,
        0.0,
        0.0,
        0.0,
        0.0,
        2.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        30.25,
        40.75,
        0.0,
        1.0,
      ]);

      final (Rect sourceRect, Rect targetRect, Offset canvas2dShift) = calculateParagraph(
        paragraph,
        offset,
        ParagraphTransform.from(transform, dpr),
      );

      const double effectiveScaleX = dpr * 1.5;
      const double effectiveScaleY = dpr * 2.0;

      // Verify sourceRect dimensions are exact integers in physical pixels
      expect(sourceRect.width % 1.0, closeTo(0.0, epsilon));
      expect(sourceRect.height % 1.0, closeTo(0.0, epsilon));

      // Verify targetRect logical size corresponds to sourceRect / effectiveScale
      expect(targetRect.width * effectiveScaleX, closeTo(sourceRect.width, epsilon));
      expect(targetRect.height * effectiveScaleY, closeTo(sourceRect.height, epsilon));

      // Verify Canvas2D shift is exact integer physical pixels
      expect((canvas2dShift.dx * effectiveScaleX) % 1.0, closeTo(0.0, epsilon));
      expect((canvas2dShift.dy * effectiveScaleY) % 1.0, closeTo(0.0, epsilon));

      // Verify screen destination coordinates are exact integers
      final double screenX = targetRect.left * effectiveScaleX + 30.25 * dpr;
      final double screenY = targetRect.top * effectiveScaleY + 40.75 * dpr;
      expect(screenX % 1.0, closeTo(0.0, epsilon));
      expect(screenY % 1.0, closeTo(0.0, epsilon));
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test(
    'WebParagraph unified scale cache policy reuses cache across arbitrary offset shifts',
    () async {
      final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
      try {
        EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

        final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
        builder.addText('Unified Scale Cache Test');
        final paragraph = builder.build() as WebParagraph;
        paragraph.layout(const ParagraphConstraints(width: 300));

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder, region);

        // Initial paint rasterizes once (count: 0 -> 1)
        expect(paragraph.debugRasterizeCount, 0);
        paragraph.paint(canvas, const Offset(10.1, 20.1));
        expect(paragraph.debugPainter.hasCache, isTrue);
        expect(paragraph.debugRasterizeCount, 1);

        // Same offset: cache hit (count: 1 -> 1)
        paragraph.paint(canvas, const Offset(10.1, 20.1));
        expect(paragraph.debugRasterizeCount, 1);

        // Small fractional shift: cache hit (count: 1 -> 1)
        paragraph.paint(canvas, const Offset(10.35, 20.35));
        expect(paragraph.debugRasterizeCount, 1);

        // Different fractional shift: cache hit (count: 1 -> 1)
        paragraph.paint(canvas, const Offset(10.6, 20.6));
        expect(paragraph.debugRasterizeCount, 1);

        // Negative offset shift: cache hit (count: 1 -> 1)
        paragraph.paint(canvas, const Offset(-5.75, -12.4));
        expect(paragraph.debugRasterizeCount, 1);

        // Large scrolling jump: cache hit (count: 1 -> 1)
        paragraph.paint(canvas, const Offset(100.85, 250.75));
        expect(paragraph.debugRasterizeCount, 1);

        // Jump back to original offset: cache hit (count: 1 -> 1)
        paragraph.paint(canvas, const Offset(10.1, 20.1));
        expect(paragraph.debugRasterizeCount, 1);
      } finally {
        EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
      }
    },
  );

  test('WebParagraph cache policy across different device pixel ratios', () async {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
      builder.addText('Static DPR Caching Test');
      final paragraph = builder.build() as WebParagraph;
      paragraph.layout(const ParagraphConstraints(width: 300));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);

      // DPR = 1.0
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      expect(paragraph.debugRasterizeCount, 0);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);

      // Moving offset at same DPR = 1.0 reuses cache
      paragraph.paint(canvas, const Offset(10.35, 20.35));
      expect(paragraph.debugRasterizeCount, 1);

      // DPR = 2.0 -> scale mismatch forces re-rasterization
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.0);
      paragraph.paint(canvas, const Offset(10.35, 20.35));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 2);

      // Moving offset at same DPR = 2.0 reuses cache
      paragraph.paint(canvas, const Offset(50.85, 60.85));
      expect(paragraph.debugRasterizeCount, 2);

      // DPR = 1.5 -> scale mismatch forces re-rasterization
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.5);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 3);

      // Moving offset at same DPR = 1.5 reuses cache
      paragraph.paint(canvas, const Offset(10.25, 20.25));
      expect(paragraph.debugRasterizeCount, 3);
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test(
    'WebParagraph sourceRect includes antialiasing safety padding to prevent glyph clipping',
    () {
      final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
      try {
        EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
        final style = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
        final builder = WebParagraphBuilder(style);
        builder.addText('gjy_');
        final WebParagraph paragraph = builder.build();
        paragraph.layout(const ParagraphConstraints(width: 200));

        final (Rect sourceRect, Rect targetRect, Offset canvas2dShift) = calculateParagraph(
          paragraph,
          Offset.zero,
          ParagraphTransform.from(identityTransform, 1.0),
        );

        const kAntialiasingPadding = 2.0;
        final double shiftPhysicalX = (-paragraph.paintBounds.left + kAntialiasingPadding)
            .ceilToDouble();
        final double shiftPhysicalY = (-paragraph.paintBounds.top + kAntialiasingPadding)
            .ceilToDouble();
        final double expectedWidth =
            (shiftPhysicalX + paragraph.paintBounds.right + kAntialiasingPadding).ceilToDouble();
        final double expectedHeight =
            (shiftPhysicalY + paragraph.paintBounds.bottom + kAntialiasingPadding).ceilToDouble();

        expect(sourceRect.width, closeTo(expectedWidth, epsilon));
        expect(sourceRect.height, closeTo(expectedHeight, epsilon));
      } finally {
        EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
      }
    },
  );

  test('WebParagraph invalidates cache when canvas transform scale changes', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
      builder.addText('Scale Zoom Test');
      final paragraph = builder.build() as WebParagraph;
      paragraph.layout(const ParagraphConstraints(width: 300));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);

      // Identity scale (1.0x) -> Rasterize #1
      canvas.save();
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);

      // Same scale -> cache hit
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugRasterizeCount, 1);
      canvas.restore();

      // Zoom to 1.25x scale -> scale mismatch invalidates cache -> Rasterize #2
      canvas.save();
      canvas.scale(1.25, 1.25);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 2);

      // Same 1.25x scale -> cache hit
      paragraph.paint(canvas, const Offset(15.0, 25.0));
      expect(paragraph.debugRasterizeCount, 2);
      canvas.restore();

      // Zoom to 0.75x scale -> scale mismatch invalidates cache -> Rasterize #3
      canvas.save();
      canvas.scale(0.75, 0.75);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 3);

      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugRasterizeCount, 3);
      canvas.restore();
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('WebParagraph clearPaintCache resets cache and forces fresh rasterization', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
      builder.addText('ClearCache Test');
      final paragraph = builder.build() as WebParagraph;
      paragraph.layout(const ParagraphConstraints(width: 300));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);

      // Initial paint -> Rasterize #1
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);

      // clearPaintCache() resets cache to null
      paragraph.clearPaintCache();
      expect(paragraph.debugPainter.hasCache, isFalse);

      // Next paint forces fresh rasterization -> Rasterize #2
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 2);
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('WebParagraph handles non-uniform canvas scale and complex transforms', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
      builder.addText('Non-uniform Scale Test');
      final paragraph = builder.build() as WebParagraph;
      paragraph.layout(const ParagraphConstraints(width: 300));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);

      // Identity scale (1.0, 1.0) -> Rasterize #1
      canvas.save();
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);
      canvas.restore();

      // Non-uniform scale (1.5x, 0.8y) -> Scale mismatch invalidates cache -> Rasterize #2
      canvas.save();
      canvas.scale(1.5, 0.8);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 2);

      // Repaint at same non-uniform scale (1.5x, 0.8y) -> Cache hit
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 2);
      canvas.restore();

      // Non-uniform scale with different ratio (0.8x, 1.5y) -> Invalidation -> Rasterize #3
      canvas.save();
      canvas.scale(0.8, 1.5);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 3);
      canvas.restore();
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('WebParagraph handles empty text paragraph gracefully', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
      builder.addText('');
      final paragraph = builder.build() as WebParagraph;
      paragraph.layout(const ParagraphConstraints(width: 300));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);

      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugRasterizeCount, 0);
      expect(paragraph.debugPainter.hasCache, isFalse);
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('WebParagraph handles canvas rotation and reuses cache when scale matches', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto', fontSize: 16));
      builder.addText('Canvas Rotation Test');
      final paragraph = builder.build() as WebParagraph;
      paragraph.layout(const ParagraphConstraints(width: 300));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);

      // Initial paint at identity transform (0 radians) -> Rasterize #1
      canvas.save();
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);

      // Repaint at identity transform -> Cache hit
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);
      canvas.restore();

      // Rotate canvas by π/4 (45 degrees) -> Rotation preserves scale (1.0x) -> Cache hit!
      canvas.save();
      canvas.rotate(math.pi / 4);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);

      // Repaint at same π/4 rotation -> Cache hit
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);
      canvas.restore();

      // Rotate canvas by π/2 (90 degrees) -> Rotation preserves scale (1.0x) -> Cache hit!
      canvas.save();
      canvas.rotate(math.pi / 2);
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);
      canvas.restore();

      // Restore canvas to identity transform -> Cache hit!
      paragraph.paint(canvas, const Offset(10.0, 20.0));
      expect(paragraph.debugPainter.hasCache, isTrue);
      expect(paragraph.debugRasterizeCount, 1);
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('WebParagraph snaps background rects to integer physical device pixels without gaps', () {
    for (final dpr in <double>[1.0, 1.5, 2.0, 2.5]) {
      const scaleX = 1.25;
      const scaleY = 1.25;
      final double effectiveScaleX = dpr * scaleX;
      final double effectiveScaleY = dpr * scaleY;
      const transformX = 15.35;
      const transformY = 25.65;

      // Two adjacent blocks on the same line: block1 ends where block2 begins
      const block1Rect = Rect.fromLTRB(10.25, 20.35, 35.65, 45.85);
      const block2Rect = Rect.fromLTRB(35.65, 20.35, 70.15, 45.85);

      final transform = ParagraphTransform(
        effectiveScaleX: effectiveScaleX,
        effectiveScaleY: effectiveScaleY,
        transformX: transformX,
        transformY: transformY,
        devicePixelRatio: dpr,
      );
      final Rect snapped1 = transform.snapRect(block1Rect);
      final Rect snapped2 = transform.snapRect(block2Rect);

      // Verify physical screen coordinates are exact integers
      final double physLeft1 = snapped1.left * effectiveScaleX + transformX * dpr;
      final double physRight1 = snapped1.right * effectiveScaleX + transformX * dpr;
      final double physTop1 = snapped1.top * effectiveScaleY + transformY * dpr;
      final double physBottom1 = snapped1.bottom * effectiveScaleY + transformY * dpr;

      expect(physLeft1 % 1.0, closeTo(0.0, epsilon));
      expect(physRight1 % 1.0, closeTo(0.0, epsilon));
      expect(physTop1 % 1.0, closeTo(0.0, epsilon));
      expect(physBottom1 % 1.0, closeTo(0.0, epsilon));

      final double physLeft2 = snapped2.left * effectiveScaleX + transformX * dpr;
      final double physRight2 = snapped2.right * effectiveScaleX + transformX * dpr;
      final double physTop2 = snapped2.top * effectiveScaleY + transformY * dpr;
      final double physBottom2 = snapped2.bottom * effectiveScaleY + transformY * dpr;

      expect(physLeft2 % 1.0, closeTo(0.0, epsilon));
      expect(physRight2 % 1.0, closeTo(0.0, epsilon));
      expect(physTop2 % 1.0, closeTo(0.0, epsilon));
      expect(physBottom2 % 1.0, closeTo(0.0, epsilon));

      // Verify seamless boundary between adjacent blocks (no gap, no overlap)
      expect(physRight1, closeTo(physLeft2, epsilon));
      expect(snapped1.right, closeTo(snapped2.left, epsilon));
    }
  });

  test('ParagraphTransform correctly extracts scale from matrix and handles rotations and translations', () {
    const dpr = 2.0;

    // Identity transform
    final identity = Float64List.fromList(<double>[
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
    ]);
    final idTransform = ParagraphTransform.from(identity, dpr);
    expect(idTransform.effectiveScaleX, closeTo(2.0, epsilon));
    expect(idTransform.effectiveScaleY, closeTo(2.0, epsilon));
    expect(idTransform.transformX, closeTo(0.0, epsilon));
    expect(idTransform.transformY, closeTo(0.0, epsilon));

    // Translation only (not identity)
    final translation = Float64List.fromList(<double>[
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      10.0,
      20.0,
      0.0,
      1.0,
    ]);
    final transTransform = ParagraphTransform.from(translation, dpr);
    expect(transTransform.effectiveScaleX, closeTo(2.0, epsilon));
    expect(transTransform.effectiveScaleY, closeTo(2.0, epsilon));
    expect(transTransform.transformX, closeTo(10.0, epsilon));
    expect(transTransform.transformY, closeTo(20.0, epsilon));

    // Uniform scale 1.5x
    final uniform = Float64List.fromList(<double>[
      1.5,
      0.0,
      0.0,
      0.0,
      0.0,
      1.5,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      10.0,
      20.0,
      0.0,
      1.0,
    ]);
    final uniTransform = ParagraphTransform.from(uniform, dpr);
    expect(uniTransform.effectiveScaleX, closeTo(3.0, epsilon));
    expect(uniTransform.effectiveScaleY, closeTo(3.0, epsilon));

    // 45 degree rotation: cos(pi/4) = sin(pi/4) = 1/sqrt(2)
    final double cos45 = math.cos(math.pi / 4);
    final double sin45 = math.sin(math.pi / 4);
    final rot45 = Float64List.fromList(<double>[
      cos45,
      sin45,
      0.0,
      0.0,
      -sin45,
      cos45,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
    ]);
    final rotTransform = ParagraphTransform.from(rot45, dpr);
    expect(rotTransform.effectiveScaleX, closeTo(2.0, epsilon));
    expect(rotTransform.effectiveScaleY, closeTo(2.0, epsilon));

    // Non-uniform scale with zero fallback
    final nonUniformZero = Float64List.fromList(<double>[
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      2.5,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
    ]);
    final nzTransform = ParagraphTransform.from(nonUniformZero, dpr);
    expect(nzTransform.effectiveScaleX, closeTo(2.0, epsilon)); // fallback to 1.0 * dpr
    expect(nzTransform.effectiveScaleY, closeTo(5.0, epsilon));
  });

  test('CanvasKit canvas.getTransform() returns logical coordinates independent of DPR', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.5);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);
      canvas.translate(10.0, 20.0);
      canvas.scale(2.0, 3.0);

      final Float64List matrix = canvas.getTransform();

      // If getTransform() included DPR (2.5), translation would be (25.0, 50.0)
      // and scale would be (5.0, 7.5).
      // In reality, it records purely in logical coordinates:
      expect(matrix[12], closeTo(10.0, epsilon));
      expect(matrix[13], closeTo(20.0, epsilon));
      expect(matrix[0], closeTo(2.0, epsilon));
      expect(matrix[5], closeTo(3.0, epsilon));
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });
}
