// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class _CustomPhysics extends ClampingScrollPhysics {
  const _CustomPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  _CustomPhysics applyTo(ScrollPhysics ancestor) {
    return _CustomPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double dragVelocity) {
    return ScrollSpringSimulation(spring, 1000.0, 1000.0, 1000.0);
  }
}

Widget buildTest({ ScrollController controller, String title ='TTTTTTTT' }) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Scaffold(
          body: DefaultTabController(
            length: 4,
            child: NestedScrollView(
              controller: controller,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    title: Text(title),
                    pinned: true,
                    expandedHeight: 200.0,
                    forceElevated: innerBoxIsScrolled,
                    bottom: const TabBar(
                      tabs: <Tab>[
                        Tab(text: 'AA'),
                        Tab(text: 'BB'),
                        Tab(text: 'CC'),
                        Tab(text: 'DD'),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: <Widget>[
                  ListView(
                    children: <Widget>[
                      Container(
                        height: 300.0,
                        child: const Text('aaa1'),
                      ),
                      Container(
                        height: 200.0,
                        child: const Text('aaa2'),
                      ),
                      Container(
                        height: 100.0,
                        child: const Text('aaa3'),
                      ),
                      Container(
                        height: 50.0,
                        child: const Text('aaa4'),
                      ),
                    ],
                  ),
                  ListView(
                    children: <Widget>[
                      Container(
                        height: 100.0,
                        child: const Text('bbb1'),
                      ),
                    ],
                  ),
                  Container(
                    child: const Center(child: Text('ccc1')),
                  ),
                  ListView(
                    children: <Widget>[
                      Container(
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
    final ScrollController controller = ScrollController(initialScrollOffset: 50.0);

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
    await tester.pumpAndSettle();
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
    final TrackingScrollController controller = TrackingScrollController();
    expect(controller.mostRecentlyUpdatedPosition, isNull);
    expect(controller.initialScrollOffset, 0.0);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
        children: <Widget>[
          buildTest(controller: controller, title: 'Page0'),
          buildTest(controller: controller, title: 'Page1'),
          buildTest(controller: controller, title: 'Page2'),
        ],
      ),
    ));

    // Initially Page0 is visible and Page0's appbar is fully expanded (height = 200.0).
    expect(find.text('Page0'), findsOneWidget);
    expect(find.text('Page1'), findsNothing);
    expect(find.text('Page2'), findsNothing);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);

    // A scroll collapses Page0's appbar to 150.0.
    controller.jumpTo(50.0);
    await tester.pumpAndSettle();
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 150.0);

    // Fling to Page1. Page1's appbar height is the same as the appbar for Page0.
    await tester.fling(find.text('Page0'), const Offset(-100.0, 0.0), 10000.0);
    await tester.pumpAndSettle();
    expect(find.text('Page0'), findsNothing);
    expect(find.text('Page1'), findsOneWidget);
    expect(find.text('Page2'), findsNothing);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 150.0);

    // Expand Page1's appbar and then fling to Page2. Page2's appbar appears
    // fully expanded.
    controller.jumpTo(0.0);
    await tester.pumpAndSettle();
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
    await tester.fling(find.text('Page1'), const Offset(-100.0, 0.0), 10000.0);
    await tester.pumpAndSettle();
    expect(find.text('Page0'), findsNothing);
    expect(find.text('Page1'), findsNothing);
    expect(find.text('Page2'), findsOneWidget);
    expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 200.0);
  });

  testWidgets('NestedScrollViews with custom physics', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: MediaQuery(
          data: const MediaQueryData(),
          child: NestedScrollView(
            physics: const _CustomPhysics(),
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                const SliverAppBar(
                  floating: true,
                  title: Text('AA'),
                ),
              ];
            },
            body: Container(),
          ),
        ),
      ),
    ));
    expect(find.text('AA'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    final Offset point1 = tester.getCenter(find.text('AA'));
    await tester.dragFrom(point1, const Offset(0.0, 200.0));
    await tester.pump(const Duration(milliseconds: 20));
    final Offset point2 = tester.getCenter(find.text('AA', skipOffstage: false));
    expect(point1.dy, greaterThan(point2.dy));
  });

  testWidgets('NestedScrollView and internal scrolling', (WidgetTester tester) async {
    debugDisableShadows = false;
    const List<String> _tabs = <String>['Hello', 'World'];
    int buildCount = 0;
    await tester.pumpWidget(
      MaterialApp(home: Material(child:
        // THE FOLLOWING SECTION IS FROM THE NestedScrollView DOCUMENTATION
        // (EXCEPT FOR THE CHANGES TO THE buildCount COUNTER)
        DefaultTabController(
          length: _tabs.length, // This is the number of tabs.
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              buildCount += 1; // THIS LINE IS NOT IN THE ORIGINAL -- ADDED FOR TEST
              // These are the slivers that show up in the "outer" scroll view.
              return <Widget>[
                SliverOverlapAbsorber(
                  // This widget takes the overlapping behavior of the SliverAppBar,
                  // and redirects it to the SliverOverlapInjector below. If it is
                  // missing, then it is possible for the nested "inner" scroll view
                  // below to end up under the SliverAppBar even when the inner
                  // scroll view thinks it has not been scrolled.
                  // This is not necessary if the "headerSliverBuilder" only builds
                  // widgets that do not overlap the next sliver.
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  child: SliverAppBar(
                    title: const Text('Books'), // This is the title in the app bar.
                    pinned: true,
                    expandedHeight: 150.0,
                    // The "forceElevated" property causes the SliverAppBar to show
                    // a shadow. The "innerBoxIsScrolled" parameter is true when the
                    // inner scroll view is scrolled beyond its "zero" point, i.e.
                    // when it appears to be scrolled below the SliverAppBar.
                    // Without this, there are cases where the shadow would appear
                    // or not appear inappropriately, because the SliverAppBar is
                    // not actually aware of the precise position of the inner
                    // scroll views.
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      // These are the widgets to put in each tab in the tab bar.
                      tabs: _tabs.map<Widget>((String name) => Tab(text: name)).toList(),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              // These are the contents of the tab views, below the tabs.
              children: _tabs.map<Widget>((String name) {
                return SafeArea(
                  top: false,
                  bottom: false,
                  child: Builder(
                    // This Builder is needed to provide a BuildContext that is "inside"
                    // the NestedScrollView, so that sliverOverlapAbsorberHandleFor() can
                    // find the NestedScrollView.
                    builder: (BuildContext context) {
                      return CustomScrollView(
                        // The "controller" and "primary" members should be left
                        // unset, so that the NestedScrollView can control this
                        // inner scroll view.
                        // If the "controller" property is set, then this scroll
                        // view will not be associated with the NestedScrollView.
                        // The PageStorageKey should be unique to this ScrollView;
                        // it allows the list to remember its scroll position when
                        // the tab view is not on the screen.
                        key: PageStorageKey<String>(name),
                        slivers: <Widget>[
                          SliverOverlapInjector(
                            // This is the flip side of the SliverOverlapAbsorber above.
                            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(8.0),
                            // In this example, the inner scroll view has
                            // fixed-height list items, hence the use of
                            // SliverFixedExtentList. However, one could use any
                            // sliver widget here, e.g. SliverList or SliverGrid.
                            sliver: SliverFixedExtentList(
                              // The items in this example are fixed to 48 pixels
                              // high. This matches the Material Design spec for
                              // ListTile widgets.
                              itemExtent: 48.0,
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                                  // This builder is called for each child.
                                  // In this example, we just number each list item.
                                  return ListTile(
                                    title: Text('Item $index'),
                                  );
                                },
                                // The childCount of the SliverChildBuilderDelegate
                                // specifies how many children this inner list
                                // has. In this example, each tab has a list of
                                // exactly 30 items, but this is arbitrary.
                                childCount: 30,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        )
        // END
      )),
    );
    int expectedBuildCount = 0;
    expectedBuildCount += 1;
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 18'), findsNothing);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    // scroll down
    final TestGesture gesture0 = await tester.startGesture(tester.getCenter(find.text('Item 2')));
    await gesture0.moveBy(const Offset(0.0, -120.0)); // tiny bit more than the pinned app bar height (56px * 2)
    await tester.pump();
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 18'), findsNothing);
    await gesture0.up();
    await tester.pump(const Duration(milliseconds: 1)); // start shadow animation
    expectedBuildCount += 1;
    expect(buildCount, expectedBuildCount);
    await tester.pump(const Duration(milliseconds: 1)); // during shadow animation
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), paints..shadow());
    await tester.pump(const Duration(seconds: 1)); // end shadow animation
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), paints..shadow());
    // scroll down
    final TestGesture gesture1 = await tester.startGesture(tester.getCenter(find.text('Item 2')));
    await gesture1.moveBy(const Offset(0.0, -800.0));
    await tester.pump();
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), paints..shadow());
    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 18'), findsOneWidget);
    await gesture1.up();
    await tester.pump(const Duration(seconds: 1));
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), paints..shadow());
    // swipe left to bring in tap on the right
    final TestGesture gesture2 = await tester.startGesture(tester.getCenter(find.byType(NestedScrollView)));
    await gesture2.moveBy(const Offset(-400.0, 0.0));
    await tester.pump();
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 18'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
    expect(tester.getTopLeft(find.ancestor(of: find.text('Item 0'), matching: find.byType(ListTile))).dy,
           tester.getBottomLeft(find.byType(AppBar)).dy + 8.0);
    expect(find.byType(NestedScrollView), paints..shadow());
    await gesture2.up();
    await tester.pump(); // start sideways scroll
    await tester.pump(const Duration(seconds: 1)); // end sideways scroll, triggers shadow going away
    expect(buildCount, expectedBuildCount);
    await tester.pump(const Duration(seconds: 1)); // start shadow going away
    expectedBuildCount += 1;
    expect(buildCount, expectedBuildCount);
    await tester.pump(const Duration(seconds: 1)); // end shadow going away
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 18'), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    await tester.pump(const Duration(seconds: 1)); // just checking we don't rebuild...
    expect(buildCount, expectedBuildCount);
    // peek left to see it's still in the right place
    final TestGesture gesture3 = await tester.startGesture(tester.getCenter(find.byType(NestedScrollView)));
    await gesture3.moveBy(const Offset(400.0, 0.0));
    await tester.pump(); // bring the left page into view
    expect(buildCount, expectedBuildCount);
    await tester.pump(); // shadow comes back starting here
    expectedBuildCount += 1;
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 18'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    await tester.pump(const Duration(seconds: 1)); // shadow finishes coming back
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), paints..shadow());
    await gesture3.moveBy(const Offset(-400.0, 0.0));
    await gesture3.up();
    await tester.pump(); // left tab view goes away
    expect(buildCount, expectedBuildCount);
    await tester.pump(); // shadow goes away starting here
    expectedBuildCount += 1;
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), paints..shadow());
    await tester.pump(const Duration(seconds: 1)); // shadow finishes going away
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    // scroll back up
    final TestGesture gesture4 = await tester.startGesture(tester.getCenter(find.byType(NestedScrollView)));
    await gesture4.moveBy(const Offset(0.0, 200.0)); // expands the appbar again
    await tester.pump();
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 18'), findsNothing);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    await gesture4.up();
    await tester.pump(const Duration(seconds: 1));
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    // peek left to see it's now back at zero
    final TestGesture gesture5 = await tester.startGesture(tester.getCenter(find.byType(NestedScrollView)));
    await gesture5.moveBy(const Offset(400.0, 0.0));
    await tester.pump(); // bring the left page into view
    await tester.pump(); // shadow would come back starting here, but there's no shadow to show
    expect(buildCount, expectedBuildCount);
    expect(find.text('Item 18'), findsNothing);
    expect(find.text('Item 2'), findsNWidgets(2));
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    await tester.pump(const Duration(seconds: 1)); // shadow would be finished coming back
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    await gesture5.up();
    await tester.pump(); // right tab view goes away
    await tester.pumpAndSettle();
    expect(buildCount, expectedBuildCount);
    expect(find.byType(NestedScrollView), isNot(paints..shadow()));
    debugDisableShadows = true;
  });

  testWidgets('NestedScrollView and iOS bouncing', (WidgetTester tester) async {
    // This verifies that overscroll bouncing works correctly on iOS. For
    // example, this checks that if you pull to overscroll, friction is applied;
    // it also makes sure that if you scroll back the other way, the scroll
    // positions of the inner and outer list don't have a discontinuity.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const Key key1 = ValueKey<int>(1);
    const Key key2 = ValueKey<int>(2);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DefaultTabController(
            length: 1,
            child: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  const SliverPersistentHeader(
                    delegate: TestHeader(key: key1),
                  ),
                ];
              },
              body: SingleChildScrollView(
                child: Container(
                  height: 1000.0,
                  child: const Placeholder(key: key2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, 0.0, 800.0, 100.0));
    expect(tester.getRect(find.byKey(key2)), Rect.fromLTWH(0.0, 100.0, 800.0, 1000.0));
    final TestGesture gesture = await tester.startGesture(const Offset(10.0, 10.0));
    await gesture.moveBy(const Offset(0.0, -10.0)); // scroll up
    await tester.pump();
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, -10.0, 800.0, 100.0));
    expect(tester.getRect(find.byKey(key2)), Rect.fromLTWH(0.0, 90.0, 800.0, 1000.0));
    await gesture.moveBy(const Offset(0.0, 10.0)); // scroll back to origin
    await tester.pump();
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, 0.0, 800.0, 100.0));
    expect(tester.getRect(find.byKey(key2)), Rect.fromLTWH(0.0, 100.0, 800.0, 1000.0));
    await gesture.moveBy(const Offset(0.0, 10.0)); // overscroll
    await gesture.moveBy(const Offset(0.0, 10.0)); // overscroll
    await gesture.moveBy(const Offset(0.0, 10.0)); // overscroll
    await tester.pump();
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, 0.0, 800.0, 100.0));
    expect(tester.getRect(find.byKey(key2)).top, greaterThan(100.0));
    expect(tester.getRect(find.byKey(key2)).top, lessThan(130.0));
    await gesture.moveBy(const Offset(0.0, -1.0)); // scroll back a little
    await tester.pump();
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, -1.0, 800.0, 100.0));
    expect(tester.getRect(find.byKey(key2)).top, greaterThan(100.0));
    expect(tester.getRect(find.byKey(key2)).top, lessThan(129.0));
    await gesture.moveBy(const Offset(0.0, -10.0)); // scroll back a lot
    await tester.pump();
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, -11.0, 800.0, 100.0));
    await gesture.moveBy(const Offset(0.0, 20.0)); // overscroll again
    await tester.pump();
    expect(tester.getRect(find.byKey(key1)), Rect.fromLTWH(0.0, 0.0, 800.0, 100.0));
    await gesture.up();
    debugDefaultTargetPlatformOverride = null;
  });
}

class TestHeader extends SliverPersistentHeaderDelegate {
  const TestHeader({ this.key });
  final Key key;
  @override
  double get minExtent => 100.0;
  @override
  double get maxExtent => 100.0;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Placeholder(key: key);
  }
  @override
  bool shouldRebuild(TestHeader oldDelegate) => false;
}
