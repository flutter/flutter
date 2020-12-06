// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class TestCanvas implements Canvas {
  TestCanvas([this.invocations]);

  final List<Invocation> invocations;

  @override
  void noSuchMethod(Invocation invocation) {
    invocations?.add(invocation);
  }
}

Widget _buildBoilerplate({
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  Widget child,
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

    SchedulerBinding.instance.debugAssertNoTransientCallbacks('Building a list with a scrollbar triggered an animation.');
    await tester.tap(find.byType(ListView));
    SchedulerBinding.instance.debugAssertNoTransientCallbacks('Tapping a block with a scrollbar triggered an animation.');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.byType(ListView), const Offset(0.0, -10.0));
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
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

    final List<Invocation> invocations = <Invocation>[];
    final TestCanvas canvas = TestCanvas(invocations);
    scrollPainter.paint(canvas, const Size(10.0, 100.0));

    // Scrollbar is not supposed to draw anything if there isn't enough content.
    expect(invocations.isEmpty, isTrue);
  });

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

    await tester.pumpWidget(viewWithScroll(TargetPlatform.macOS));
    await gesture.down(
      tester.getCenter(find.byType(SingleChildScrollView)),
    );
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Scrollbar), paints..rrect());
    expect(find.byType(CupertinoScrollbar), paints..rrect());
  });

  testWidgets('Scrollbar passes controller to CupertinoScrollbar', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    Widget viewWithScroll(TargetPlatform platform) {
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
    final CupertinoScrollbar scrollbar = find.byType(CupertinoScrollbar).evaluate().first.widget as CupertinoScrollbar;
    expect(scrollbar.controller, isNotNull);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('When isAlwaysShown is true, must pass a controller',
      (WidgetTester tester) async {
    Widget viewWithScroll() {
      return _buildBoilerplate(
        child: Theme(
          data: ThemeData(),
          child: Scrollbar(
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
    Widget viewWithScroll({Radius radius}) {
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
    expect(find.byType(Scrollbar), paints..rect(
      rect: const Rect.fromLTWH(780, 0, 20, 300),
    ));
    await tester.pumpWidget(viewWithScroll(radius: const Radius.circular(10)));
    expect(find.byType(Scrollbar), paints..rrect(
      rrect: RRect.fromRectAndRadius(const Rect.fromLTWH(780, 0, 20, 300), const Radius.circular(10)),
    ));

    await tester.pumpAndSettle();
  });
}
