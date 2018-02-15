// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('The InkWell widget renders an ink splash', (WidgetTester tester) async {
    const Color highlightColor = const Color(0xAAFF0000);
    const Color splashColor = const Color(0xAA0000FF);
    final BorderRadius borderRadius = new BorderRadius.circular(6.0);

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 60.0,
            child: new InkWell(
              borderRadius: borderRadius,
              highlightColor: highlightColor,
              splashColor: splashColor,
              onTap: () { },
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(InkWell));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as dynamic;
    expect(
      box,
      paints
        ..clipRRect(rrect: new RRect.fromLTRBR(300.0, 270.0, 500.0, 330.0, const Radius.circular(6.0)))
        ..circle(x: 400.0, y: 300.0, radius: 21.0, color: splashColor)
        ..rrect(
          rrect: new RRect.fromLTRBR(300.0, 270.0, 500.0, 330.0, const Radius.circular(6.0)),
          color: highlightColor,
        )
    );

    await gesture.up();
  });

  testWidgets('The InkWell widget renders an ink ripple', (WidgetTester tester) async {
    const Color highlightColor = const Color(0xAAFF0000);
    const Color splashColor = const Color(0xB40000FF);
    final BorderRadius borderRadius = new BorderRadius.circular(6.0);

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 100.0,
            child: new InkWell(
              borderRadius: borderRadius,
              highlightColor: highlightColor,
              splashColor: splashColor,
              onTap: () { },
              radius: 100.0,
              splashFactory: InkRipple.splashFactory,
            ),
          ),
        ),
      ),
    );

    final Offset tapDownOffset = tester.getTopLeft(find.byType(InkWell));
    final Offset inkWellCenter = tester.getCenter(find.byType(InkWell));
    //final TestGesture gesture = await tester.startGesture(tapDownOffset);
    await tester.tapAt(tapDownOffset);
    await tester.pump(); // start gesture

    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as dynamic;

    bool offsetsAreClose(Offset a, Offset b) => (a - b).distance < 1.0;
    bool radiiAreClose(double a, double b) => (a - b).abs() < 1.0;

    // Initially the ripple's center is where the tap occurred,
    expect(box, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawCircle)
        return false;
      final Offset center = arguments[0];
      final double radius = arguments[1];
      final Paint paint = arguments[2];
      if (offsetsAreClose(center, tapDownOffset) && radius == 30.0 && paint.color.alpha == 0)
        return true;
      throw '''
        Expected: center == $tapDownOffset, radius == 30.0, alpha == 0
        Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
    }));

    // The ripple fades in for 75ms. During that time its alpha is eased from
    // 0 to the splashColor's alpha value and its center moves towards the
    // center of the ink well.
    await tester.pump(const Duration(milliseconds: 50));
    expect(box, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawCircle)
        return false;
      final Offset center = arguments[0];
      final double radius = arguments[1];
      final Paint paint = arguments[2];
      final Offset expectedCenter = tapDownOffset + const Offset(17.0, 17.0);
      const double expectedRadius = 56.0;
      if (offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius) && paint.color.alpha == 120)
        return true;
      throw '''
        Expected: center == $expectedCenter, radius == $expectedRadius, alpha == 120
        Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
    }));

    // At 75ms the ripple has fade in: it's alpha matches the splashColor's
    // alpha and its center has moved closer to the ink well's center.
    await tester.pump(const Duration(milliseconds: 25));
    expect(box, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawCircle)
        return false;
      final Offset center = arguments[0];
      final double radius = arguments[1];
      final Paint paint = arguments[2];
      final Offset expectedCenter = tapDownOffset + const Offset(29.0, 29.0);
      const double expectedRadius = 73.0;
      if (offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius) && paint.color.alpha == 180)
        return true;
      throw '''
        Expected: center == $expectedCenter, radius == $expectedRadius, alpha == 180
        Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
    }));

    // At this point the splash radius has expanded to its limit: 5 past the
    // ink well's radius parameter. The splash center has moved to its final
    // location at the inkwell's center and the fade-out is about to start.
    // The fade-out begins at 225ms = 50ms + 25ms + 150ms.
    await tester.pump(const Duration(milliseconds: 150));
    expect(box, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawCircle)
        return false;
      final Offset center = arguments[0];
      final double radius = arguments[1];
      final Paint paint = arguments[2];
      final Offset expectedCenter = inkWellCenter;
      const double expectedRadius = 105.0;
      if (offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius) && paint.color.alpha == 180)
        return true;
      throw '''
        Expected: center == $expectedCenter, radius == $expectedRadius, alpha == 180
        Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
    }));

    // After another 150ms the fade-out is complete.
    await tester.pump(const Duration(milliseconds: 150));
    expect(box, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawCircle)
        return false;
      final Offset center = arguments[0];
      final double radius = arguments[1];
      final Paint paint = arguments[2];
      final Offset expectedCenter = inkWellCenter;
      const double expectedRadius = 105.0;
      if (offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius) && paint.color.alpha == 0)
        return true;
      throw '''
        Expected: center == $expectedCenter, radius == $expectedRadius, alpha == 0
        Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
    }));
  });

  testWidgets('Does the Ink widget render anything', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Ink(
            color: Colors.blue,
            width: 200.0,
            height: 200.0,
            child: new InkWell(
              splashColor: Colors.green,
              onTap: () { },
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(InkWell));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as dynamic;
    expect(
      box,
      paints
        ..rect(rect: new Rect.fromLTRB(300.0, 200.0, 500.0, 400.0), color: new Color(Colors.blue.value))
        ..circle(color: new Color(Colors.green.value))
    );

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Ink(
            color: Colors.red,
            width: 200.0,
            height: 200.0,
            child: new InkWell(
              splashColor: Colors.green,
              onTap: () { },
            ),
          ),
        ),
      ),
    );

    expect(Material.of(tester.element(find.byType(InkWell))), same(box));

    expect(
      box,
      paints
        ..rect(rect: new Rect.fromLTRB(300.0, 200.0, 500.0, 400.0), color: new Color(Colors.red.value))
        ..circle(color: new Color(Colors.green.value))
    );

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new InkWell( // this is at a different depth in the tree so it's now a new InkWell
            splashColor: Colors.green,
            onTap: () { },
          ),
        ),
      ),
    );

    expect(Material.of(tester.element(find.byType(InkWell))), same(box));

    expect(box, isNot(paints..rect()));
    expect(box, isNot(paints..circle()));

    await gesture.up();
  });

  testWidgets('Cancel an InkRipple that was disposed when its animation ended', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/14391
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 100.0,
            child: new InkWell(
              onTap: () { },
              radius: 100.0,
              splashFactory: InkRipple.splashFactory,
            ),
          ),
        ),
      ),
    );

    final Offset tapDownOffset = tester.getTopLeft(find.byType(InkWell));
    await tester.tapAt(tapDownOffset);
    await tester.pump(); // start splash
    await tester.pump(const Duration(milliseconds: 375)); // _kFadeOutDuration, in_ripple.dart

    final TestGesture gesture = await tester.startGesture(tapDownOffset);
    await tester.pump(); // start gesture
    await gesture.moveTo(const Offset(0.0, 0.0));
    await gesture.up(); // generates a tap cancel
    await tester.pumpAndSettle();
  });
}
