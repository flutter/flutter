// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

void main() {
  group('PhysicalShape', () {
    testWidgets('properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const PhysicalShape(
          clipper: ShapeBorderClipper(shape: CircleBorder()),
          elevation: 2.0,
          color: Color(0xFF0000FF),
          shadowColor: Color(0xFF00FF00),
        ),
      );
      final RenderPhysicalShape renderObject = tester.renderObject(find.byType(PhysicalShape));
      expect(renderObject.clipper, const ShapeBorderClipper(shape: CircleBorder()));
      expect(renderObject.color, const Color(0xFF0000FF));
      expect(renderObject.shadowColor, const Color(0xFF00FF00));
      expect(renderObject.elevation, 2.0);
    });

    testWidgets('hit test', (WidgetTester tester) async {
      await tester.pumpWidget(
        PhysicalShape(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          elevation: 2.0,
          color: const Color(0xFF0000FF),
          shadowColor: const Color(0xFF00FF00),
          child: Container(color: const Color(0xFF0000FF)),
        ),
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
    }, skip: isBrowser);

  });

  group('FractionalTranslation', () {
    testWidgets('hit test - entirely inside the bounding box', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey();
      bool _pointerDown = false;

      await tester.pumpWidget(
        Center(
          child: FractionalTranslation(
            translation: Offset.zero,
            transformHitTests: true,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _pointerDown = true;
              },
              child: SizedBox(
                key: key1,
                width: 100.0,
                height: 100.0,
                child: Container(
                  color: const Color(0xFF0000FF)
                ),
              ),
            ),
          ),
        ),
      );
      expect(_pointerDown, isFalse);
      await tester.tap(find.byKey(key1));
      expect(_pointerDown, isTrue);
    });

    testWidgets('hit test - partially inside the bounding box', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey();
      bool _pointerDown = false;

      await tester.pumpWidget(
        Center(
          child: FractionalTranslation(
            translation: const Offset(0.5, 0.5),
            transformHitTests: true,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _pointerDown = true;
              },
              child: SizedBox(
                key: key1,
                width: 100.0,
                height: 100.0,
                child: Container(
                  color: const Color(0xFF0000FF)
                ),
              ),
            ),
          ),
        ),
      );
      expect(_pointerDown, isFalse);
      await tester.tap(find.byKey(key1));
      expect(_pointerDown, isTrue);
    });

    testWidgets('hit test - completely outside the bounding box', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey();
      bool _pointerDown = false;

      await tester.pumpWidget(
        Center(
          child: FractionalTranslation(
            translation: const Offset(1.0, 1.0),
            transformHitTests: true,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _pointerDown = true;
              },
              child: SizedBox(
                key: key1,
                width: 100.0,
                height: 100.0,
                child: Container(
                  color: const Color(0xFF0000FF)
                ),
              ),
            ),
          ),
        ),
      );
      expect(_pointerDown, isFalse);
      await tester.tap(find.byKey(key1));
      expect(_pointerDown, isTrue);
    });
  });

  group('Row', () {
    testWidgets('multiple baseline aligned children', (WidgetTester tester) async {
      final UniqueKey key1 = UniqueKey();
      final UniqueKey key2 = UniqueKey();
      const double fontSize1 = 54;
      const double fontSize2 = 14;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text('big text',
                    key: key1,
                    style: const TextStyle(fontSize: fontSize1),
                  ),
                  Text('one\ntwo\nthree\nfour\nfive\nsix\nseven',
                    key: key2,
                    style: const TextStyle(fontSize: fontSize2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final RenderBox textBox1 = tester.renderObject(find.byKey(key1));
      final RenderBox textBox2 = tester.renderObject(find.byKey(key2));
      final RenderBox rowBox = tester.renderObject(find.byType(Row));

      // The two Texts are baseline aligned, so some portion of them extends
      // both above and below the baseline. The first has a huge font size, so
      // it extends higher above the baseline than usual. The second has many
      // lines, but being aligned by the first line's baseline, they hang far
      // below the baseline. The size of the parent row is just enough to
      // contain both of them.
      const double ahemBaselineLocation = 0.8; // https://web-platform-tests.org/writing-tests/ahem.html
      const double aboveBaseline1 = fontSize1 * ahemBaselineLocation;
      const double belowBaseline1 = fontSize1 * (1 - ahemBaselineLocation);
      const double aboveBaseline2 = fontSize2 * ahemBaselineLocation;
      const double belowBaseline2 = fontSize2 * (1 - ahemBaselineLocation) + fontSize2 * 6;
      final double aboveBaseline = math.max(aboveBaseline1, aboveBaseline2);
      final double belowBaseline = math.max(belowBaseline1, belowBaseline2);
      expect(rowBox.size.height, greaterThan(textBox1.size.height));
      expect(rowBox.size.height, greaterThan(textBox2.size.height));
      expect(rowBox.size.height, closeTo(aboveBaseline + belowBaseline, .001));
      expect(tester.getTopLeft(find.byKey(key1)).dy, 0);
      expect(
        tester.getTopLeft(find.byKey(key2)).dy,
        closeTo(aboveBaseline1 - aboveBaseline2, .001),
      );
    }, skip: isBrowser);
  });

  test('UnconstrainedBox toString', () {
    expect(
      const UnconstrainedBox(constrainedAxis: Axis.vertical,).toString(),
      equals('UnconstrainedBox(alignment: center, constrainedAxis: vertical)'),
    );
    expect(
      const UnconstrainedBox(constrainedAxis: Axis.horizontal, textDirection: TextDirection.rtl, alignment: Alignment.topRight).toString(),
      equals('UnconstrainedBox(alignment: topRight, constrainedAxis: horizontal, textDirection: rtl)'),
    );
  });
}

HitsRenderBox hits(RenderBox renderBox) => HitsRenderBox(renderBox);

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

DoesNotHitRenderBox doesNotHit(RenderBox renderBox) => DoesNotHitRenderBox(renderBox);

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
