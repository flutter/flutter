// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final magnifierController = MagnifierController();
  const reasonableTextField = Rect.fromLTRB(50, 100, 200, 100);
  final basicOffset = Offset(
    Magnifier.kDefaultMagnifierSize.width / 2,
    Magnifier.kStandardVerticalFocalPointShift + Magnifier.kDefaultMagnifierSize.height,
  );

  Offset getMagnifierPosition(WidgetTester tester, [bool animated = false]) {
    if (animated) {
      final AnimatedPositioned animatedPositioned = tester.firstWidget(
        find.byType(AnimatedPositioned),
      );
      return Offset(animatedPositioned.left ?? 0, animatedPositioned.top ?? 0);
    } else {
      final Positioned positioned = tester.firstWidget(find.byType(Positioned));
      return Offset(positioned.left ?? 0, positioned.top ?? 0);
    }
  }

  Future<void> showMagnifier(
    BuildContext context,
    WidgetTester tester,
    ValueNotifier<MagnifierInfo> magnifierInfo,
  ) async {
    final Future<void> magnifierShown = magnifierController.show(
      context: context,
      builder: (_) => TextMagnifier(magnifierInfo: magnifierInfo),
    );

    WidgetsBinding.instance.scheduleFrame();
    await tester.pumpAndSettle();

    // Verify that the magnifier is shown.
    await magnifierShown;
  }

  tearDown(() {
    magnifierController.removeFromOverlay();
    magnifierController.animationController = null;
  });

  group('adaptiveMagnifierControllerBuilder', () {
    testWidgets('should return a TextEditingMagnifier on Android', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Placeholder()));

      final BuildContext context = tester.firstElement(find.byType(Placeholder));

      final magnifierPositioner = ValueNotifier<MagnifierInfo>(MagnifierInfo.empty);
      addTearDown(magnifierPositioner.dispose);

      final Widget? builtWidget = TextMagnifier.adaptiveMagnifierConfiguration.magnifierBuilder(
        context,
        MagnifierController(),
        magnifierPositioner,
      );

      expect(builtWidget, isA<TextMagnifier>());
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('should return a CupertinoMagnifier on iOS', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Placeholder()));

      final BuildContext context = tester.firstElement(find.byType(Placeholder));

      final magnifierPositioner = ValueNotifier<MagnifierInfo>(MagnifierInfo.empty);
      addTearDown(magnifierPositioner.dispose);

      final Widget? builtWidget = TextMagnifier.adaptiveMagnifierConfiguration.magnifierBuilder(
        context,
        MagnifierController(),
        magnifierPositioner,
      );

      expect(builtWidget, isA<CupertinoTextMagnifier>());
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets(
      'should return null on all platforms not Android, iOS',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierPositioner = ValueNotifier<MagnifierInfo>(MagnifierInfo.empty);
        addTearDown(magnifierPositioner.dispose);

        final Widget? builtWidget = TextMagnifier.adaptiveMagnifierConfiguration.magnifierBuilder(
          context,
          MagnifierController(),
          magnifierPositioner,
        );

        expect(builtWidget, isNull);
      },
      variant: TargetPlatformVariant.all(
        excluding: <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.android},
      ),
    );
  });

  group('magnifier', () {
    group('position', () {
      testWidgets('should be at gesture position if does not violate any positioning rules', (
        WidgetTester tester,
      ) async {
        final Key textField = UniqueKey();

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        await tester.pumpWidget(
          ColoredBox(
            color: const Color.fromARGB(255, 0, 255, 179),
            child: MaterialApp(
              home: Center(
                child: Container(
                  key: textField,
                  width: 10,
                  height: 10,
                  color: Colors.red,
                  child: const Placeholder(),
                ),
              ),
            ),
          ),
        );

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        // Magnifier should be positioned directly over the red square.
        final tapPointRenderBox = tester.firstRenderObject(find.byKey(textField)) as RenderBox;
        final Rect fakeTextFieldRect =
            tapPointRenderBox.localToGlobal(Offset.zero) & tapPointRenderBox.size;

        final magnifierInfo = ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: fakeTextFieldRect,
            fieldBounds: fakeTextFieldRect,
            caretRect: fakeTextFieldRect,
            // The tap position is dragBelow units below the text field.
            globalGesturePosition: fakeTextFieldRect.center,
          ),
        );
        addTearDown(magnifierInfo.dispose);

        await showMagnifier(context, tester, magnifierInfo);

        // Should show two red crossed-out squares: the original in the center,
        // and one in the magnifier, in the upper half of the image, surrounded
        // by a faint offset rounded rectangle shadow.
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('magnifier.position.default.png'),
        );
      });

      testWidgets('should never move outside the right bounds of the editing line', (
        WidgetTester tester,
      ) async {
        // Close enough to the line that the magnifier is still shown.
        const double gestureOutsideLine = 20;

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierPositioner;
        addTearDown(() => magnifierPositioner.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierPositioner = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: reasonableTextField,
              // Inflate these two to make sure we're bounding on the
              // current line boundaries, not anything else.
              fieldBounds: reasonableTextField.inflate(gestureOutsideLine),
              caretRect: reasonableTextField.inflate(gestureOutsideLine),
              // The tap position is far out of the right side of the app.
              globalGesturePosition: Offset(reasonableTextField.right + gestureOutsideLine, 0),
            ),
          ),
        );

        // Should be less than the right edge, since we have padding.
        expect(getMagnifierPosition(tester).dx, lessThanOrEqualTo(reasonableTextField.right));
      });

      testWidgets('should never move outside the left bounds of the editing line', (
        WidgetTester tester,
      ) async {
        // Close enough to the line that the magnifier is still shown.
        const double gestureOutsideLine = 20;

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierPositioner;
        addTearDown(() => magnifierPositioner.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierPositioner = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: reasonableTextField,
              // Inflate these two to make sure we're bounding on the
              // current line boundaries, not anything else.
              fieldBounds: reasonableTextField.inflate(gestureOutsideLine),
              caretRect: reasonableTextField.inflate(gestureOutsideLine),
              // The tap position is far out of the left side of the app.
              globalGesturePosition: Offset(reasonableTextField.left - gestureOutsideLine, 0),
            ),
          ),
        );

        expect(
          getMagnifierPosition(tester).dx + basicOffset.dx,
          greaterThanOrEqualTo(reasonableTextField.left),
        );
      });

      testWidgets('should position vertically at the center of the line', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierPositioner;
        addTearDown(() => magnifierPositioner.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierPositioner = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: reasonableTextField,
              fieldBounds: reasonableTextField,
              caretRect: reasonableTextField,
              globalGesturePosition: reasonableTextField.center,
            ),
          ),
        );

        expect(getMagnifierPosition(tester).dy, reasonableTextField.center.dy - basicOffset.dy);
      });

      testWidgets('should reposition vertically if mashed against the ceiling', (
        WidgetTester tester,
      ) async {
        final topOfScreenTextFieldRect = Rect.fromPoints(Offset.zero, const Offset(200, 0));

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierPositioner;
        addTearDown(() => magnifierPositioner.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierPositioner = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: topOfScreenTextFieldRect,
              fieldBounds: topOfScreenTextFieldRect,
              caretRect: topOfScreenTextFieldRect,
              globalGesturePosition: topOfScreenTextFieldRect.topCenter,
            ),
          ),
        );

        expect(getMagnifierPosition(tester).dy, greaterThanOrEqualTo(0));
      });
    });

    // Regression tests for https://github.com/flutter/flutter/issues/159230.
    group('visibility', () {
      // Within half of the magnified content's width from the line, which is
      // (77.37 / 2) / 1.25 ≈ 30.9.
      const double closeToLine = 20;
      // Further than half of the magnified content's width from the line.
      const double farFromLine = 100;

      MagnifierInfo magnifierInfoWithGestureAt(double dx) {
        return MagnifierInfo(
          currentLineBoundaries: reasonableTextField,
          fieldBounds: reasonableTextField.inflate(farFromLine * 2),
          caretRect: reasonableTextField,
          globalGesturePosition: Offset(dx, reasonableTextField.center.dy),
        );
      }

      testWidgets('should be shown when the gesture is close to either end of the line', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));
        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierInfo = ValueNotifier<MagnifierInfo>(
          magnifierInfoWithGestureAt(reasonableTextField.right + closeToLine),
        );
        addTearDown(magnifierInfo.dispose);

        await showMagnifier(context, tester, magnifierInfo);

        expect(find.byType(Magnifier), findsOneWidget);

        magnifierInfo.value = magnifierInfoWithGestureAt(reasonableTextField.left - closeToLine);
        await tester.pump();

        expect(find.byType(Magnifier), findsOneWidget);
      });

      testWidgets('should be hidden when the gesture is far past the right end of the line', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));
        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierInfo = ValueNotifier<MagnifierInfo>(
          magnifierInfoWithGestureAt(reasonableTextField.right + farFromLine),
        );
        addTearDown(magnifierInfo.dispose);

        await showMagnifier(context, tester, magnifierInfo);

        expect(find.byType(TextMagnifier), findsOneWidget);
        expect(find.byType(Magnifier), findsNothing);
      });

      testWidgets('should be hidden when the gesture is far past the left end of the line', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));
        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierInfo = ValueNotifier<MagnifierInfo>(
          magnifierInfoWithGestureAt(reasonableTextField.left - farFromLine),
        );
        addTearDown(magnifierInfo.dispose);

        await showMagnifier(context, tester, magnifierInfo);

        expect(find.byType(TextMagnifier), findsOneWidget);
        expect(find.byType(Magnifier), findsNothing);
      });

      testWidgets('should hide and reappear as the gesture leaves and returns to the line', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));
        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierInfo = ValueNotifier<MagnifierInfo>(
          magnifierInfoWithGestureAt(reasonableTextField.center.dx),
        );
        addTearDown(magnifierInfo.dispose);

        await showMagnifier(context, tester, magnifierInfo);
        expect(find.byType(Magnifier), findsOneWidget);

        magnifierInfo.value = magnifierInfoWithGestureAt(reasonableTextField.right + farFromLine);
        await tester.pump();
        expect(find.byType(Magnifier), findsNothing);

        magnifierInfo.value = magnifierInfoWithGestureAt(reasonableTextField.right);
        await tester.pump();
        expect(find.byType(Magnifier), findsOneWidget);
        // The magnifier tracks the gesture again.
        expect(
          getMagnifierPosition(tester, true).dx + basicOffset.dx,
          moreOrLessEquals(reasonableTextField.right),
        );
      });

      testWidgets('should not animate when reappearing on a different line', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));
        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierInfo = ValueNotifier<MagnifierInfo>(
          magnifierInfoWithGestureAt(reasonableTextField.right + farFromLine),
        );
        addTearDown(magnifierInfo.dispose);

        await showMagnifier(context, tester, magnifierInfo);
        expect(find.byType(Magnifier), findsNothing);

        // Come back to a line further down.
        const lineShift = Offset(0, 50);
        magnifierInfo.value = MagnifierInfo(
          currentLineBoundaries: reasonableTextField.shift(lineShift),
          fieldBounds: reasonableTextField.inflate(farFromLine * 2),
          caretRect: reasonableTextField.shift(lineShift),
          globalGesturePosition: reasonableTextField.center + lineShift,
        );
        await tester.pump();

        expect(find.byType(Magnifier), findsOneWidget);
        final AnimatedPositioned animatedPositioned = tester.firstWidget(
          find.byType(AnimatedPositioned),
        );
        expect(animatedPositioned.duration, Duration.zero);
      });
    });

    group('focal point', () {
      Offset getMagnifierAdditionalFocalPoint(WidgetTester tester) {
        final Magnifier magnifier = tester.firstWidget(find.byType(Magnifier));
        return magnifier.additionalFocalPointOffset;
      }

      testWidgets('should shift focal point so that the lens sees nothing out of bounds', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierPositioner;
        addTearDown(() => magnifierPositioner.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierPositioner = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: reasonableTextField,
              fieldBounds: reasonableTextField,
              caretRect: reasonableTextField,
              // Gesture on the far right of the magnifier.
              globalGesturePosition: reasonableTextField.topLeft,
            ),
          ),
        );

        expect(getMagnifierAdditionalFocalPoint(tester).dx, lessThan(reasonableTextField.left));
      });

      testWidgets('focal point should shift if mashed against the top to always point to text', (
        WidgetTester tester,
      ) async {
        final topOfScreenTextFieldRect = Rect.fromPoints(Offset.zero, const Offset(200, 0));

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierPositioner;
        addTearDown(() => magnifierPositioner.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierPositioner = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: topOfScreenTextFieldRect,
              fieldBounds: topOfScreenTextFieldRect,
              caretRect: topOfScreenTextFieldRect,
              globalGesturePosition: topOfScreenTextFieldRect.topCenter,
            ),
          ),
        );

        expect(getMagnifierAdditionalFocalPoint(tester).dy, lessThan(0));
      });
    });

    group('animation state', () {
      bool getIsAnimated(WidgetTester tester) {
        final AnimatedPositioned animatedPositioned = tester.firstWidget(
          find.byType(AnimatedPositioned),
        );
        return animatedPositioned.duration.compareTo(Duration.zero) != 0;
      }

      testWidgets('should not be animated on the initial state', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        late ValueNotifier<MagnifierInfo> magnifierInfo;
        addTearDown(() => magnifierInfo.dispose());

        await showMagnifier(
          context,
          tester,
          magnifierInfo = ValueNotifier<MagnifierInfo>(
            MagnifierInfo(
              currentLineBoundaries: reasonableTextField,
              fieldBounds: reasonableTextField,
              caretRect: reasonableTextField,
              globalGesturePosition: reasonableTextField.center,
            ),
          ),
        );

        expect(getIsAnimated(tester), false);
      });

      testWidgets('should not be animated on horizontal shifts', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierPositioner = ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            globalGesturePosition: reasonableTextField.center,
          ),
        );
        addTearDown(magnifierPositioner.dispose);

        await showMagnifier(context, tester, magnifierPositioner);

        // New position has a horizontal shift.
        magnifierPositioner.value = MagnifierInfo(
          currentLineBoundaries: reasonableTextField,
          fieldBounds: reasonableTextField,
          caretRect: reasonableTextField,
          globalGesturePosition: reasonableTextField.center + const Offset(200, 0),
        );
        await tester.pumpAndSettle();

        expect(getIsAnimated(tester), false);
      });

      testWidgets('should be animated on vertical shifts', (WidgetTester tester) async {
        const verticalShift = Offset(0, 200);

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierPositioner = ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            globalGesturePosition: reasonableTextField.center,
          ),
        );
        addTearDown(magnifierPositioner.dispose);

        await showMagnifier(context, tester, magnifierPositioner);

        // New position has a vertical shift.
        magnifierPositioner.value = MagnifierInfo(
          currentLineBoundaries: reasonableTextField.shift(verticalShift),
          fieldBounds: Rect.fromPoints(
            reasonableTextField.topLeft,
            reasonableTextField.bottomRight + verticalShift,
          ),
          caretRect: reasonableTextField.shift(verticalShift),
          globalGesturePosition: reasonableTextField.center + verticalShift,
        );

        await tester.pump();
        expect(getIsAnimated(tester), true);
      });

      testWidgets('should stop being animated when timer is up', (WidgetTester tester) async {
        const verticalShift = Offset(0, 200);

        await tester.pumpWidget(const MaterialApp(home: Placeholder()));

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final magnifierPositioner = ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            globalGesturePosition: reasonableTextField.center,
          ),
        );
        addTearDown(magnifierPositioner.dispose);

        await showMagnifier(context, tester, magnifierPositioner);

        // New position has a vertical shift.
        magnifierPositioner.value = MagnifierInfo(
          currentLineBoundaries: reasonableTextField.shift(verticalShift),
          fieldBounds: Rect.fromPoints(
            reasonableTextField.topLeft,
            reasonableTextField.bottomRight + verticalShift,
          ),
          caretRect: reasonableTextField.shift(verticalShift),
          globalGesturePosition: reasonableTextField.center + verticalShift,
        );

        await tester.pump();
        expect(getIsAnimated(tester), true);
        await tester.pump(
          TextMagnifier.jumpBetweenLinesAnimationDuration + const Duration(seconds: 2),
        );
        expect(getIsAnimated(tester), false);
      });
    });
  });
}
