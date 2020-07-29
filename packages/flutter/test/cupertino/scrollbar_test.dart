// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const CupertinoDynamicColor _kScrollbarColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x59000000),
  darkColor: Color(0x80FFFFFF),
);

void main() {
  const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
  const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
  const Duration _kScrollbarResizeDuration = Duration(milliseconds: 100);
  const Duration _kLongPressDuration = Duration(milliseconds: 100);

  testWidgets('Scrollbar never goes away until finger lift', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: CupertinoScrollbar(
            child: SingleChildScrollView(child: SizedBox(width: 4000.0, height: 4000.0)),
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.color,
    ));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    // Still there.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.color,
    ));

    await gesture.up();
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration * 0.5);

    // Opacity going down now.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.color.withAlpha(69),
    ));
  });

  testWidgets('Scrollbar dark mode', (WidgetTester tester) async {
    Brightness brightness = Brightness.light;
    StateSetter setState;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return MediaQuery(
              data: MediaQueryData(platformBrightness: brightness),
              child: const CupertinoScrollbar(
                child: SingleChildScrollView(child: SizedBox(width: 4000.0, height: 4000.0)),
              ),
            );
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, 10.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.color,
    ));

    setState(() { brightness = Brightness.dark; });
    await tester.pump();

    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.darkColor,
    ));
  });

  testWidgets('Scrollbar thumb can be dragged with long press', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: const CupertinoScrollbar(
              child: SingleChildScrollView(child: SizedBox(width: 4000.0, height: 4000.0)),
            ),
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);

    // Scroll a bit.
    const double scrollAmount = 10.0;
    final TestGesture scrollGesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    // Scroll down by swiping up.
    await scrollGesture.moveBy(const Offset(0.0, -scrollAmount));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Scrollbar thumb is fully showing and scroll offset has moved by
    // scrollAmount.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.color,
    ));
    expect(scrollController.offset, scrollAmount);
    await scrollGesture.up();
    await tester.pump();

    int hapticFeedbackCalls = 0;
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'HapticFeedback.vibrate') {
        hapticFeedbackCalls++;
      }
    });

    // Long press on the scrollbar thumb and expect a vibration after it resizes.
    expect(hapticFeedbackCalls, 0);
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(796.0, 50.0));
    await tester.pump(_kLongPressDuration);
    expect(hapticFeedbackCalls, 0);
    await tester.pump(_kScrollbarResizeDuration);
    // Allow the haptic feedback some slack.
    await tester.pump(const Duration(milliseconds: 1));
    expect(hapticFeedbackCalls, 1);

    // Drag the thumb down to scroll down.
    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pump(const Duration(milliseconds: 100));
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // The view has scrolled more than it would have by a swipe gesture of the
    // same distance.
    expect(scrollController.offset, greaterThan(scrollAmount * 2));
    // The scrollbar thumb is still fully visible.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: _kScrollbarColor.color,
    ));

    // Let the thumb fade out so all timers have resolved.
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration);
  });

  testWidgets('Scrollbar changes thickness and radius when dragged', (WidgetTester tester) async {
    const double thickness = 20;
    const double thicknessWhileDragging = 40;
    const double radius = 10;
    const double radiusWhileDragging = 20;

    const double inset = 3;
    const double scaleFactor = 2;
    final Size screenSize = tester.binding.window.physicalSize / tester.binding.window.devicePixelRatio;

    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: CupertinoScrollbar(
              thickness: thickness,
              thicknessWhileDragging: thicknessWhileDragging,
              radius: const Radius.circular(radius),
              radiusWhileDragging: const Radius.circular(radiusWhileDragging),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: screenSize.width * scaleFactor,
                  height: screenSize.height * scaleFactor,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);

    // Scroll a bit to cause the scrollbar thumb to be shown;
    // undo the scroll to put the thumb back at the top.
    const double scrollAmount = 10.0;
    final TestGesture scrollGesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await scrollGesture.moveBy(const Offset(0.0, -scrollAmount));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await scrollGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pump();
    await scrollGesture.up();
    await tester.pump();

    // Long press on the scrollbar thumb and expect it to grow
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(780.0, 50.0));
    await tester.pump(_kLongPressDuration);
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      rrect: RRect.fromRectAndRadius(
        Rect.fromLTWH(
          screenSize.width - inset - thickness,
          inset,
          thickness,
          (screenSize.height - 2 * inset) / scaleFactor,
        ),
        const Radius.circular(radius),
      ),
    ));
    await tester.pump(_kScrollbarResizeDuration ~/ 2);
    const double midpointThickness = (thickness + thicknessWhileDragging) / 2;
    const double midpointRadius = (radius + radiusWhileDragging) / 2;
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      rrect: RRect.fromRectAndRadius(
        Rect.fromLTWH(
          screenSize.width - inset - midpointThickness,
          inset,
          midpointThickness,
          (screenSize.height - 2 * inset) / scaleFactor,
        ),
        const Radius.circular(midpointRadius),
      ),
    ));
    await tester.pump(_kScrollbarResizeDuration ~/ 2);
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      rrect: RRect.fromRectAndRadius(
        Rect.fromLTWH(
          screenSize.width - inset - thicknessWhileDragging,
          inset,
          thicknessWhileDragging,
          (screenSize.height - 2 * inset) / scaleFactor,
        ),
        const Radius.circular(radiusWhileDragging),
      ),
    ));

    // Let the thumb fade out so all timers have resolved.
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration);
  });

  testWidgets('When isAlwaysShown is true, must pass a controller',
      (WidgetTester tester) async {
    Widget viewWithScroll() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoScrollbar(
            isAlwaysShown: true,
            child: const SingleChildScrollView(
              child: SizedBox(
                width: 4000.0,
                height: 4000.0,
              ),
            ),
          ),
        ),
      );
    }

    expect(() async {
      await tester.pumpWidget(viewWithScroll());
    }, throwsAssertionError);
  });

  testWidgets('When isAlwaysShown is true, must pass a controller that is attached to a scroll view',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoScrollbar(
            controller: controller,
            isAlwaysShown: true,
            child: const SingleChildScrollView(
              child: SizedBox(
                width: 4000.0,
                height: 4000.0,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    final dynamic exception = tester.takeException();
    expect(exception, isAssertionError);
  });

  testWidgets('On first render with isAlwaysShown: true, the thumb shows',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: controller,
            child: CupertinoScrollbar(
              isAlwaysShown: true,
              controller: controller,
              child: const SingleChildScrollView(
                child: SizedBox(
                  width: 4000.0,
                  height: 4000.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    // The scrollbar measures its size on the first frame
    // and renders starting in the second,
    //
    // so pumpAndSettle a frame to allow it to appear.
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), paints..rrect());
  });

  testWidgets('On first render with isAlwaysShown: false, the thumb is hidden',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: controller,
            child: CupertinoScrollbar(
              isAlwaysShown: false,
              controller: controller,
              child: const SingleChildScrollView(
                child: SizedBox(
                  width: 4000.0,
                  height: 4000.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), isNot(paints..rect()));
  });

  testWidgets(
      'With isAlwaysShown: true, fling a scroll. While it is still scrolling, set isAlwaysShown: false. The thumb should not fade out until the scrolling stops.',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = true;
    Widget viewWithScroll() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Stack(
                children: <Widget>[
                  CupertinoScrollbar(
                    isAlwaysShown: isAlwaysShown,
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: const SizedBox(
                        width: 4000.0,
                        height: 4000.0,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: CupertinoButton(
                      onPressed: () {
                        setState(() {
                          isAlwaysShown = !isAlwaysShown;
                        });
                      },
                      child: const Text('change isAlwaysShown'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0.0, -10.0),
      10,
    );
    expect(find.byType(CupertinoScrollbar), paints..rrect());

    await tester.tap(find.byType(CupertinoButton));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));
  });

  testWidgets(
      'With isAlwaysShown: false, set isAlwaysShown: true. The thumb should be always shown directly',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = false;
    Widget viewWithScroll() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Stack(
                children: <Widget>[
                  CupertinoScrollbar(
                    isAlwaysShown: isAlwaysShown,
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: const SizedBox(
                        width: 4000.0,
                        height: 4000.0,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: CupertinoButton(
                      onPressed: () {
                        setState(() {
                          isAlwaysShown = !isAlwaysShown;
                        });
                      },
                      child: const Text('change isAlwaysShown'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));

    await tester.tap(find.byType(CupertinoButton));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), paints..rrect());
  });

  testWidgets(
      'With isAlwaysShown: false, fling a scroll. While it is still scrolling, set isAlwaysShown: true. The thumb should not fade even after the scrolling stops',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = false;
    Widget viewWithScroll() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Stack(
                children: <Widget>[
                  CupertinoScrollbar(
                    isAlwaysShown: isAlwaysShown,
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: const SizedBox(
                        width: 4000.0,
                        height: 4000.0,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: CupertinoButton(
                      onPressed: () {
                        setState(() {
                          isAlwaysShown = !isAlwaysShown;
                        });
                      },
                      child: const Text('change isAlwaysShown'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0.0, -10.0),
      10,
    );
    expect(find.byType(CupertinoScrollbar), paints..rrect());

    await tester.tap(find.byType(CupertinoButton));
    await tester.pump();
    expect(find.byType(CupertinoScrollbar), paints..rrect());

    // Wait for the timer delay to expire.
    await tester.pump(const Duration(milliseconds: 600)); // _kScrollbarTimeToFade
    await tester.pumpAndSettle();
    // Scrollbar thumb is showing after scroll finishes and timer ends.
    expect(find.byType(CupertinoScrollbar), paints..rrect());
  });

  testWidgets(
      'Toggling isAlwaysShown while not scrolling fades the thumb in/out. This works even when you have never scrolled at all yet',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = true;
    Widget viewWithScroll() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Stack(
                children: <Widget>[
                  CupertinoScrollbar(
                    isAlwaysShown: isAlwaysShown,
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: const SizedBox(
                        width: 4000.0,
                        height: 4000.0,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: CupertinoButton(
                      onPressed: () {
                        setState(() {
                          isAlwaysShown = !isAlwaysShown;
                        });
                      },
                      child: const Text('change isAlwaysShown'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), paints..rrect());

    await tester.tap(find.byType(CupertinoButton));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));
  });
}
