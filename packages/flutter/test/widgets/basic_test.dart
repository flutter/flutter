// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';


void main() {
  group('PhysicalShape', () {
    testWidgets('properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const PhysicalShape(
          clipper: const ShapeBorderClipper(shape: const CircleBorder()),
          elevation: 2.0,
          color: const Color(0xFF0000FF),
          shadowColor: const Color(0xFF00FF00),
        )
      );
      final RenderPhysicalShape renderObject = tester.renderObject(find.byType(PhysicalShape));
      expect(renderObject.clipper, const ShapeBorderClipper(shape: const CircleBorder()));
      expect(renderObject.color, const Color(0xFF0000FF));
      expect(renderObject.shadowColor, const Color(0xFF00FF00));
      expect(renderObject.elevation, 2.0);
    });

    testWidgets('hit test', (WidgetTester tester) async {
      await tester.pumpWidget(
        new PhysicalShape(
          clipper: const ShapeBorderClipper(shape: const CircleBorder()),
          elevation: 2.0,
          color: const Color(0xFF0000FF),
          shadowColor: const Color(0xFF00FF00),
          child: new Container(color: const Color(0xFF0000FF)),
        )
      );

      final RenderPhysicalShape renderPhysicalShape =
        tester.renderObject(find.byType(PhysicalShape));

      // The viewport is 800x600, the CircleBorder is centered and fits
      // the shortest edge, so we get a circle of radius 300, centered at
      // (400, 300).
      //
      // We test by sampling a few points around the left-most point of the
      // circle (100, 300).

      expect(tester.hitTestOnBinding(const Offset(99.0, 300.0)), doesNotHit(renderPhysicalShape));
      expect(tester.hitTestOnBinding(const Offset(100.0, 300.0)), hits(renderPhysicalShape));
      expect(tester.hitTestOnBinding(const Offset(100.0, 299.0)), doesNotHit(renderPhysicalShape));
      expect(tester.hitTestOnBinding(const Offset(100.0, 301.0)), doesNotHit(renderPhysicalShape));
    });

  });

}

HitsRenderBox hits(RenderBox renderBox) => new HitsRenderBox(renderBox);

class HitsRenderBox extends Matcher {
  const HitsRenderBox(this.renderBox);

  final RenderBox renderBox;

  @override
  Description describe(Description description) =>
    description.add('hit test result contains ').addDescriptionOf(renderBox);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final HitTestResult hitTestResult = item;
    return hitTestResult.path.where(
      (HitTestEntry entry) => entry.target == renderBox
    ).isNotEmpty;
  }
}

DoesNotHitRenderBox doesNotHit(RenderBox renderBox) => new DoesNotHitRenderBox(renderBox);

class DoesNotHitRenderBox extends Matcher {
  const DoesNotHitRenderBox(this.renderBox);

  final RenderBox renderBox;

  @override
  Description describe(Description description) =>
    description.add('hit test result doesn\'t contain ').addDescriptionOf(renderBox);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final HitTestResult hitTestResult = item;
    return hitTestResult.path.where(
      (HitTestEntry entry) => entry.target == renderBox
    ).isEmpty;
  }
}
