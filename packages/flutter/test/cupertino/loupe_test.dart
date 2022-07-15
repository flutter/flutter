// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Offset basicOffset = Offset(CupertinoLoupe.kSize.width / 2,
      CupertinoLoupe.kSize.height - CupertinoLoupe.kVerticalFocalPointOffset);
  const Rect reasonableTextField = Rect.fromLTRB(0, 100, 200, 100);
  final LoupeController loupeController = LoupeController();

  // Note: make sure that your gesture is within threshold of the line,
  // or else the loupe status will stay hidden and this will not complete.
  Future<void> showCupertinoLoupe(
    BuildContext context,
    WidgetTester tester,
    ValueNotifier<LoupeSelectionOverlayInfoBearer> infoBearer,
  ) async {
    final Future<void> loupeShown = loupeController.show(
        context: context,
        builder: (_) => CupertinoTextEditingLoupe(
              controller: loupeController,
              loupeSelectionOverlayInfoBearer: infoBearer,
            ));

    // The loupe will never be shown if we don't pump the animation
    WidgetsBinding.instance.scheduleFrame();
    await tester.pumpAndSettle();

    // Verify that the loupe is shown
    await loupeShown;
  }

  tearDown(() async {
    if (loupeController.overlayEntry != null) {
      loupeController.overlayEntry!.remove();
      loupeController.overlayEntry = null;
    }
  });

  group('CupertinoTextEditingLoupe', () {
    group('position', () {
      Offset getLoupePosition(WidgetTester tester) {
        final AnimatedPositioned animatedPositioned =
            tester.firstWidget(find.byType(AnimatedPositioned));
        return Offset(
            animatedPositioned.left ?? 0, animatedPositioned.top ?? 0);
      }

      testWidgets(
          'should be at gesture position if does not violate any positioning rules',
          (WidgetTester tester) async {
        final Key fakeTextFieldKey = UniqueKey();

        await tester.pumpWidget(
          Container(
            color: const Color.fromARGB(255, 0, 255, 179),
            child: MaterialApp(
              home: Center(
                  child: Container(
                key: fakeTextFieldKey,
                width: 10,
                height: 10,
                color: Colors.red,
                child: const Placeholder(),
              )),
            ),
          ),
        );
        final BuildContext context = tester.element(find.byType(Placeholder));

        // Loupe should be positioned directly over the red square.
        final RenderBox tapPointRenderBox =
            tester.firstRenderObject(find.byKey(fakeTextFieldKey)) as RenderBox;
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

        await showCupertinoLoupe(context, tester, loupeInfo);

        // Should show two red squares; original, and one in the loupe,
        // directly ontop of one another.
        await expectLater(
          find.byType(Placeholder),
          matchesGoldenFile('cupertino_loupe.position.default.png'),
        );
      });

      testWidgets('should never horizontally be outside of Screen Padding',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context =
            tester.firstElement(find.byType(Placeholder));

        await showCupertinoLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              fieldBounds: reasonableTextField,
              handleRect: reasonableTextField,
              // The tap position is far out of the right side of the app.
              globalGesturePosition:
                  Offset(MediaQuery.of(context).size.width + 100, 0),
            )));

        // Should be less than the right edge, since we have padding.
        expect(getLoupePosition(tester).dx,
            lessThan(MediaQuery.of(context).size.width));
      });

      testWidgets('should have some vertical drag',
          (WidgetTester tester) async {
        final double dragPositionBelowTextField = reasonableTextField.top + 30;

        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context =
            tester.firstElement(find.byType(Placeholder));

        await showCupertinoLoupe(
            context,
            tester,
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
              currentLineBoundries: reasonableTextField,
              fieldBounds: reasonableTextField,
              handleRect: reasonableTextField,
              // The tap position is dragBelow units below the text field.
              globalGesturePosition: Offset(
                  MediaQuery.of(context).size.width / 2,
                  dragPositionBelowTextField),
            )));

        // The loupe should be greater than the text field, since we "dragged" it down,
        // but excatly following the drag position.
        expect(getLoupePosition(tester).dy + basicOffset.dy,
            greaterThan(reasonableTextField.center.dy));
        expect(getLoupePosition(tester).dy + basicOffset.dy,
            lessThan(dragPositionBelowTextField));
      });
    });

    group('status', () {
      testWidgets('should hide if gesture is far below the text field',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            color: Color.fromARGB(7, 0, 129, 90),
            home: Placeholder(),
          ),
        );

        final BuildContext context =
            tester.firstElement(find.byType(Placeholder));

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupeInfo =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          // The tap position is dragBelow units below the text field.
          globalGesturePosition: Offset(
              MediaQuery.of(context).size.width / 2, reasonableTextField.top),
        ));

        // Show the loupe initally, so that we get it in a not hidden state
        await showCupertinoLoupe(context, tester, loupeInfo);

        // Move the gesture to one that should hide it.
        loupeInfo.value = LoupeSelectionOverlayInfoBearer(
            currentLineBoundries: reasonableTextField,
            fieldBounds: reasonableTextField,
            handleRect: reasonableTextField,
            globalGesturePosition:
                loupeInfo.value.globalGesturePosition + const Offset(0, 100));
        await tester.pumpAndSettle();



        expect(
          find.byType(Opacity).evaluate().first.widget,
            isA<Opacity>()
                .having((Opacity opacity) => opacity.opacity, 'opacity', 0));
        expect(loupeController.overlayEntry, isNotNull);
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

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupeInfo =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          // The tap position is dragBelow units below the text field.
          globalGesturePosition: Offset(
              MediaQuery.of(context).size.width / 2, reasonableTextField.top),
        ));

        // Show the loupe initally, so that we get it in a not hidden state
        await showCupertinoLoupe(context, tester, loupeInfo);

        // Move the gesture to one that should hide it.
        loupeInfo.value = LoupeSelectionOverlayInfoBearer(
            currentLineBoundries: reasonableTextField,
            fieldBounds: reasonableTextField,
            handleRect: reasonableTextField,
            globalGesturePosition:
                loupeInfo.value.globalGesturePosition + const Offset(0, 100));
        await tester.pumpAndSettle();

        expect(
            find.byType(Opacity).evaluate().first.widget,
            isA<Opacity>()
                .having((Opacity opacity) => opacity.opacity, 'opacity', 0));
        expect(loupeController.overlayEntry, isNotNull);

        // Return the gesture to one that shows it.
        loupeInfo.value = LoupeSelectionOverlayInfoBearer(
            currentLineBoundries: reasonableTextField,
            fieldBounds: reasonableTextField,
            handleRect: reasonableTextField,
            globalGesturePosition: Offset(MediaQuery.of(context).size.width / 2,
                reasonableTextField.top));
        await tester.pumpAndSettle();

        expect(
            find.byType(Opacity).evaluate().first.widget,
            isA<Opacity>()
                .having((Opacity opacity) => opacity.opacity, 'opacity', 1));
        expect(loupeController.overlayEntry, isNotNull);
      });
    });
  });
}
