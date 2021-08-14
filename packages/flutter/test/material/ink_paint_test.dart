// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('The Ink widget renders a Container by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: Ink(),
      ),
    );
    expect(tester.getSize(find.byType(Container)).height, 600.0);
    expect(tester.getSize(find.byType(Container)).width, 800.0);

    const double height = 150.0;
    const double width = 200.0;
    await tester.pumpWidget(
      Material(
        child: Center( // used to constrain to child's size
          child: Ink(
            height: height,
            width: width,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Container)).height, height);
    expect(tester.getSize(find.byType(Container)).width, width);
  });

  testWidgets('The InkWell widget renders an ink splash', (WidgetTester tester) async {
    const Color highlightColor = Color(0xAAFF0000);
    const Color splashColor = Color(0xAA0000FF);
    final BorderRadius borderRadius = BorderRadius.circular(6.0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: SizedBox(
              width: 200.0,
              height: 60.0,
              child: InkWell(
                borderRadius: borderRadius,
                highlightColor: highlightColor,
                splashColor: splashColor,
                onTap: () { },
              ),
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(InkWell));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final RenderBox box = Material.of(tester.element(find.byType(InkWell)))! as RenderBox;
    expect(
      box,
      paints
        ..translate(x: 0.0, y: 0.0)
        ..save()
        ..translate(x: 300.0, y: 270.0)
        ..clipRRect(rrect: RRect.fromLTRBR(0.0, 0.0, 200.0, 60.0, const Radius.circular(6.0)))
        ..circle(x: 100.0, y: 30.0, radius: 21.0, color: splashColor)
        ..restore()
        ..rrect(
          rrect: RRect.fromLTRBR(300.0, 270.0, 500.0, 330.0, const Radius.circular(6.0)),
          color: highlightColor,
        ),
    );

    await gesture.up();
  });

  testWidgets('The InkWell widget renders an ink ripple', (WidgetTester tester) async {
    const Color highlightColor = Color(0xAAFF0000);
    const Color splashColor = Color(0xB40000FF);
    final BorderRadius borderRadius = BorderRadius.circular(6.0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: InkWell(
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
      ),
    );

    final Offset tapDownOffset = tester.getTopLeft(find.byType(InkWell));
    final Offset inkWellCenter = tester.getCenter(find.byType(InkWell));
    //final TestGesture gesture = await tester.startGesture(tapDownOffset);
    await tester.tapAt(tapDownOffset);
    await tester.pump(); // start gesture

    final RenderBox box = Material.of(tester.element(find.byType(InkWell)))! as RenderBox;

    bool offsetsAreClose(Offset a, Offset b) => (a - b).distance < 1.0;
    bool radiiAreClose(double a, double b) => (a - b).abs() < 1.0;

    PaintPattern ripplePattern(Offset expectedCenter, double expectedRadius, int expectedAlpha) {
      return paints
        ..translate(x: 0.0, y: 0.0)
        ..translate(x: tapDownOffset.dx, y: tapDownOffset.dy)
        ..something((Symbol method, List<dynamic> arguments) {
          if (method != #drawCircle)
            return false;
          final Offset center = arguments[0] as Offset;
          final double radius = arguments[1] as double;
          final Paint paint = arguments[2] as Paint;
          if (offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius) && paint.color.alpha == expectedAlpha)
            return true;
          throw '''
            Expected: center == $expectedCenter, radius == $expectedRadius, alpha == $expectedAlpha
            Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
        }
      );
    }

    // Initially the ripple's center is where the tap occurred;
    // ripplePattern always add a translation of tapDownOffset.
    expect(box, ripplePattern(Offset.zero, 30.0, 0));

    // The ripple fades in for 75ms. During that time its alpha is eased from
    // 0 to the splashColor's alpha value and its center moves towards the
    // center of the ink well.
    await tester.pump(const Duration(milliseconds: 50));
    expect(box, ripplePattern(const Offset(17.0, 17.0), 56.0, 120));

    // At 75ms the ripple has fade in: it's alpha matches the splashColor's
    // alpha and its center has moved closer to the ink well's center.
    await tester.pump(const Duration(milliseconds: 25));
    expect(box, ripplePattern(const Offset(29.0, 29.0), 73.0, 180));

    // At this point the splash radius has expanded to its limit: 5 past the
    // ink well's radius parameter. The splash center has moved to its final
    // location at the inkwell's center and the fade-out is about to start.
    // The fade-out begins at 225ms = 50ms + 25ms + 150ms.
    await tester.pump(const Duration(milliseconds: 150));
    expect(box, ripplePattern(inkWellCenter - tapDownOffset, 105.0, 180));

    // After another 150ms the fade-out is complete.
    await tester.pump(const Duration(milliseconds: 150));
    expect(box, ripplePattern(inkWellCenter - tapDownOffset, 105.0, 0));
  });

  testWidgets('Does the Ink widget render anything', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Ink(
              color: Colors.blue,
              width: 200.0,
              height: 200.0,
              child: InkWell(
                splashColor: Colors.green,
                onTap: () { },
              ),
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(InkWell));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final RenderBox box = Material.of(tester.element(find.byType(InkWell)))! as RenderBox;
    expect(
      box,
      paints
        ..rect(rect: const Rect.fromLTRB(300.0, 200.0, 500.0, 400.0), color: Color(Colors.blue.value))
        ..circle(color: Color(Colors.green.value)),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Ink(
              color: Colors.red,
              width: 200.0,
              height: 200.0,
              child: InkWell(
                splashColor: Colors.green,
                onTap: () { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(Material.of(tester.element(find.byType(InkWell))), same(box));

    expect(
      box,
      paints
        ..rect(rect: const Rect.fromLTRB(300.0, 200.0, 500.0, 400.0), color: Color(Colors.red.value))
        ..circle(color: Color(Colors.green.value)),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: InkWell( // this is at a different depth in the tree so it's now a new InkWell
              splashColor: Colors.green,
              onTap: () { },
            ),
          ),
        ),
      ),
    );

    expect(Material.of(tester.element(find.byType(InkWell))), same(box));

    expect(box, isNot(paints..rect()));
    expect(box, isNot(paints..circle()));

    await gesture.up();
  });

  testWidgets('The InkWell widget renders an SelectAction or ActivateAction-induced ink ripple', (WidgetTester tester) async {
    const Color highlightColor = Color(0xAAFF0000);
    const Color splashColor = Color(0xB40000FF);
    final BorderRadius borderRadius = BorderRadius.circular(6.0);

    final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');
    Future<void> buildTest(Intent intent) async {
      return tester.pumpWidget(
        Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.space): intent,
          },
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Center(
                child: SizedBox(
                  width: 100.0,
                  height: 100.0,
                  child: InkWell(
                    borderRadius: borderRadius,
                    highlightColor: highlightColor,
                    splashColor: splashColor,
                    focusNode: focusNode,
                    onTap: () { },
                    radius: 100.0,
                    splashFactory: InkRipple.splashFactory,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(const ActivateIntent());
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final Offset topLeft = tester.getTopLeft(find.byType(InkWell));
    final Offset inkWellCenter = tester.getCenter(find.byType(InkWell)) - topLeft;

    bool offsetsAreClose(Offset a, Offset b) => (a - b).distance < 1.0;
    bool radiiAreClose(double a, double b) => (a - b).abs() < 1.0;

    PaintPattern ripplePattern(double expectedRadius, int expectedAlpha) {
      return paints
        ..translate(x: 0.0, y: 0.0)
        ..translate(x: topLeft.dx, y: topLeft.dy)
        ..something((Symbol method, List<dynamic> arguments) {
          if (method != #drawCircle) {
            return false;
          }
          final Offset center = arguments[0] as Offset;
          final double radius = arguments[1] as double;
          final Paint paint = arguments[2] as Paint;
          if (offsetsAreClose(center, inkWellCenter) &&
              radiiAreClose(radius, expectedRadius) &&
              paint.color.alpha == expectedAlpha) {
            return true;
          }
          throw '''
            Expected: center == $inkWellCenter, radius == $expectedRadius, alpha == $expectedAlpha
            Found: center == $center radius == $radius alpha == ${paint.color.alpha}''';
        },
        );
    }

    await buildTest(const ActivateIntent());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    final RenderBox box = Material.of(tester.element(find.byType(InkWell)))! as RenderBox;

    // ripplePattern always add a translation of topLeft.
    expect(box, ripplePattern(30.0, 0));

    // The ripple fades in for 75ms. During that time its alpha is eased from
    // 0 to the splashColor's alpha value.
    await tester.pump(const Duration(milliseconds: 50));
    expect(box, ripplePattern(56.0, 120));

    // At 75ms the ripple has faded in: it's alpha matches the splashColor's
    // alpha.
    await tester.pump(const Duration(milliseconds: 25));
    expect(box, ripplePattern(73.0, 180));

    // At this point the splash radius has expanded to its limit: 5 past the
    // ink well's radius parameter. The fade-out is about to start.
    // The fade-out begins at 225ms = 50ms + 25ms + 150ms.
    await tester.pump(const Duration(milliseconds: 150));
    expect(box, ripplePattern(105.0, 180));

    // After another 150ms the fade-out is complete.
    await tester.pump(const Duration(milliseconds: 150));
    expect(box, ripplePattern(105.0, 0));
  });

  testWidgets('Cancel an InkRipple that was disposed when its animation ended', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/14391
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: InkWell(
                onTap: () { },
                radius: 100.0,
                splashFactory: InkRipple.splashFactory,
              ),
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
    await gesture.moveTo(Offset.zero);
    await gesture.up(); // generates a tap cancel
    await tester.pumpAndSettle();
  });

  testWidgets('Cancel an InkRipple that was disposed when its animation ended', (WidgetTester tester) async {
    const Color highlightColor = Color(0xAAFF0000);
    const Color splashColor = Color(0xB40000FF);

    // Regression test for https://github.com/flutter/flutter/issues/14391
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: InkWell(
                splashColor: splashColor,
                highlightColor: highlightColor,
                onTap: () { },
                radius: 100.0,
                splashFactory: InkRipple.splashFactory,
              ),
            ),
          ),
        ),
      ),
    );

    final Offset tapDownOffset = tester.getTopLeft(find.byType(InkWell));
    await tester.tapAt(tapDownOffset);
    await tester.pump(); // start splash
    // No delay here so _fadeInController.value=1.0 (InkRipple.dart)

    // Generate a tap cancel; Will cancel the ink splash before it started
    final TestGesture gesture = await tester.startGesture(tapDownOffset);
    await tester.pump(); // start gesture
    await gesture.moveTo(Offset.zero);
    await gesture.up(); // generates a tap cancel

    final RenderBox box = Material.of(tester.element(find.byType(InkWell)))! as RenderBox;
    expect(box, paints..everything((Symbol method, List<dynamic> arguments) {
      if (method != #drawCircle)
        return true;
      final Paint paint = arguments[2] as Paint;
      if (paint.color.alpha == 0)
        return true;
      throw 'Expected: paint.color.alpha == 0, found: ${paint.color.alpha}';
    }));
  });
}
