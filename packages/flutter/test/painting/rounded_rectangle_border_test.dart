// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'common_matchers.dart';

void main() {
  test('RoundedRectangleBorder defaults', () {
    const RoundedRectangleBorder border = RoundedRectangleBorder();
    expect(border.side, BorderSide.none);
    expect(border.borderRadius, BorderRadius.zero);
  });

  test('RoundedRectangleBorder copyWith, ==, hashCode', () {
    expect(const RoundedRectangleBorder(), const RoundedRectangleBorder().copyWith());
    expect(const RoundedRectangleBorder().hashCode, const RoundedRectangleBorder().copyWith().hashCode);
    const BorderSide side = BorderSide(width: 10.0, color: Color(0xff123456));
    const BorderRadius radius = BorderRadius.all(Radius.circular(16.0));
    expect(
      const RoundedRectangleBorder().copyWith(side: side, borderRadius: radius),
      const RoundedRectangleBorder(side: side, borderRadius: radius),
    );
  });

  test('RoundedRectangleBorder', () {
    final RoundedRectangleBorder c10 = RoundedRectangleBorder(side: const BorderSide(width: 10.0), borderRadius: BorderRadius.circular(100.0));
    final RoundedRectangleBorder c15 = RoundedRectangleBorder(side: const BorderSide(width: 15.0), borderRadius: BorderRadius.circular(150.0));
    final RoundedRectangleBorder c20 = RoundedRectangleBorder(side: const BorderSide(width: 20.0), borderRadius: BorderRadius.circular(200.0));
    expect(c10.dimensions, const EdgeInsets.all(10.0));
    expect(c10.scale(2.0), c20);
    expect(c20.scale(0.5), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.0), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.5), c15);
    expect(ShapeBorder.lerp(c10, c20, 1.0), c20);

    final RoundedRectangleBorder c1 = RoundedRectangleBorder(side: const BorderSide(width: 1.0), borderRadius: BorderRadius.circular(1.0));
    final RoundedRectangleBorder c2 = RoundedRectangleBorder(side: const BorderSide(width: 1.0), borderRadius: BorderRadius.circular(2.0));
    expect(c2.getInnerPath(Rect.fromCircle(center: Offset.zero, radius: 2.0)), isUnitCircle);
    expect(c1.getOuterPath(Rect.fromCircle(center: Offset.zero, radius: 1.0)), isUnitCircle);
    const Rect rect = Rect.fromLTRB(10.0, 20.0, 80.0, 190.0);
    expect(
      (Canvas canvas) => c10.paint(canvas, rect),
      paints
        ..drrect(
          outer: RRect.fromRectAndRadius(rect, const Radius.circular(100.0)),
          inner: RRect.fromRectAndRadius(rect.deflate(10.0), const Radius.circular(90.0)),
          strokeWidth: 0.0,
        ),
    );

    const RoundedRectangleBorder directional = RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(20)),
    );
    expect(ShapeBorder.lerp(directional, c10, 1.0),
           ShapeBorder.lerp(c10, directional, 0.0));
  });

  test('RoundedRectangleBorder and CircleBorder', () {
    final RoundedRectangleBorder r = RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(10.0));
    const CircleBorder c = CircleBorder(side: BorderSide.none);
    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 20.0); // center is x=40..60 y=10
    final Matcher looksLikeR = isPathThat(
      includes: const <Offset>[ Offset(30.0, 10.0), Offset(50.0, 10.0), ],
      excludes: const <Offset>[ Offset(1.0, 1.0), Offset(99.0, 19.0), ],
    );
    final Matcher looksLikeC = isPathThat(
      includes: const <Offset>[ Offset(50.0, 10.0), ],
      excludes: const <Offset>[ Offset(1.0, 1.0), Offset(30.0, 10.0), Offset(99.0, 19.0), ],
    );
    expect(r.getOuterPath(rect), looksLikeR);
    expect(c.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(r, c, 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(r, c, 0.9)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.9), r, 0.1)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.9), r, 0.9)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), c, 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), c, 0.9)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), ShapeBorder.lerp(r, c, 0.9), 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), ShapeBorder.lerp(r, c, 0.9), 0.9)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(r, ShapeBorder.lerp(r, c, 0.9), 0.1)!.getOuterPath(rect), looksLikeR);
    expect(ShapeBorder.lerp(r, ShapeBorder.lerp(r, c, 0.9), 0.9)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(c, ShapeBorder.lerp(r, c, 0.1), 0.1)!.getOuterPath(rect), looksLikeC);
    expect(ShapeBorder.lerp(c, ShapeBorder.lerp(r, c, 0.1), 0.9)!.getOuterPath(rect), looksLikeR);

    expect(ShapeBorder.lerp(r, c, 0.1).toString(),
           'RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(10.0), 10.0% of the way to being a CircleBorder)');
    expect(ShapeBorder.lerp(r, c, 0.2).toString(),
           'RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(10.0), 20.0% of the way to being a CircleBorder)');
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.1), ShapeBorder.lerp(r, c, 0.9), 0.9).toString(),
           'RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(10.0), 82.0% of the way to being a CircleBorder)');

    expect(ShapeBorder.lerp(c, r, 0.9).toString(),
           'RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(10.0), 10.0% of the way to being a CircleBorder)');
    expect(ShapeBorder.lerp(c, r, 0.8).toString(),
           'RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(10.0), 20.0% of the way to being a CircleBorder)');
    expect(ShapeBorder.lerp(ShapeBorder.lerp(r, c, 0.9), ShapeBorder.lerp(r, c, 0.1), 0.1).toString(),
           'RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(10.0), 82.0% of the way to being a CircleBorder)');

    expect(ShapeBorder.lerp(r, c, 0.1), ShapeBorder.lerp(r, c, 0.1));
    expect(ShapeBorder.lerp(r, c, 0.1).hashCode, ShapeBorder.lerp(r, c, 0.1).hashCode);

    final ShapeBorder direct50 = ShapeBorder.lerp(r, c, 0.5)!;
    final ShapeBorder indirect50 = ShapeBorder.lerp(ShapeBorder.lerp(c, r, 0.1), ShapeBorder.lerp(c, r, 0.9), 0.5)!;
    expect(direct50, indirect50);
    expect(direct50.hashCode, indirect50.hashCode);
    expect(direct50.toString(), indirect50.toString());
  });
}
