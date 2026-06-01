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

  test('ShapeDecoration.lerp between gradient and color does not throw', () {
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

    // color and gradient are mutually exclusive, so only one of them is set at
    // any point during the interpolation: the source's fill type is used before
    // the half-way point and the target's after it.
    final ShapeDecoration beforeMid =
        ShapeDecoration.lerp(colorDecoration, gradientDecoration, 0.49)!;
    expect(beforeMid.color, isNotNull);
    expect(beforeMid.gradient, isNull);

    final ShapeDecoration afterMid =
        ShapeDecoration.lerp(colorDecoration, gradientDecoration, 0.5)!;
    expect(afterMid.color, isNull);
    expect(afterMid.gradient, isNotNull);

    // Interpolating across the full range never violates the color/gradient
    // invariant (which would otherwise throw an assertion).
    for (final t in <double>[0.1, 0.25, 0.49, 0.5, 0.51, 0.75, 0.9]) {
      expect(ShapeDecoration.lerp(colorDecoration, gradientDecoration, t), isNotNull);
      // Also exercise the reverse direction (gradient -> color).
      expect(ShapeDecoration.lerp(gradientDecoration, colorDecoration, t), isNotNull);
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
