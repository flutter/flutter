import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final LoupeController loupeController = LoupeController();
  const Rect reasonableTextField = Rect.fromLTRB(50, 100, 200, 100);
  final Offset basicOffset = Offset(Loupe.kSize.width / 2,
      Loupe.kSize.height - Loupe.kStandardVerticalFocalPointShift);

  Future<BuildContext> contextTrap(WidgetTester tester,
      {Widget Function(Widget child)? wrapper}) async {
    late BuildContext outerContext;

    Widget identity(Widget child) {
      return child;
    }

    await tester.pumpWidget(
        (wrapper ?? identity)(Builder(builder: (BuildContext context) {
      outerContext = context;
      return Container();
    })));

    return outerContext;
  }

  Offset getLoupePosition(WidgetTester tester, [bool animated = false]) {
    if (animated) {
      final AnimatedPositioned animatedPositioned =
          tester.firstWidget(find.byType(AnimatedPositioned));
      return Offset(animatedPositioned.left ?? 0, animatedPositioned.top ?? 0);
    } else {
      final Positioned positioned = tester.firstWidget(find.byType(Positioned));
      return Offset(positioned.left ?? 0, positioned.top ?? 0);
    }
  }

  Future<void> showLoupe(
    BuildContext context,
    WidgetTester tester,
    ValueNotifier<LoupeSelectionOverlayInfoBearer> infoBearer,
  ) async {
    final Future<void> loupeShown = loupeController.show(
        context: context,
        builder: (_) => TextEditingLoupe(
              controller: loupeController,
              loupeSelectionOverlayInfoBearer: infoBearer,
            ));

    // The loupe will never be shown if we don't pump the animation
    WidgetsBinding.instance.scheduleFrame();
    await tester.pumpAndSettle();

    // Verify that the loupe is shown
    await loupeShown;
  }

  group('adaptiveLoupeControllerBuilder', () {
    testWidgets('should return a TextEditingLoupe on Android',
        (WidgetTester tester) async {
      final BuildContext context = await contextTrap(tester);

      final Widget? builtWidget =
          TextEditingLoupe.adaptiveLoupeControllerBuilder(
              context,
              LoupeController(),
              ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                  const LoupeSelectionOverlayInfoBearer.empty()));

      expect(builtWidget, isA<TextEditingLoupe>());
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('should return a CupertinoLoupe on iOS',
        (WidgetTester tester) async {
      final BuildContext context = await contextTrap(tester);

      final Widget? builtWidget =
          TextEditingLoupe.adaptiveLoupeControllerBuilder(
              context,
              LoupeController(),
              ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                  const LoupeSelectionOverlayInfoBearer.empty()));

      expect(builtWidget, isA<CupertinoTextEditingLoupe>());
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('should return null on all platforms not Android, iOS',
        (WidgetTester tester) async {
      final BuildContext context = await contextTrap(tester);

      final Widget? builtWidget =
          TextEditingLoupe.adaptiveLoupeControllerBuilder(
              context,
              LoupeController(),
              ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                  const LoupeSelectionOverlayInfoBearer.empty()));

      expect(builtWidget, isNull);
    },
        variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{
          TargetPlatform.iOS,
          TargetPlatform.android
        }));
  });

  group('loupe', () {
    group('position', () {
      testWidgets(
          'should be at gesture position if does not violate any positioning rules',
          (WidgetTester tester) async {
        final Key textField = UniqueKey();
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => Container(
            color: const Color.fromARGB(255, 0, 255, 179),
            child: MaterialApp(
              home: Center(
                  child: Container(
                key: textField,
                width: 10,
                height: 10,
                color: Colors.red,
                child: child,
              )),
            ),
          ),
        );

        // Loupe should be positioned directly over the red square.
        final RenderBox tapPointRenderBox =
            tester.firstRenderObject(find.byKey(textField)) as RenderBox;
        final Rect fakeTextFieldRect =
            tapPointRenderBox.localToGlobal(Offset.zero) &
                tapPointRenderBox.size;

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupeInfo =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: fakeTextFieldRect,
          fieldBounds: fakeTextFieldRect,
          handleRect: fakeTextFieldRect,
          // The tap position is dragBelow units below the text field.
          globalGesturePosition: fakeTextFieldRect.center,
        ));

        await showLoupe(context, tester, loupeInfo);

        // Should show two red squares; original, and one in the loupe,
        // directly ontop of one another.
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('loupe.position.default.png'),
        );
      });

      testWidgets(
          'should never move outside the right bounds of the editing line',
          (WidgetTester tester) async {
        const double gestureOutsideLine = 100;

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              // Inflate these two to make sure we're bounding on the
              // current line boundries, not anything else.
              fieldBounds: reasonableTextField.inflate(gestureOutsideLine),
              handleRect: reasonableTextField.inflate(gestureOutsideLine),
              // The tap position is far out of the right side of the app.
              globalGesturePosition:
                  Offset(reasonableTextField.right + gestureOutsideLine, 0),
            )));

        // Should be less than the right edge, since we have padding.
        expect(getLoupePosition(tester).dx,
            lessThanOrEqualTo(reasonableTextField.right));
      });

      testWidgets(
          'should never move outside the left bounds of the editing line',
          (WidgetTester tester) async {
        const double gestureOutsideLine = 100;

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              // Inflate these two to make sure we're bounding on the
              // current line boundries, not anything else.
              fieldBounds: reasonableTextField.inflate(gestureOutsideLine),
              handleRect: reasonableTextField.inflate(gestureOutsideLine),
              // The tap position is far out of the left side of the app.
              globalGesturePosition:
                  Offset(reasonableTextField.left - gestureOutsideLine, 0),
            )));

        // Should be less than the right edge, since we have padding.
        expect(getLoupePosition(tester).dx,
            greaterThanOrEqualTo(reasonableTextField.left));
      });

      testWidgets('should position vertically at the center of the line',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              fieldBounds: reasonableTextField,
              handleRect: reasonableTextField,
              globalGesturePosition: reasonableTextField.center,
            )));

        expect(getLoupePosition(tester).dy,
            reasonableTextField.center.dy - basicOffset.dy);
      });

      testWidgets('should reposition vertically if mashed against the ceiling',
          (WidgetTester tester) async {
        final Rect topOfScreenTextFieldRect =
            Rect.fromPoints(Offset.zero, const Offset(200, 0));

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: topOfScreenTextFieldRect,
              fieldBounds: topOfScreenTextFieldRect,
              handleRect: topOfScreenTextFieldRect,
              globalGesturePosition: topOfScreenTextFieldRect.topCenter,
            )));

        expect(getLoupePosition(tester).dy, greaterThanOrEqualTo(0));
      });
    });

    group('focal point', () {
      Offset getLoupeAdditionalFocalPoint(WidgetTester tester) {
        final Loupe loupe = tester.firstWidget(find.byType(Loupe));
        return loupe.additionalFocalPointOffset;
      }

      testWidgets(
          'should shift focal point so that the lens sees nothing out of bounds',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              fieldBounds: reasonableTextField,
              handleRect: reasonableTextField,

              // Gesture on the far right of the loupe.
              globalGesturePosition: reasonableTextField.topLeft,
            )));

        expect(getLoupeAdditionalFocalPoint(tester).dx,
            lessThan(reasonableTextField.left));
      });

      testWidgets(
          'focal point should shift if mashed against the top to always point to text',
          (WidgetTester tester) async {
        final Rect topOfScreenTextFieldRect =
            Rect.fromPoints(Offset.zero, const Offset(200, 0));

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: topOfScreenTextFieldRect,
              fieldBounds: topOfScreenTextFieldRect,
              handleRect: topOfScreenTextFieldRect,
              globalGesturePosition: topOfScreenTextFieldRect.topCenter,
            )));

        expect(
            getLoupeAdditionalFocalPoint(tester).dy, greaterThanOrEqualTo(0));
      });
    });

    group('animation state', () {
      bool getIsAnimated(WidgetTester tester) {
        final AnimatedPositioned animatedPositioned =
            tester.firstWidget(find.byType(AnimatedPositioned));
        return animatedPositioned.duration.compareTo(Duration.zero) != 0;
      }

      testWidgets('should not be animated on the inital state',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        await showLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              fieldBounds: reasonableTextField,
              handleRect: reasonableTextField,
              globalGesturePosition: reasonableTextField.center,
            )));

        expect(getIsAnimated(tester), false);
      });

      testWidgets('should not be animated on horizontal shifts',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupePositioner =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          globalGesturePosition: reasonableTextField.center,
        ));

        await showLoupe(context, tester, loupePositioner);

        // New position has a horizontal shift.
        loupePositioner.value = LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          globalGesturePosition:
              reasonableTextField.center + const Offset(200, 0),
        );
        await tester.pumpAndSettle();

        expect(getIsAnimated(tester), false);
      });

      testWidgets('should be animated on vertical shifts',
          (WidgetTester tester) async {
        const Offset verticalShift = Offset(0, 200);

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupePositioner =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          globalGesturePosition: reasonableTextField.center,
        ));

        await showLoupe(context, tester, loupePositioner);

        // New position has a vertical shift.
        loupePositioner.value = LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField.shift(verticalShift),
          fieldBounds: Rect.fromPoints(reasonableTextField.topLeft,
              reasonableTextField.bottomRight + verticalShift),
          handleRect: reasonableTextField.shift(verticalShift),
          globalGesturePosition: reasonableTextField.center + verticalShift,
        );

        await tester.pump();
        expect(getIsAnimated(tester), true);
      });

      testWidgets('should stop being animated when timer is up',
          (WidgetTester tester) async {
        const Offset verticalShift = Offset(0, 200);

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupePositioner =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          globalGesturePosition: reasonableTextField.center,
        ));

        await showLoupe(context, tester, loupePositioner);

        // New position has a vertical shift.
        loupePositioner.value = LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField.shift(verticalShift),
          fieldBounds: Rect.fromPoints(reasonableTextField.topLeft,
              reasonableTextField.bottomRight + verticalShift),
          handleRect: reasonableTextField.shift(verticalShift),
          globalGesturePosition: reasonableTextField.center + verticalShift,
        );

        await tester.pump();
        expect(getIsAnimated(tester), true);
        await tester.pump(TextEditingLoupe.jumpBetweenLinesAnimationDuration + const Duration(seconds: 2));
        expect(getIsAnimated(tester), false);
      });
    });
  });
}
