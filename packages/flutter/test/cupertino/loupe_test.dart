import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProxyLoupeController extends LoupeController {
  int showCalls = 0;
  int hideCalls = 0;

  @override
  Future<void> hide({bool removeFromOverlay = true}) async {
    hideCalls++;
    super.hide(removeFromOverlay: removeFromOverlay);
  }

  @override
  Future<void> signalShow() async {
    showCalls++;
    super.signalShow();
  }
}

void main() {
  final Offset basicOffset = Offset(
    CupertinoLoupe.kLoupeSize.width / 2,
      CupertinoLoupe.kLoupeSize.height -
          CupertinoLoupe.kVerticalFocalPointOffset);
  const Rect reasonableTextField = Rect.fromLTRB(0, 100, 200, 100);
  final _ProxyLoupeController proxyLoupeController = _ProxyLoupeController();

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

  // Note: make sure that your gesture is within threshold of the line,
  // or else the loupe status will stay hidden and this will not complete.
  Future<void> showCupertinoLoupe(
    BuildContext context,
    WidgetTester tester,
    ValueNotifier<LoupeSelectionOverlayInfoBearer> infoBearer,
  ) async {
    final Future<void> loupeShown = proxyLoupeController.show(
        context: context,
        builder: (_) => CupertinoTextEditingLoupe(
              controller: proxyLoupeController,
              loupeSelectionOverlayInfoBearer: infoBearer,
            ));

    // The loupe will never be shown if we don't pump the animation
    WidgetsBinding.instance.scheduleFrame();
    await tester.pumpAndSettle();

    // Verify that the loupe is shown
    await loupeShown;
  }

  tearDown(() async {
    if (proxyLoupeController.overlayEntry != null) {
      proxyLoupeController.overlayEntry!.remove();
      proxyLoupeController.overlayEntry = null;
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
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

        final Offset gesturePosition = Offset(
            MediaQuery.of(context).size.width / 2, reasonableTextField.top);

        final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupeInfo =
            ValueNotifier<LoupeSelectionOverlayInfoBearer>(
                LoupeSelectionOverlayInfoBearer(
          currentLineBoundries: reasonableTextField,
          fieldBounds: reasonableTextField,
          handleRect: reasonableTextField,
          // The tap position is dragBelow units below the text field.
          globalGesturePosition: gesturePosition,
        ));

        // Show the loupe initally, so that we get it in a not hidden state
        await showCupertinoLoupe(context, tester, loupeInfo);
        expect(getLoupePosition(tester), gesturePosition - basicOffset);
      });

      testWidgets('should never horizontally be outside of Screen Padding',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

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

        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

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
            greaterThan(reasonableTextField.top));
        expect(getLoupePosition(tester).dy + basicOffset.dy,
            lessThan(dragPositionBelowTextField));
      });
    });

    group('status', () {
      testWidgets('should hide if gesture is far below the text field',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

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

        expect(proxyLoupeController.hideCalls, 1);
      });

      testWidgets('should hide if gesture is far below the text field',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

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

        expect(proxyLoupeController.hideCalls, 1);
      });

      testWidgets('should re-show if gesture', (WidgetTester tester) async {
        final BuildContext context = await contextTrap(
          tester,
          wrapper: (Widget child) => MaterialApp(
            color: const Color.fromARGB(7, 0, 129, 90),
            home: child,
          ),
        );

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

        expect(proxyLoupeController.hideCalls, 1);
        // Reset show calls to avoid counting inital show.
        proxyLoupeController.showCalls = 0;

        // Return the gesture to one that shows it.
        loupeInfo.value = LoupeSelectionOverlayInfoBearer(
            currentLineBoundries: reasonableTextField,
            fieldBounds: reasonableTextField,
            handleRect: reasonableTextField,
            globalGesturePosition: Offset(MediaQuery.of(context).size.width / 2,
                reasonableTextField.top));
        await tester.pumpAndSettle();

        expect(proxyLoupeController.showCalls, 1);
      });
    });
  });
}
