// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);
const Color _kAndroidThumbIdleColor = Color(0xffbcbcbc);
const Rect _kAndroidTrackDimensions = Rect.fromLTRB(796.0, 0.0, 800.0, 600.0);
const Radius _kDefaultThumbRadius = Radius.circular(8.0);
const Color _kDefaultIdleThumbColor = Color(0x1a000000);
const Offset _kTrackBorderPoint1 = Offset(796.0, 0.0);
const Offset _kTrackBorderPoint2 = Offset(796.0, 600.0);

Rect getStartingThumbRect({ required bool isAndroid }) {
  return isAndroid
    // On Android the thumb is slightly different. The thumb is only 4 pixels wide,
    // and has no margin along the side of the viewport.
    ? const Rect.fromLTRB(796.0, 0.0, 800.0, 90.0)
    // The Material Design thumb is 8 pixels wide, with a 2
    // pixel margin to the right edge of the viewport.
    : const Rect.fromLTRB(790.0, 0.0, 798.0, 90.0);
}

class TestCanvas implements Canvas {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

Widget _buildBoilerplate({
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  required Widget child,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: MediaQueryData(padding: padding),
      child: child,
    ),
  );
}

void main() {
  testWidgets("Scrollbar doesn't show when tapping list", (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildBoilerplate(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFFF00))
            ),
            height: 200.0,
            width: 300.0,
            child: Scrollbar(
              child: ListView(
                children: <Widget>[
                  Container(height: 40.0, child: const Text('0')),
                  Container(height: 40.0, child: const Text('1')),
                  Container(height: 40.0, child: const Text('2')),
                  Container(height: 40.0, child: const Text('3')),
                  Container(height: 40.0, child: const Text('4')),
                  Container(height: 40.0, child: const Text('5')),
                  Container(height: 40.0, child: const Text('6')),
                  Container(height: 40.0, child: const Text('7')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    SchedulerBinding.instance!.debugAssertNoTransientCallbacks('Building a list with a scrollbar triggered an animation.');
    await tester.tap(find.byType(ListView));
    SchedulerBinding.instance!.debugAssertNoTransientCallbacks('Tapping a block with a scrollbar triggered an animation.');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.byType(ListView), const Offset(0.0, -10.0));
    expect(SchedulerBinding.instance!.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('ScrollbarPainter does not divide by zero', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildBoilerplate(child: Container(
        height: 200.0,
        width: 300.0,
        child: Scrollbar(
          child: ListView(
            children: <Widget>[
              Container(height: 40.0, child: const Text('0')),
            ],
          ),
        ),
      )),
    );

    final CustomPaint custom = tester.widget(find.descendant(
      of: find.byType(Scrollbar),
      matching: find.byType(CustomPaint),
    ).first);
    final dynamic scrollPainter = custom.foregroundPainter;
    // Dragging makes the scrollbar first appear.
    await tester.drag(find.text('0'), const Offset(0.0, -10.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    final ScrollMetrics metrics = FixedScrollMetrics(
      minScrollExtent: 0.0,
      maxScrollExtent: 0.0,
      pixels: 0.0,
      viewportDimension: 100.0,
      axisDirection: AxisDirection.down,
    );
    scrollPainter.update(metrics, AxisDirection.down);

    final TestCanvas canvas = TestCanvas();
    scrollPainter.paint(canvas, const Size(10.0, 100.0));

    // Scrollbar is not supposed to draw anything if there isn't enough content.
    expect(canvas.invocations.isEmpty, isTrue);
  });

  testWidgets('When isAlwaysShown is true, must pass a controller or find PrimaryScrollController',
      (WidgetTester tester) async {
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: const Scrollbar(
            isAlwaysShown: true,
            child: SingleChildScrollView(
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

  testWidgets('When isAlwaysShown is true, must pass a controller that is attached to a scroll view or find PrimaryScrollController',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: Scrollbar(
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
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: Scrollbar(
            isAlwaysShown: true,
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: const SizedBox(
                width: 4000.0,
                height: 4000.0,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), paints..rect());
  });

  testWidgets('On first render with isAlwaysShown: true, the thumb shows with PrimaryScrollController', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: PrimaryScrollController(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                return const Scrollbar(
                  isAlwaysShown: true,
                  child: SingleChildScrollView(
                    primary: true,
                    child: SizedBox(
                      width: 4000.0,
                      height: 4000.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), paints..rect());
  });

  testWidgets('On first render with isAlwaysShown: false, the thumb is hidden',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: Scrollbar(
            isAlwaysShown: false,
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: const SizedBox(
                width: 4000.0,
                height: 4000.0,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), isNot(paints..rect()));
  });

  testWidgets(
      'With isAlwaysShown: true, fling a scroll. While it is still scrolling, set isAlwaysShown: false. The thumb should not fade out until the scrolling stops.',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = true;
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Theme(
              data: ThemeData(),
              child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.threed_rotation),
                  onPressed: () {
                    setState(() {
                      isAlwaysShown = !isAlwaysShown;
                    });
                  },
                ),
                body: Scrollbar(
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
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0.0, -10.0),
      10,
    );
    expect(find.byType(Scrollbar), paints..rect());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // Scrollbar is not showing after scroll finishes
    expect(find.byType(Scrollbar), isNot(paints..rect()));
  });

  testWidgets(
      'With isAlwaysShown: false, set isAlwaysShown: true. The thumb should be always shown directly',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = false;
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Theme(
              data: ThemeData(),
              child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.threed_rotation),
                  onPressed: () {
                    setState(() {
                      isAlwaysShown = !isAlwaysShown;
                    });
                  },
                ),
                body: Scrollbar(
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
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), isNot(paints..rect()));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // Scrollbar is not showing after scroll finishes
    expect(find.byType(Scrollbar), paints..rect());
  });

  testWidgets(
      'With isAlwaysShown: false, fling a scroll. While it is still scrolling, set isAlwaysShown: true. The thumb should not fade even after the scrolling stops',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = false;
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Theme(
              data: ThemeData(),
              child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.threed_rotation),
                  onPressed: () {
                    setState(() {
                      isAlwaysShown = !isAlwaysShown;
                    });
                  },
                ),
                body: Scrollbar(
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
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), isNot(paints..rect()));
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0.0, -10.0),
      10,
    );
    expect(find.byType(Scrollbar), paints..rect());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.byType(Scrollbar), paints..rect());

    // Wait for the timer delay to expire.
    await tester.pump(const Duration(milliseconds: 600)); // _kScrollbarTimeToFade
    await tester.pumpAndSettle();
    // Scrollbar thumb is showing after scroll finishes and timer ends.
    expect(find.byType(Scrollbar), paints..rect());
  });

  testWidgets(
      'Toggling isAlwaysShown while not scrolling fades the thumb in/out. This works even when you have never scrolled at all yet',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    bool isAlwaysShown = true;
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Theme(
              data: ThemeData(),
              child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.threed_rotation),
                  onPressed: () {
                    setState(() {
                      isAlwaysShown = !isAlwaysShown;
                    });
                  },
                ),
                body: Scrollbar(
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
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll());
    await tester.pumpAndSettle();
    final Finder materialScrollbar = find.byType(Scrollbar);
    expect(materialScrollbar, paints..rect());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(materialScrollbar, isNot(paints..rect()));
  });

  testWidgets('Scrollbar respects thickness and radius', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll({Radius? radius}) {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: Scrollbar(
            controller: controller,
            thickness: 20,
            radius: radius,
            child: SingleChildScrollView(
              controller: controller,
              child: const SizedBox(
                width: 1600.0,
                height: 1200.0,
              ),
            ),
          ),
        ),
      );
    }

    // Scroll a bit to cause the scrollbar thumb to be shown;
    // undo the scroll to put the thumb back at the top.
    await tester.pumpWidget(viewWithScroll());
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
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(780.0, 0.0, 800.0, 600.0),
          color: Colors.transparent,
        )
        ..line(
          p1: const Offset(780.0, 0.0),
          p2: const Offset(780.0, 600.0),
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(780.0, 0.0, 800.0, 300.0),
          color: _kAndroidThumbIdleColor,
        ),
    );
    await tester.pumpWidget(viewWithScroll(radius: const Radius.circular(10)));
    expect(find.byType(Scrollbar), paints..rrect(
      rrect: RRect.fromRectAndRadius(const Rect.fromLTRB(780, 0.0, 800.0, 300.0), const Radius.circular(10)),
    ));

    await tester.pumpAndSettle();
  });

  testWidgets('Tapping the track area pages the Scroll View', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Scrollbar(
            interactive: true,
            isAlwaysShown: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(width: 1000.0, height: 1000.0),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 0.0, 800.0, 360.0),
          color: _kAndroidThumbIdleColor,
        ),
    );

    // Tap on the track area below the thumb.
    await tester.tapAt(const Offset(796.0, 550.0));
    await tester.pumpAndSettle();

    expect(scrollController.offset, 400.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 240.0, 800.0, 600.0),
          color: _kAndroidThumbIdleColor,
        ),
    );

    // Tap on the track area above the thumb.
    await tester.tapAt(const Offset(796.0, 50.0));
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 0.0, 800.0, 360.0),
          color: _kAndroidThumbIdleColor,
        ),
    );
  });

  testWidgets('Scrollbar never goes away until finger lift', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scrollbar(
          child: SingleChildScrollView(
            child: SizedBox(width: 4000.0, height: 4000.0)
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -20.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 3.0, 800.0, 93.0),
          color: _kAndroidThumbIdleColor,
        ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    // Still there.
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 3.0, 800.0, 93.0),
          color: _kAndroidThumbIdleColor,
        ),
    );

    await gesture.up();
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration * 0.5);

    // Opacity going down now.
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 3.0, 800.0, 93.0),
          color: const Color(0xc6bcbcbc),
        ),
    );
  });

  testWidgets('Scrollbar thumb can be dragged', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: scrollController,
          child: Scrollbar(
            interactive: true,
            isAlwaysShown: true,
            controller: scrollController,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0)
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: getStartingThumbRect(isAndroid: true),
          color: _kAndroidThumbIdleColor,
        ),
    );

    // Drag the thumb down to scroll down.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: getStartingThumbRect(isAndroid: true),
          // Drag color
          color: const Color(0x99000000),
        ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // The view has scrolled more than it would have by a swipe gesture of the
    // same distance.
    expect(scrollController.offset, greaterThan(scrollAmount * 2));
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: const Rect.fromLTRB(796.0, 10.0, 800.0, 100.0),
          color: _kAndroidThumbIdleColor,
        ),
    );
  });

  testWidgets('Scrollbar thumb color completes a hover animation', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: scrollController,
          child: Scrollbar(
            isAlwaysShown: true,
            controller: scrollController,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0)
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          getStartingThumbRect(isAndroid: false),
          _kDefaultThumbRadius,
        ),
        color: _kDefaultIdleThumbColor,
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          getStartingThumbRect(isAndroid: false),
          _kDefaultThumbRadius,
        ),
        // Hover color
        color: const Color(0x80000000),
      ),
    );
  },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    }),
  );

  testWidgets('Hover animation is not triggered by tap gestures', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: scrollController,
          child: Scrollbar(
            isAlwaysShown: true,
            showTrackOnHover: true,
            controller: scrollController,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0)
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          getStartingThumbRect(isAndroid: false),
          _kDefaultThumbRadius,
        ),
        color: _kDefaultIdleThumbColor,
      ),
    );
    await tester.tapAt(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    // Tapping triggers a hover enter event. In this case, the Scrollbar should
    // be unchanged since it ignores hover events that aren't from a mouse.
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          getStartingThumbRect(isAndroid: false),
          _kDefaultThumbRadius,
        ),
        color: _kDefaultIdleThumbColor,
      ),
    );

    // Now trigger hover with a mouse.
    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(794.0, 5.0));
    await tester.pump();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(784.0, 0.0, 800.0, 600.0),
          color: const Color(0x08000000),
        )
        ..line(
          p1: const Offset(784.0, 0.0),
          p2: const Offset(784.0, 600.0),
          strokeWidth: 1.0,
          color: _kDefaultIdleThumbColor,
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(786.0, 0.0, 798.0, 90.0),
            _kDefaultThumbRadius,
          ),
          // Hover color
          color: const Color(0x80000000),
        ),
    );

  },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.linux,
    }),
  );

  testWidgets('Scrollbar showTrackOnHover', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: scrollController,
          child: Scrollbar(
            isAlwaysShown: true,
            showTrackOnHover: true,
            controller: scrollController,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0)
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          getStartingThumbRect(isAndroid: false),
          _kDefaultThumbRadius,
        ),
        color: _kDefaultIdleThumbColor,
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(794.0, 5.0));
    await tester.pump();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(784.0, 0.0, 800.0, 600.0),
          color: const Color(0x08000000),
        )
        ..line(
          p1: const Offset(784.0, 0.0),
          p2: const Offset(784.0, 600.0),
          strokeWidth: 1.0,
          color: _kDefaultIdleThumbColor,
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(786.0, 0.0, 798.0, 90.0),
            _kDefaultThumbRadius,
          ),
          // Hover color
          color: const Color(0x80000000),
      ),
    );
  },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    }),
  );

  testWidgets('Adaptive scrollbar', (WidgetTester tester) async {
    Widget viewWithScroll(TargetPlatform platform) {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(
            platform: platform
          ),
          child: const Scrollbar(
            child: SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll(TargetPlatform.android));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Scrollbar), paints..rect());

    await tester.pumpWidget(viewWithScroll(TargetPlatform.iOS));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView))
    );
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Scrollbar), paints..rrect());
    expect(find.byType(CupertinoScrollbar), paints..rrect());
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Scrollbar passes controller to CupertinoScrollbar', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll(TargetPlatform? platform) {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(
            platform: platform
          ),
          child: Scrollbar(
            controller: controller,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(viewWithScroll(debugDefaultTargetPlatformOverride));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView))
    );
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CupertinoScrollbar), paints..rrect());
    final CupertinoScrollbar scrollbar = tester.widget<CupertinoScrollbar>(find.byType(CupertinoScrollbar));
    expect(scrollbar.controller, isNotNull);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

  testWidgets("Scrollbar doesn't show when scroll the inner scrollable widget", (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();
    final GlobalKey outerKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Scrollbar(
            key: key2,
            notificationPredicate: null,
            child: SingleChildScrollView(
              key: outerKey,
              child: SizedBox(
                height: 1000.0,
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    Scrollbar(
                      key: key1,
                      notificationPredicate: null,
                      child: SizedBox(
                        height: 300.0,
                        width: double.infinity,
                        child: SingleChildScrollView(
                          key: innerKey,
                          child: const SizedBox(
                            key: Key('Inner scrollable'),
                            height: 1000.0,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Drag the inner scrollable widget.
    await tester.drag(find.byKey(innerKey), const Offset(0.0, -25.0));
    await tester.pump();
    // Scrollbar fully showing.
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.renderObject(find.byKey(key2)),
      paintsExactlyCountTimes(#drawRect, 2), // Each bar will call [drawRect] twice.
    );

    expect(
      tester.renderObject(find.byKey(key1)),
      paintsExactlyCountTimes(#drawRect, 2),
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets('Scrollbar dragging can be disabled', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: scrollController,
          child: Scrollbar(
            interactive: false,
            isAlwaysShown: true,
            controller: scrollController,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(788.0, 0.0, 800.0, 600.0),
          color: Colors.transparent,
        )
        ..line(
          p1: const Offset(788.0, 0.0),
          p2: const Offset(788.0, 600.0),
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            getStartingThumbRect(isAndroid: false),
            _kDefaultThumbRadius,
          ),
          color: _kDefaultIdleThumbColor,
        ),
    );

    // Try to drag the thumb down.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarThumbGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();
    await dragScrollbarThumbGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarThumbGesture.up();
    await tester.pumpAndSettle();
    // Dragging on the thumb does not change the offset.
    expect(scrollController.offset, 0.0);

    // Drag in the track area to validate pass through to scrollable.
    final TestGesture dragPassThroughTrack = await tester.startGesture(const Offset(797.0, 250.0));
    await dragPassThroughTrack.moveBy(const Offset(0.0, -scrollAmount));
    await tester.pumpAndSettle();
    await dragPassThroughTrack.up();
    await tester.pumpAndSettle();
    // The scroll view received the drag.
    expect(scrollController.offset, scrollAmount);

    // Tap on the track to validate the scroll view will not page.
    await tester.tapAt(const Offset(797.0, 200.0));
    await tester.pumpAndSettle();
    // The offset should not have changed.
    expect(scrollController.offset, scrollAmount);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{
    TargetPlatform.linux,
    TargetPlatform.windows,
    TargetPlatform.fuchsia,
  }));

  testWidgets('Scrollbar dragging is disabled by default on Android', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: scrollController,
          child: Scrollbar(
            isAlwaysShown: true,
            controller: scrollController,
            child: const SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0)
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: _kAndroidTrackDimensions,
          color: Colors.transparent,
        )
        ..line(
          p1: _kTrackBorderPoint1,
          p2: _kTrackBorderPoint2,
          strokeWidth: 1.0,
          color: Colors.transparent,
        )
        ..rect(
          rect: getStartingThumbRect(isAndroid: true),
          color: _kAndroidThumbIdleColor,
        ),
    );

    // Try to drag the thumb down.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarThumbGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();
    await dragScrollbarThumbGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarThumbGesture.up();
    await tester.pumpAndSettle();
    // Dragging on the thumb does not change the offset.
    expect(scrollController.offset, 0.0);

    // Drag in the track area to validate pass through to scrollable.
    final TestGesture dragPassThroughTrack = await tester.startGesture(const Offset(797.0, 250.0));
    await dragPassThroughTrack.moveBy(const Offset(0.0, -scrollAmount));
    await tester.pumpAndSettle();
    await dragPassThroughTrack.up();
    await tester.pumpAndSettle();
    // The scroll view received the drag.
    expect(scrollController.offset, scrollAmount);

    // Tap on the track to validate the scroll view will not page.
    await tester.tapAt(const Offset(797.0, 200.0));
    await tester.pumpAndSettle();
    // The offset should not have changed.
    expect(scrollController.offset, scrollAmount);
  });
}
