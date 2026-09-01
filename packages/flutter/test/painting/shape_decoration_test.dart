// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('ShapeDecoration constructor', () {
    const colorR = Color(0xffff0000);
    const colorG = Color(0xff00ff00);
    const Gradient gradient = LinearGradient(colors: <Color>[colorR, colorG]);
    expect(const ShapeDecoration(shape: Border()), const ShapeDecoration(shape: Border()));
    expect(
      () => ShapeDecoration(color: colorR, gradient: nonconst(gradient), shape: const Border()),
      throwsAssertionError,
    );
    expect(
      ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.circle)),
      const ShapeDecoration(shape: CircleBorder()),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(
        const BoxDecoration(borderRadius: BorderRadiusDirectional.all(Radius.circular(100.0))),
      ),
      const ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(100.0)),
        ),
      ),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(
        BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorG),
        ),
      ),
      const ShapeDecoration(
        shape: CircleBorder(side: BorderSide(color: colorG)),
      ),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(BoxDecoration(border: Border.all(color: colorR))),
      ShapeDecoration(shape: Border.all(color: colorR)),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(
        const BoxDecoration(border: BorderDirectional(start: BorderSide())),
      ),
      const ShapeDecoration(shape: BorderDirectional(start: BorderSide())),
    );
  });

  test('ShapeDecoration.lerp identical a,b', () {
    expect(ShapeDecoration.lerp(null, null, 0), null);
    const shape = ShapeDecoration(shape: CircleBorder());
    expect(identical(ShapeDecoration.lerp(shape, shape, 0.5), shape), true);
  });

  test('ShapeDecoration.lerp null a,b', () {
    const Decoration a = ShapeDecoration(shape: CircleBorder());
    const Decoration b = ShapeDecoration(shape: RoundedRectangleBorder());
    expect(Decoration.lerp(a, null, 0.0), a);
    expect(Decoration.lerp(null, b, 0.0), b);
    expect(Decoration.lerp(null, null, 0.0), null);
  });

  test('ShapeDecoration.lerp and hit test', () {
    const Decoration a = ShapeDecoration(shape: CircleBorder());
    const Decoration b = ShapeDecoration(shape: RoundedRectangleBorder());
    const Decoration c = ShapeDecoration(shape: OvalBorder());
    expect(Decoration.lerp(a, b, 0.0), a);
    expect(Decoration.lerp(a, b, 1.0), b);
    expect(Decoration.lerp(a, c, 0.0), a);
    expect(Decoration.lerp(a, c, 1.0), c);
    expect(Decoration.lerp(b, c, 0.0), b);
    expect(Decoration.lerp(b, c, 1.0), c);
    const size = Size(200.0, 100.0); // at t=0.5, width will be 150 (x=25 to x=175).
    expect(a.hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(c.hitTest(size, const Offset(50, 5.0)), isFalse);
    expect(c.hitTest(size, const Offset(5, 30.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.1)!.hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.5)!.hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.9)!.hitTest(size, const Offset(20.0, 50.0)), isTrue);
    expect(Decoration.lerp(a, c, 0.1)!.hitTest(size, const Offset(30.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, c, 0.5)!.hitTest(size, const Offset(30.0, 50.0)), isTrue);
    expect(Decoration.lerp(a, c, 0.9)!.hitTest(size, const Offset(30.0, 50.0)), isTrue);
    expect(Decoration.lerp(b, c, 0.1)!.hitTest(size, const Offset(45.0, 10.0)), isTrue);
    expect(Decoration.lerp(b, c, 0.5)!.hitTest(size, const Offset(30.0, 10.0)), isTrue);
    expect(Decoration.lerp(b, c, 0.9)!.hitTest(size, const Offset(10.0, 30.0)), isTrue);
    expect(b.hitTest(size, const Offset(20.0, 50.0)), isTrue);
  });

  test('ShapeBorder.hitTest defaults to getOuterPath', () {
    _outerPathCount = 0;
    const ShapeBorder border = _PathHitTestBorder();
    const rect = Rect.fromLTWH(10.0, 20.0, 100.0, 50.0);

    expect(border.hitTest(rect, const Offset(20.0, 30.0)), isTrue);
    expect(border.hitTest(rect, Offset.zero), isFalse);
    expect(_outerPathCount, 2);
  });

  test('ShapeDecoration.hitTest delegates to ShapeBorder.hitTest', () {
    _hitTestCount = 0;
    const decoration = ShapeDecoration(shape: _HitTestBorder());

    expect(decoration.hitTest(const Size(100.0, 100.0), const Offset(50.0, 50.0)), isFalse);
    expect(_hitTestCount, 1);
  });

  test('ShapeBorder.hitTest matches getOuterPath for primitive shapes', () {
    const rect = Rect.fromLTWH(0.0, 0.0, 120.0, 80.0);
    const TextDirection textDirection = TextDirection.ltr;
    const positions = <Offset>[
      Offset(-10.0, 40.0), // Outside every shape.
      Offset(1.0, 1.0), // Distinguishes square and rounded corners.
      Offset(0.5, 14.5), // Distinguishes RRect and superellipse corners.
      Offset(1.0, 35.0), // Exercises the left edge of wide shapes.
      Offset(1.0, 68.0), // Exercises the directional bottom-left corner.
      Offset(11.0, 35.0), // Exercises CircleBorder eccentricity.
      Offset(14.5, 13.5), // Distinguishes interpolated outer shapes.
      Offset(21.0, 35.0), // Inside every shape.
    ];
    final borders = <ShapeBorder>[
      Border.all(),
      const CircleBorder(),
      const CircleBorder(eccentricity: 0.5),
      const OvalBorder(),
      const RoundedRectangleBorder(),
      const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18.0))),
      const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(18.0)),
      ),
      const RoundedSuperellipseBorder(),
      const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(18.0))),
      const StadiumBorder(),
      ShapeBorder.lerp(
        const CircleBorder(),
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18.0))),
        0.5,
      )!,
      ShapeBorder.lerp(
        const CircleBorder(),
        const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(18.0))),
        0.5,
      )!,
      ShapeBorder.lerp(const StadiumBorder(), const CircleBorder(), 0.5)!,
      ShapeBorder.lerp(
        const StadiumBorder(),
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18.0))),
        0.5,
      )!,
    ];

    // Every position is tested against every border, so these collections are
    // intentionally independent rather than paired test cases.
    for (final border in borders) {
      for (final position in positions) {
        expect(
          border.hitTest(rect, position, textDirection: textDirection),
          border.getOuterPath(rect, textDirection: textDirection).contains(position),
          reason: '$border at $position',
        );
      }
    }
  });

  test('_CompoundBorder.hitTest preserves child hitTest optimizations', () {
    _hitTestCount = 0;
    final ShapeBorder compoundBorder = const RoundedRectangleBorder() + const _HitTestBorder();

    expect(
      compoundBorder.hitTest(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), Offset.zero),
      isFalse,
    );
    expect(_hitTestCount, 1);
  });

  test('ShapeDecoration.lerp between gradient and color is smooth and does not throw', () {
    // Regression test for https://github.com/flutter/flutter/issues/93953
    const colorR = Color(0xffff0000);
    const colorG = Color(0xff00ff00);
    const Gradient gradient = LinearGradient(colors: <Color>[colorR, colorG]);
    const colorDecoration = ShapeDecoration(color: colorR, shape: CircleBorder());
    const gradientDecoration = ShapeDecoration(
      gradient: gradient,
      shape: RoundedRectangleBorder(),
    );

    // The end points are returned unchanged.
    expect(ShapeDecoration.lerp(colorDecoration, gradientDecoration, 0.0), colorDecoration);
    expect(ShapeDecoration.lerp(colorDecoration, gradientDecoration, 1.0), gradientDecoration);

    // In between, the color is represented as a uniform-color gradient, so the
    // result is always a gradient (and never both a color and a gradient, which
    // would otherwise throw the constructor's assertion). This yields a smooth
    // transition rather than a sudden jump at the half-way point.
    for (final t in <double>[0.1, 0.25, 0.49, 0.5, 0.51, 0.75, 0.9]) {
      final ShapeDecoration forward =
          ShapeDecoration.lerp(colorDecoration, gradientDecoration, t)!;
      expect(forward.color, isNull);
      expect(forward.gradient, isA<LinearGradient>());

      // The reverse direction (gradient -> color) behaves the same way.
      final ShapeDecoration reverse =
          ShapeDecoration.lerp(gradientDecoration, colorDecoration, t)!;
      expect(reverse.color, isNull);
      expect(reverse.gradient, isA<LinearGradient>());
    }

    // Close to the color end, the interpolated gradient is (almost) the uniform
    // start color.
    final gradientNearColor =
        ShapeDecoration.lerp(colorDecoration, gradientDecoration, 0.001)!.gradient! as LinearGradient;
    expect(gradientNearColor.colors, hasLength(2));
    for (final Color color in gradientNearColor.colors) {
      expect(color.r, closeTo(colorR.r, 0.05));
      expect(color.g, closeTo(colorR.g, 0.05));
      expect(color.b, closeTo(colorR.b, 0.05));
    }
  });

  test('ShapeDecoration.image RTL test', () async {
    final ui.Image image = await createTestImage(width: 100, height: 200);
    final log = <int>[];
    final decoration = ShapeDecoration(
      shape: const CircleBorder(),
      image: DecorationImage(
        image: TestImageProvider(image),
        alignment: AlignmentDirectional.bottomEnd,
      ),
    );
    final BoxPainter painter = decoration.createBoxPainter(() {
      log.add(0);
    });
    expect(
      (Canvas canvas) =>
          painter.paint(canvas, Offset.zero, const ImageConfiguration(size: Size(100.0, 100.0))),
      paintsAssertion,
    );
    expect(
      (Canvas canvas) {
        return painter.paint(
          canvas,
          const Offset(20.0, -40.0),
          const ImageConfiguration(size: Size(1000.0, 1000.0), textDirection: TextDirection.rtl),
        );
      },
      paints..drawImageRect(
        source: const Rect.fromLTRB(0.0, 0.0, 100.0, 200.0),
        destination: const Rect.fromLTRB(20.0, 1000.0 - 40.0 - 200.0, 20.0 + 100.0, 1000.0 - 40.0),
      ),
    );
    expect(
      (Canvas canvas) {
        return painter.paint(
          canvas,
          Offset.zero,
          const ImageConfiguration(size: Size(100.0, 200.0), textDirection: TextDirection.ltr),
        );
      },
      isNot(paints..image()), // we always use drawImageRect
    );
    expect(log, isEmpty);
  });

  test('ShapeDecoration.getClipPath', () {
    const decoration = ShapeDecoration(shape: CircleBorder());
    const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 20.0);
    final Path clipPath = decoration.getClipPath(rect, TextDirection.ltr);
    final Matcher isLookLikeExpectedPath = isPathThat(
      includes: const <Offset>[Offset(50.0, 10.0)],
      excludes: const <Offset>[Offset(1.0, 1.0), Offset(30.0, 10.0), Offset(99.0, 19.0)],
    );
    expect(clipPath, isLookLikeExpectedPath);
  });
  test('ShapeDecoration.getClipPath for oval', () {
    const decoration = ShapeDecoration(shape: OvalBorder());
    const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 50.0);
    final Path clipPath = decoration.getClipPath(rect, TextDirection.ltr);
    final Matcher isLookLikeExpectedPath = isPathThat(
      includes: const <Offset>[Offset(50.0, 10.0)],
      excludes: const <Offset>[Offset(1.0, 1.0), Offset(15.0, 1.0), Offset(99.0, 19.0)],
    );
    expect(clipPath, isLookLikeExpectedPath);
  });
}

class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider(this.image);

  final ui.Image image;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(TestImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(SynchronousFuture<ImageInfo>(ImageInfo(image: image)));
  }
}

int _outerPathCount = 0;

class _PathHitTestBorder extends ShapeBorder {
  const _PathHitTestBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    throw StateError('ShapeBorder.hitTest should not call getInnerPath.');
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    _outerPathCount += 1;
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}

int _hitTestCount = 0;

class _HitTestBorder extends ShapeBorder {
  const _HitTestBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    throw StateError('ShapeDecoration.hitTest should not call getInnerPath.');
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    throw StateError('hitTest should not call getOuterPath directly.');
  }

  @override
  bool hitTest(Rect rect, Offset position, {TextDirection? textDirection}) {
    _hitTestCount += 1;
    return false;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}
