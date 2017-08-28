// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CustomPhysics extends ClampingScrollPhysics {
  const _CustomPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  _CustomPhysics applyTo(ScrollPhysics ancestor) {
    return new _CustomPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double dragVelocity) {
    return new ScrollSpringSimulation(spring, 1000.0, 1000.0, 1000.0);
  }
}

Widget buildTest({ ScrollController controller, String title:'TTTTTTTT' }) {
  return new MediaQuery(
    data: const MediaQueryData(),
    child: new Directionality(
      textDirection: TextDirection.ltr,
      child: new Scaffold(
        body: new DefaultTabController(
          length: 4,
          child: new NestedScrollView(
            controller: controller,
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                new SliverAppBar(
                  title: new Text(title),
                  pinned: true,
                  expandedHeight: 200.0,
                  forceElevated: innerBoxIsScrolled,
                  bottom: new TabBar(
                    tabs: const <Tab>[
                      const Tab(text: 'AA'),
                      const Tab(text: 'BB'),
                      const Tab(text: 'CC'),
                      const Tab(text: 'DD'),
                    ],
                  ),
                ),
              ];
            },
            body: new TabBarView(
              children: <Widget>[
                new ListView(
                  children: <Widget>[
                    new Container(
                      height: 300.0,
                      child: const Text('aaa1'),
                    ),
                    new Container(
                      height: 200.0,
                      child: const Text('aaa2'),
                    ),
                    new Container(
                      height: 100.0,
                      child: const Text('aaa3'),
                    ),
                    new Container(
                      height: 50.0,
                      child: const Text('aaa4'),
                    ),
                  ],
                ),
                new ListView(
                  children: <Widget>[
                    new Container(
                      height: 100.0,
                      child: const Text('bbb1'),
                    ),
                  ],
                ),
                new Container(
                  child: const Center(child: const Text('ccc1')),
                ),
                new ListView(
                  children: <Widget>[
                    new Container(
                      height: 10000.0,
                      child: const Text('ddd1'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('NestedScrollView overscroll and release and hold', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(buildTest());
    expect(find.text('aaa2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    final Offset point1 = tester.getCenter(find.text('aaa1'));
    await tester.dragFrom(point1, const Offset(0.0, 200.0));
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
    await tester.flingFrom(point1, const Offset(0.0, -80.0), 50000.0);
    await tester.pump(const Duration(milliseconds: 20));
    final Offset point2 = tester.getCenter(find.text('aaa1'));
    expect(point2.dy, greaterThan(point1.dy));
    // TODO(ianh): Once we improve how we handle scrolling down from overscroll,
    // the following expectation should switch to 200.0.
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 120.0);
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('NestedScrollView overscroll and release and hold', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(buildTest());
    expect(find.text('aaa2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    final Offset point = tester.getCenter(find.text('aaa1'));
    await tester.flingFrom(point, const Offset(0.0, 200.0), 5000.0);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('aaa2'), findsNothing);
    final TestGesture gesture1 = await tester.startGesture(point);
    await tester.pump(const Duration(milliseconds: 5000));
    expect(find.text('aaa2'), findsNothing);
    await gesture1.moveBy(const Offset(0.0, 50.0));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('aaa2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1000));
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('NestedScrollView overscroll and release', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(buildTest());
    expect(find.text('aaa2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    final TestGesture gesture1 = await tester.startGesture(tester.getCenter(find.text('aaa1')));
    await gesture1.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(find.text('aaa2'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await gesture1.up();
    await tester.pumpAndSettle();
    expect(find.text('aaa2'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  }, skip: true); // https://github.com/flutter/flutter/issues/9040
  testWidgets('NestedScrollView', (WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    expect(find.text('aaa2'), findsOneWidget);
    expect(find.text('aaa3'), findsNothing);
    expect(find.text('bbb1'), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);

    await tester.drag(find.text('AA'), const Offset(0.0, -20.0));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 180.0);

    await tester.drag(find.text('AA'), const Offset(0.0, -20.0));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 160.0);

    await tester.drag(find.text('AA'), const Offset(0.0, -20.0));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 140.0);

    expect(find.text('aaa4'), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.fling(find.text('AA'), const Offset(0.0, -50.0), 10000.0);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.text('aaa4'), findsOneWidget);

    final double minHeight = tester.renderObject<RenderBox>(find.byType(AppBar)).size.height;
    expect(minHeight, lessThan(140.0));

    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('BB'));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.text('aaa4'), findsNothing);
    expect(find.text('bbb1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('CC'));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.text('bbb1'), findsNothing);
    expect(find.text('ccc1'), findsOneWidget);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, minHeight);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.fling(find.text('AA'), const Offset(0.0, 50.0), 10000.0);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.text('ccc1'), findsOneWidget);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
  });

  testWidgets('NestedScrollView with a ScrollController', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController(initialScrollOffset: 50.0);

    double scrollOffset;
    controller.addListener(() {
      scrollOffset = controller.offset;
    });

    await tester.pumpWidget(buildTest(controller: controller));
    expect(controller.position.minScrollExtent, 0.0);
    expect(controller.position.pixels, 50.0);
    expect(controller.position.maxScrollExtent, 200.0);

    // The appbar's expandedHeight - initialScrollOffset = 150.
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 150.0);

    // Fully expand the appbar by scrolling (no animation) to 0.0.
    controller.jumpTo(0.0);
    await(tester.pumpAndSettle());
    expect(scrollOffset, 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);

    // Scroll back to 50.0 animating over 100ms.
    controller.animateTo(50.0, duration: const Duration(milliseconds: 100), curve: Curves.linear);
    await tester.pump();
    await tester.pump();
    expect(scrollOffset, 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
    await tester.pump(const Duration(milliseconds: 50)); // 50ms - halfway to scroll offset = 50.0.
    expect(scrollOffset, 25.0);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 175.0);
    await tester.pump(const Duration(milliseconds: 50)); // 100ms - all the way to scroll offset = 50.0.
    expect(scrollOffset, 50.0);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 150.0);

    // Scroll to the end, (we're not scrolling to the end of the list that contains aaa1,
    // just to the end of the outer scrollview). Verify that the first item in each tab
    // is still visible.
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(scrollOffset, 200.0);
    expect(find.text('aaa1'), findsOneWidget);

    await tester.tap(find.text('BB'));
    await tester.pumpAndSettle();
    expect(find.text('bbb1'), findsOneWidget);

    await tester.tap(find.text('CC'));
    await tester.pumpAndSettle();
    expect(find.text('ccc1'), findsOneWidget);

    await tester.tap(find.text('DD'));
    await tester.pumpAndSettle();
    expect(find.text('ddd1'), findsOneWidget);
  });

  testWidgets('Three NestedScrollViews with one ScrollController', (WidgetTester tester) async {
    final TrackingScrollController controller = new TrackingScrollController();
    expect(controller.mostRecentlyUpdatedPosition, isNull);
    expect(controller.initialScrollOffset, 0.0);

    await tester.pumpWidget(
      new PageView(
        children: <Widget>[
          buildTest(controller: controller, title: 'Page0'),
          buildTest(controller: controller, title: 'Page1'),
          buildTest(controller: controller, title: 'Page2'),
        ],
      ),
    );

    // Initially Page0 is visible and  Page0's appbar is fully expanded (height = 200.0).
    expect(find.text('Page0'), findsOneWidget);
    expect(find.text('Page1'), findsNothing);
    expect(find.text('Page2'), findsNothing);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);

    // A scroll collapses Page0's appbar to 150.0.
    controller.jumpTo(50.0);
    await(tester.pumpAndSettle());
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 150.0);

    // Fling to Page1. Page1's appbar height is the same as the appbar for Page0.
    await tester.fling(find.text('Page0'), const Offset(-100.0, 0.0), 10000.0);
    await(tester.pumpAndSettle());
    expect(find.text('Page0'), findsNothing);
    expect(find.text('Page1'), findsOneWidget);
    expect(find.text('Page2'), findsNothing);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 150.0);

    // Expand Page1's appbar and then fling to Page2.  Page2's appbar appears
    // fully expanded.
    controller.jumpTo(0.0);
    await(tester.pumpAndSettle());
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
    await tester.fling(find.text('Page1'), const Offset(-100.0, 0.0), 10000.0);
    await(tester.pumpAndSettle());
    expect(find.text('Page0'), findsNothing);
    expect(find.text('Page1'), findsNothing);
    expect(find.text('Page2'), findsOneWidget);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
  });

  testWidgets('NestedScrollViews with custom physics', (WidgetTester tester) async {
    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(),
      child: new NestedScrollView(
        physics: const _CustomPhysics(),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            const SliverAppBar(
              floating: true,
              title: const Text('AA'),
            ),
          ];
        },
        body: new Container(),
    )));
    expect(find.text('AA'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    final Offset point1 = tester.getCenter(find.text('AA'));
    await tester.dragFrom(point1, const Offset(0.0, 200.0));
    await tester.pump(const Duration(milliseconds: 20));
    final Offset point2 = tester.getCenter(find.text('AA'));
    expect(point1.dy, greaterThan(point2.dy));
  });

}
