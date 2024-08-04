// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Offset basicOffset = Offset(CupertinoMagnifier.kDefaultSize.width / 2,
       CupertinoMagnifier.kDefaultSize.height - CupertinoMagnifier.kMagnifierAboveFocalPoint);
  const Rect reasonableTextField = Rect.fromLTRB(0, 100, 200, 200);
  final MagnifierController magnifierController = MagnifierController();

  // Make sure that your gesture in magnifierInfo is within the line in magnifierInfo,
  // or else the magnifier status will stay hidden and this will not complete.
  Future<void> showCupertinoMagnifier(
    BuildContext context,
    WidgetTester tester,
    ValueNotifier<MagnifierInfo> magnifierInfo,
  ) async {
    final Future<void> magnifierShown = magnifierController.show(
      context: context,
      builder: (BuildContext context) => CupertinoTextMagnifier(
        controller: magnifierController,
        magnifierInfo: magnifierInfo,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await magnifierShown;
  }

  tearDown(() async {
      magnifierController.removeFromOverlay();
  });

  group('CupertinoTextEditingMagnifier', () {
    group('position', () {
      Offset getMagnifierPosition(WidgetTester tester) {
        final AnimatedPositioned animatedPositioned =
            tester.firstWidget(find.byType(AnimatedPositioned));
        return Offset(
            animatedPositioned.left ?? 0, animatedPositioned.top ?? 0);
      }

      testWidgets('should be at gesture position if does not violate any positioning rules', (WidgetTester tester) async {
        final Key fakeTextFieldKey = UniqueKey();
        final Key outerKey = UniqueKey();

        await tester.pumpWidget(
          ColoredBox(
            key: outerKey,
            color: const Color.fromARGB(255, 0, 255, 179),
            child: MaterialApp(
              home: Center(
                child: Container(
                  key: fakeTextFieldKey,
                  width: 10,
                  height: 10,
                  color: Colors.red,
                  child: const Placeholder(),
                ),
              ),
            ),
          ),
        );
        final BuildContext context = tester.element(find.byType(Placeholder));

        // Magnifier should be positioned directly over the red square.
        final RenderBox tapPointRenderBox =
            tester.firstRenderObject(find.byKey(fakeTextFieldKey)) as RenderBox;
        final Rect fakeTextFieldRect =
            tapPointRenderBox.localToGlobal(Offset.zero) & tapPointRenderBox.size;

        final ValueNotifier<MagnifierInfo> magnifier =
            ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: fakeTextFieldRect,
            fieldBounds: fakeTextFieldRect,
            caretRect: fakeTextFieldRect,
            // The tap position is dragBelow units below the text field.
            globalGesturePosition: fakeTextFieldRect.center,
          ),
        );
        addTearDown(magnifier.dispose);

        await showCupertinoMagnifier(context, tester, magnifier);

        // Should show two red squares; original, and one in the magnifier,
        // directly ontop of one another.
        await expectLater(
          find.byKey(outerKey),
          matchesGoldenFile('cupertino_magnifier.position.default.png'),
        );
      });

      testWidgets('should never horizontally be outside of Screen Padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context = tester.firstElement(find.byType(Placeholder));

        final ValueNotifier<MagnifierInfo> magnifierInfo = ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            // The tap position is far out of the right side of the app.
            globalGesturePosition:
            Offset(MediaQuery.sizeOf(context).width + 100, 0),
          ),
        );
        addTearDown(magnifierInfo.dispose);
        await showCupertinoMagnifier(
          context,
          tester,
          magnifierInfo,
        );

        // Should be less than the right edge, since we have padding.
        expect(getMagnifierPosition(tester).dx,
            lessThan(MediaQuery.sizeOf(context).width));
      });

      testWidgets('should have some vertical drag', (WidgetTester tester) async {
        final double dragPositionBelowTextField = reasonableTextField.center.dy + 30;

        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context =
            tester.firstElement(find.byType(Placeholder));

        final ValueNotifier<MagnifierInfo> magnifierInfo =
            ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            // The tap position is dragBelow units below the text field.
            globalGesturePosition: Offset(
                MediaQuery.sizeOf(context).width / 2,
                dragPositionBelowTextField),
          ),
        );
        addTearDown(magnifierInfo.dispose);
        await showCupertinoMagnifier(
          context,
          tester,
          magnifierInfo,
        );

        // The magnifier Y should be greater than the text field, since we "dragged" it down.
        expect(getMagnifierPosition(tester).dy + basicOffset.dy,
            greaterThan(reasonableTextField.center.dy));
        expect(getMagnifierPosition(tester).dy + basicOffset.dy,
            lessThan(dragPositionBelowTextField));
      });
    });

    group('status', () {
      testWidgets('should hide if gesture is far below the text field', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context =
            tester.firstElement(find.byType(Placeholder));

        final ValueNotifier<MagnifierInfo> magnifierInfo =
            ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            // The tap position is dragBelow units below the text field.
            globalGesturePosition: Offset(
                MediaQuery.sizeOf(context).width / 2, reasonableTextField.top),
          ),
        );
        addTearDown(magnifierInfo.dispose);

        // Show the magnifier initially, so that we get it in a not hidden state.
        await showCupertinoMagnifier(context, tester, magnifierInfo);

        // Move the gesture to one that should hide it.
        magnifierInfo.value = MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            globalGesturePosition: magnifierInfo.value.globalGesturePosition + const Offset(0, 100),
        );
        await tester.pumpAndSettle();

        expect(magnifierController.shown, false);
        expect(magnifierController.overlayEntry, isNotNull);
      });

      testWidgets('should re-show if gesture moves back up',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context =
            tester.firstElement(find.byType(Placeholder));

        final ValueNotifier<MagnifierInfo> magnifierInfo =
            ValueNotifier<MagnifierInfo>(
          MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            // The tap position is dragBelow units below the text field.
            globalGesturePosition: Offset(MediaQuery.sizeOf(context).width / 2, reasonableTextField.top),
          ),
        );
        addTearDown(magnifierInfo.dispose);

        // Show the magnifier initially, so that we get it in a not hidden state.
        await showCupertinoMagnifier(context, tester, magnifierInfo);

        // Move the gesture to one that should hide it.
        magnifierInfo.value = MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            globalGesturePosition:
                magnifierInfo.value.globalGesturePosition + const Offset(0, 100));
        await tester.pumpAndSettle();

        expect(magnifierController.shown, false);
        expect(magnifierController.overlayEntry, isNotNull);

        // Return the gesture to one that shows it.
        magnifierInfo.value = MagnifierInfo(
            currentLineBoundaries: reasonableTextField,
            fieldBounds: reasonableTextField,
            caretRect: reasonableTextField,
            globalGesturePosition: Offset(MediaQuery.sizeOf(context).width / 2,
                reasonableTextField.top));
        await tester.pumpAndSettle();

        expect(magnifierController.shown, true);
        expect(magnifierController.overlayEntry, isNotNull);
      });
    });
  });
}
