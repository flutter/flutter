// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> testBorder(WidgetTester tester, String name, StarBorder border,
      {ShapeBorder? lerpTo, ShapeBorder? lerpFrom, double lerpAmount = 0}) async {
    assert(lerpTo == null || lerpFrom == null); // They can't both be set.
    ShapeBorder shape;
    if (lerpTo != null) {
      shape = border.lerpTo(lerpTo, lerpAmount)!;
    } else if (lerpFrom != null) {
      shape = border.lerpFrom(lerpFrom, lerpAmount)!;
    } else {
      shape = border;
    }
    await tester.pumpWidget(
      Container(
        alignment: Alignment.center,
        width: 200,
        height: 100,
        decoration: ShapeDecoration(
          color: const Color(0xff000000),
          shape: shape,
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('painting.star_border.$name.png'),
    );
  }

  test('StarBorder defaults', () {
    const StarBorder star = StarBorder();
    expect(star.side, BorderSide.none);
    expect(star.points, 5);
    expect(star.innerRadiusRatio, 0.4);
    expect(star.rotation, 0);
    expect(star.pointRounding, 0);
    expect(star.valleyRounding, 0);
    expect(star.squash, 0);

    const StarBorder polygon = StarBorder.polygon();
    expect(polygon.points, 5);
    expect(polygon.pointRounding, 0);
    expect(polygon.rotation, 0);
    expect(polygon.squash, 0);
  });

  test('StarBorder copyWith, ==, hashCode', () {
    const BorderSide side = BorderSide(width: 10.0, color: Color(0xff123456));
    final StarBorder copy = const StarBorder().copyWith(
      side: side,
      points: 3,
      innerRadiusRatio: 0.1,
      pointRounding: 0.2,
      valleyRounding: 0.3,
      rotation: 180,
      squash: 0.4,
    );
    const StarBorder expected = StarBorder(
      side: side,
      points: 3,
      innerRadiusRatio: 0.1,
      pointRounding: 0.2,
      valleyRounding: 0.3,
      rotation: 180,
      squash: 0.4,
    );
    expect(const StarBorder(), equals(const StarBorder().copyWith()));
    expect(copy, equals(expected));
    expect(copy.hashCode, equals(expected.hashCode));
  });

  testWidgets('StarBorder basic geometry', (WidgetTester tester) async {
    await testBorder(tester, 'basic_star', const StarBorder());
    await testBorder(tester, 'basic_polygon', const StarBorder.polygon());
  });

  testWidgets('StarBorder parameters', (WidgetTester tester) async {
    await testBorder(tester, 'points_6', const StarBorder(points: 6));
    await testBorder(tester, 'points_2', const StarBorder(points: 2));
    await testBorder(tester, 'inner_radius_0', const StarBorder(innerRadiusRatio: 0.0));
    await testBorder(tester, 'inner_radius_2', const StarBorder(innerRadiusRatio: 0.2));
    await testBorder(tester, 'inner_radius_7', const StarBorder(innerRadiusRatio: 0.7));
    await testBorder(tester, 'point_rounding_2', const StarBorder(pointRounding: 0.2));
    await testBorder(tester, 'point_rounding_7', const StarBorder(pointRounding: 0.7));
    await testBorder(tester, 'point_rounding_10', const StarBorder(pointRounding: 1.0));
    await testBorder(tester, 'valley_rounding_2', const StarBorder(valleyRounding: 0.2));
    await testBorder(tester, 'valley_rounding_7', const StarBorder(valleyRounding: 0.7));
    await testBorder(tester, 'valley_rounding_10', const StarBorder(valleyRounding: 1.0));
    await testBorder(tester, 'squash_2', const StarBorder(squash: 0.2));
    await testBorder(tester, 'squash_7', const StarBorder(squash: 0.7));
    await testBorder(tester, 'squash_10', const StarBorder(squash: 1.0));
    await testBorder(tester, 'rotate_27', const StarBorder(rotation: 27));
    await testBorder(tester, 'rotate_270', const StarBorder(rotation: 270));
    await testBorder(tester, 'rotate_360', const StarBorder(rotation: 360));
    await testBorder(tester, 'side_none', const StarBorder(side: BorderSide(style: BorderStyle.none)));
    await testBorder(tester, 'side_1', const StarBorder(side: BorderSide(color: Color(0xffff0000))));
    await testBorder(tester, 'side_10', const StarBorder(side: BorderSide(color: Color(0xffff0000), width: 10)));
    await testBorder(tester, 'side_align_center',
        const StarBorder(side: BorderSide(color: Color(0xffff0000), strokeAlign: BorderSide.strokeAlignCenter)));
    await testBorder(tester, 'side_align_outside',
        const StarBorder(side: BorderSide(color: Color(0xffff0000), strokeAlign: BorderSide.strokeAlignOutside));
  });

  testWidgets('StarBorder.polygon parameters', (WidgetTester tester) async {
    await testBorder(tester, 'poly_sides_6', const StarBorder.polygon(sides: 6));
    await testBorder(tester, 'poly_sides_2', const StarBorder.polygon(sides: 2));
    await testBorder(tester, 'poly_point_rounding_2', const StarBorder.polygon(pointRounding: 0.2));
    await testBorder(tester, 'poly_point_rounding_7', const StarBorder.polygon(pointRounding: 0.7));
    await testBorder(tester, 'poly_point_rounding_10', const StarBorder.polygon(pointRounding: 1.0));
    await testBorder(tester, 'poly_squash_2', const StarBorder.polygon(squash: 0.2));
    await testBorder(tester, 'poly_squash_7', const StarBorder.polygon(squash: 0.7));
    await testBorder(tester, 'poly_squash_10', const StarBorder.polygon(squash: 1.0));
    await testBorder(tester, 'poly_rotate_27', const StarBorder.polygon(rotation: 27));
    await testBorder(tester, 'poly_rotate_270', const StarBorder.polygon(rotation: 270));
    await testBorder(tester, 'poly_rotate_360', const StarBorder.polygon(rotation: 360));
    await testBorder(tester, 'poly_side_none', const StarBorder.polygon(side: BorderSide(style: BorderStyle.none)));
    await testBorder(tester, 'poly_side_1', const StarBorder.polygon(side: BorderSide(color: Color(0xffff0000))));
    await testBorder(
        tester, 'poly_side_10', const StarBorder.polygon(side: BorderSide(color: Color(0xffff0000), width: 10)));
    await testBorder(tester, 'poly_side_align_center',
        const StarBorder.polygon(side: BorderSide(color: Color(0xffff0000), strokeAlign: BorderSide.strokeAlignCenter)));
    await testBorder(tester, 'poly_side_align_outside',
        const StarBorder.polygon(side: BorderSide(color: Color(0xffff0000), strokeAlign: BorderSide.strokeAlignOutside)));
  });

  testWidgets('StarBorder lerped with StarBorder', (WidgetTester tester) async {
    const StarBorder from = StarBorder();
    const ShapeBorder otherBorder = StarBorder(
      points: 6,
      pointRounding: 0.5,
      valleyRounding: 0.5,
      innerRadiusRatio: 0.5,
      rotation: 90,
    );
    await testBorder(tester, 'to_star_border_2', from, lerpTo: otherBorder, lerpAmount: 0.2);
    await testBorder(tester, 'to_star_border_7', from, lerpTo: otherBorder, lerpAmount: 0.7);
    await testBorder(tester, 'to_star_border_10', from, lerpTo: otherBorder, lerpAmount: 1.0);
    await testBorder(tester, 'from_star_border_2', from, lerpFrom: otherBorder, lerpAmount: 0.2);
    await testBorder(tester, 'from_star_border_7', from, lerpFrom: otherBorder, lerpAmount: 0.7);
    await testBorder(tester, 'from_star_border_10', from, lerpFrom: otherBorder, lerpAmount: 1.0);
  });

  testWidgets('StarBorder lerped with CircleBorder', (WidgetTester tester) async {
    const StarBorder from = StarBorder();
    const ShapeBorder otherBorder = CircleBorder();
    const ShapeBorder eccentricCircle = CircleBorder(eccentricity: 0.6);
    await testBorder(tester, 'to_circle_border_2', from, lerpTo: otherBorder, lerpAmount: 0.2);
    await testBorder(tester, 'to_circle_border_7', from, lerpTo: otherBorder, lerpAmount: 0.7);
    await testBorder(tester, 'to_circle_border_10', from, lerpTo: otherBorder, lerpAmount: 1.0);
    await testBorder(tester, 'from_circle_border_2', from, lerpFrom: otherBorder, lerpAmount: 0.2);
    await testBorder(tester, 'from_circle_border_7', from, lerpFrom: otherBorder, lerpAmount: 0.7);
    await testBorder(tester, 'from_circle_border_10', from, lerpFrom: otherBorder, lerpAmount: 1.0);
    await testBorder(tester, 'to_eccentric_circle_border', from, lerpTo: eccentricCircle, lerpAmount: 0.4);
    await testBorder(tester, 'from_eccentric_circle_border', from, lerpFrom: eccentricCircle, lerpAmount: 0.4);
  });

  testWidgets('StarBorder lerped with RoundedRectangleBorder', (WidgetTester tester) async {
    const StarBorder from = StarBorder();
    const RoundedRectangleBorder rectangleBorder = RoundedRectangleBorder();
    await testBorder(tester, 'to_rect_border_2', from, lerpTo: rectangleBorder, lerpAmount: 0.2);
    await testBorder(tester, 'to_rect_border_7', from, lerpTo: rectangleBorder, lerpAmount: 0.7);
    await testBorder(tester, 'to_rect_border_10', from, lerpTo: rectangleBorder, lerpAmount: 1.0);
    await testBorder(tester, 'from_rect_border_2', from, lerpFrom: rectangleBorder, lerpAmount: 0.2);
    await testBorder(tester, 'from_rect_border_7', from, lerpFrom: rectangleBorder, lerpAmount: 0.7);
    await testBorder(tester, 'from_rect_border_10', from, lerpFrom: rectangleBorder, lerpAmount: 1.0);

    const RoundedRectangleBorder roundedRectBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(10.0),
        bottomRight: Radius.circular(10.0),
      ),
    );
    await testBorder(tester, 'to_rrect_border_2', from, lerpTo: roundedRectBorder, lerpAmount: 0.2);
    await testBorder(tester, 'to_rrect_border_7', from, lerpTo: roundedRectBorder, lerpAmount: 0.7);
    await testBorder(tester, 'to_rrect_border_10', from, lerpTo: roundedRectBorder, lerpAmount: 1.0);
    await testBorder(tester, 'from_rrect_border_2', from, lerpFrom: roundedRectBorder, lerpAmount: 0.2);
    await testBorder(tester, 'from_rrect_border_7', from, lerpFrom: roundedRectBorder, lerpAmount: 0.7);
    await testBorder(tester, 'from_rrect_border_10', from, lerpFrom: roundedRectBorder, lerpAmount: 1.0);
  });

  testWidgets('StarBorder lerped with StadiumBorder', (WidgetTester tester) async {
    const StarBorder from = StarBorder();
    const StadiumBorder stadiumBorder = StadiumBorder();

    await testBorder(tester, 'to_stadium_border_2', from, lerpTo: stadiumBorder, lerpAmount: 0.2);
    await testBorder(tester, 'to_stadium_border_7', from, lerpTo: stadiumBorder, lerpAmount: 0.7);
    await testBorder(tester, 'to_stadium_border_10', from, lerpTo: stadiumBorder, lerpAmount: 1.0);
    await testBorder(tester, 'from_stadium_border_2', from, lerpFrom: stadiumBorder, lerpAmount: 0.2);
    await testBorder(tester, 'from_stadium_border_7', from, lerpFrom: stadiumBorder, lerpAmount: 0.7);
    await testBorder(tester, 'from_stadium_border_10', from, lerpFrom: stadiumBorder, lerpAmount: 1.0);
  });
}
