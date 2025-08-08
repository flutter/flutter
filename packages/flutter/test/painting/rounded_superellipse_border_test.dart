// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_matchers.dart';

void main() {
  test('RoundedSuperellipseBorder defaults', () {
    const RoundedSuperellipseBorder border = RoundedSuperellipseBorder();
    expect(border.side, BorderSide.none);
    expect(border.borderRadius, BorderRadius.zero);
  });

  test('RoundedSuperellipseBorder copyWith, ==, hashCode', () {
    expect(const RoundedSuperellipseBorder(), const RoundedSuperellipseBorder().copyWith());
    expect(
      const RoundedSuperellipseBorder().hashCode,
      const RoundedSuperellipseBorder().copyWith().hashCode,
    );
    const BorderSide side = BorderSide(width: 10.0, color: Color(0xff123456));
    const BorderRadius radius = BorderRadius.all(Radius.circular(16.0));
    const BorderRadiusDirectional directionalRadius = BorderRadiusDirectional.all(
      Radius.circular(16.0),
    );

    expect(
      const RoundedSuperellipseBorder().copyWith(side: side, borderRadius: radius),
      const RoundedSuperellipseBorder(side: side, borderRadius: radius),
    );

    expect(
      const RoundedSuperellipseBorder().copyWith(side: side, borderRadius: directionalRadius),
      const RoundedSuperellipseBorder(side: side, borderRadius: directionalRadius),
    );
  });

  test('RoundedSuperellipseBorder', () {
    const RoundedSuperellipseBorder c10 = RoundedSuperellipseBorder(
      side: BorderSide(width: 10.0),
      borderRadius: BorderRadius.all(Radius.circular(100.0)),
    );
    const RoundedSuperellipseBorder c15 = RoundedSuperellipseBorder(
      side: BorderSide(width: 15.0),
      borderRadius: BorderRadius.all(Radius.circular(150.0)),
    );
    const RoundedSuperellipseBorder c20 = RoundedSuperellipseBorder(
      side: BorderSide(width: 20.0),
      borderRadius: BorderRadius.all(Radius.circular(200.0)),
    );
    expect(c10.dimensions, const EdgeInsets.all(10.0));
    expect(c10.scale(2.0), c20);
    expect(c20.scale(0.5), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.0), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.5), c15);
    expect(ShapeBorder.lerp(c10, c20, 1.0), c20);

    const RoundedSuperellipseBorder c1 = RoundedSuperellipseBorder(
      side: BorderSide(),
      borderRadius: BorderRadius.all(Radius.circular(1.0)),
    );
    const RoundedSuperellipseBorder c2 = RoundedSuperellipseBorder(
      side: BorderSide(),
      borderRadius: BorderRadius.all(Radius.circular(2.0)),
    );
    expect(c2.getInnerPath(Rect.fromCircle(center: Offset.zero, radius: 2.0)), isUnitCircle);
    expect(c1.getOuterPath(Rect.fromCircle(center: Offset.zero, radius: 1.0)), isUnitCircle);
    const Rect rect = Rect.fromLTRB(10.0, 20.0, 80.0, 190.0);
    expect(
      (Canvas canvas) => c10.paint(canvas, rect),
      paints..rsuperellipse(
        rsuperellipse: RSuperellipse.fromRectAndRadius(
          rect.deflate(5.0),
          const Radius.circular(95.0),
        ),
        strokeWidth: 10.0,
      ),
    );

    const RoundedSuperellipseBorder directional = RoundedSuperellipseBorder(
      borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(20)),
    );
    expect(ShapeBorder.lerp(directional, c10, 1.0), ShapeBorder.lerp(c10, directional, 0.0));
  });

  test('RoundedSuperellipseBorder and CircleBorder', () {
    const RoundedSuperellipseBorder r = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    );
    const CircleBorder c = CircleBorder();
    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 20.0); // center is x=40..60 y=10
    final Matcher looksLikeR = isPathThat(
      includes: const <Offset>[Offset(30.0, 10.0), Offset(50.0, 10.0)],
      excludes: const <Offset>[Offset(1.0, 1.0), Offset(99.0, 19.0)],
    );
    final Matcher looksLikeC = isPathThat(
      includes: const <Offset>[Offset(50.0, 10.0)],
      excludes: const <Offset>[Offset(1.0, 1.0), Offset(30.0, 10.0), Offset(99.0, 19.0)],
    );
    expect(r.getOuterPath(rect), looksLikeR);
    expect(c.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(r, c, 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(r, c, 0.9)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.9), r, 0.1)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.9), r, 0.9)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), c, 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), c, 0.9)!.getOuterPath(rect), looksLikeC);
    expect(
      ShapeBorder.lerp(
        ShapeBorder.lerp(r, c, 0.1),
        ShapeBorder.lerp(r, c, 0.9),
        0.1,
      )!.getOuterPath(rect),
      looksLikeR,
    );
    expect(
      ShapeBorder.lerp(
        ShapeBorder.lerp(r, c, 0.1),
        ShapeBorder.lerp(r, c, 0.9),
        0.9,
      )!.getOuterPath(rect),
      looksLikeC,
    );
    expect(ShapeBorder.lerp(r, ShapeBorder.lerp(r, c, 0.9), 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(r, ShapeBorder.lerp(r, c, 0.9), 0.9)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(c, ShapeBorder.lerp(r, c, 0.1), 0.1)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(c, ShapeBorder.lerp(r, c, 0.1), 0.9)!.getOuterPath(rect), looksLikeR);

    expect(
      ShapeBorder.lerp(r, c, 0.1).toString(),
      'RoundedSuperellipseBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(10.0), 10.0% of the way to being a CircleBorder)',
    );
    expect(
      ShapeBorder.lerp(r, c, 0.2).toString(),
      'RoundedSuperellipseBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(10.0), 20.0% of the way to being a CircleBorder)',
    );
    expect(
      ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), ShapeBorder.lerp(r, c, 0.9), 0.9).toString(),
      'RoundedSuperellipseBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(10.0), 82.0% of the way to being a CircleBorder)',
    );

    expect(
      ShapeBorder.lerp(c, r, 0.9).toString(),
      'RoundedSuperellipseBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(10.0), 10.0% of the way to being a CircleBorder)',
    );
    expect(
      ShapeBorder.lerp(c, r, 0.8).toString(),
      'RoundedSuperellipseBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(10.0), 20.0% of the way to being a CircleBorder)',
    );
    expect(
      ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.9), ShapeBorder.lerp(r, c, 0.1), 0.1).toString(),
      'RoundedSuperellipseBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(10.0), 82.0% of the way to being a CircleBorder)',
    );

    expect(ShapeBorder.lerp(r, c, 0.1), ShapeBorder.lerp(r, c, 0.1));
    expect(ShapeBorder.lerp(r, c, 0.1).hashCode, ShapeBorder.lerp(r, c, 0.1).hashCode);

    final ShapeBorder direct50 = ShapeBorder.lerp(r, c, 0.5)!;
    final ShapeBorder indirect50 = ShapeBorder.lerp(
      ShapeBorder.lerp(c, r, 0.1),
      ShapeBorder.lerp(c, r, 0.9),
      0.5,
    )!;
    expect(direct50, indirect50);
    expect(direct50.hashCode, indirect50.hashCode);
    expect(direct50.toString(), indirect50.toString());
  });

  test('RoundedSuperellipseBorder.dimensions and CircleBorder.dimensions', () {
    const RoundedSuperellipseBorder insideRoundedSuperellipseBorder = RoundedSuperellipseBorder(
      side: BorderSide(width: 10),
    );
    expect(insideRoundedSuperellipseBorder.dimensions, const EdgeInsets.all(10));

    const RoundedSuperellipseBorder centerRoundedSuperellipseBorder = RoundedSuperellipseBorder(
      side: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
    );
    expect(centerRoundedSuperellipseBorder.dimensions, const EdgeInsets.all(5));

    const RoundedSuperellipseBorder outsideRoundedSuperellipseBorder = RoundedSuperellipseBorder(
      side: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignOutside),
    );
    expect(outsideRoundedSuperellipseBorder.dimensions, EdgeInsets.zero);

    const CircleBorder insideCircleBorder = CircleBorder(side: BorderSide(width: 10));
    expect(insideCircleBorder.dimensions, const EdgeInsets.all(10));

    const CircleBorder centerCircleBorder = CircleBorder(
      side: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
    );
    expect(centerCircleBorder.dimensions, const EdgeInsets.all(5));

    const CircleBorder outsideCircleBorder = CircleBorder(
      side: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignOutside),
    );
    expect(outsideCircleBorder.dimensions, EdgeInsets.zero);
  });

  test('RoundedSuperellipseBorder.lerp with different StrokeAlign', () {
    const RoundedSuperellipseBorder rInside = RoundedSuperellipseBorder(
      side: BorderSide(width: 10.0),
    );
    const RoundedSuperellipseBorder rOutside = RoundedSuperellipseBorder(
      side: BorderSide(width: 20.0, strokeAlign: BorderSide.strokeAlignOutside),
    );
    const RoundedSuperellipseBorder rCenter = RoundedSuperellipseBorder(
      side: BorderSide(width: 15.0, strokeAlign: BorderSide.strokeAlignCenter),
    );
    expect(ShapeBorder.lerp(rInside, rOutside, 0.5), rCenter);
  });

  testWidgets('RoundedSuperellipseBorder looks correct', (WidgetTester tester) async {
    Widget containerWithBorder(Size size, BorderRadiusGeometry radius) {
      return Center(
        child: Container(
          height: size.height,
          width: size.width,
          decoration: ShapeDecoration(
            color: const Color.fromARGB(255, 120, 120, 120),
            shape: RoundedSuperellipseBorder(
              side: const BorderSide(color: Color.fromARGB(255, 255, 0, 0), width: 4.0),
              borderRadius: radius,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(containerWithBorder(const Size(120, 300), BorderRadius.zero));
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.rounded_superellipse_border.all_zero.png'),
    );

    await tester.pumpWidget(
      containerWithBorder(const Size(120, 300), const BorderRadius.all(Radius.circular(36))),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.rounded_superellipse_border.all_circular.png'),
    );

    await tester.pumpWidget(
      containerWithBorder(const Size(120, 300), const BorderRadius.all(Radius.elliptical(20, 50))),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.rounded_superellipse_border.all_elliptical.png'),
    );

    await tester.pumpWidget(
      containerWithBorder(const Size(120, 300), const BorderRadius.all(Radius.circular(600))),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.rounded_superellipse_border.clamping_uniform.png'),
    );

    await tester.pumpWidget(
      containerWithBorder(
        const Size(120, 300),
        const BorderRadius.only(
          topLeft: Radius.elliptical(1000, 1000),
          topRight: Radius.elliptical(0, 1000),
          bottomRight: Radius.elliptical(800, 1000),
          bottomLeft: Radius.elliptical(100, 500),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.rounded_superellipse_border.clamping_non_uniform.png'),
    );

    // Regression test for https://github.com/flutter/flutter/issues/170593
    await tester.pumpWidget(
      containerWithBorder(
        const Size(120, 300),
        const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.rounded_superellipse_border.regression_1.png'),
    );
  });
}
