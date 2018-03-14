// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlag, SemanticsAction;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/physics.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';
import '../widgets/semantics_tester.dart';

Widget boilerplate({ Widget child, TextDirection textDirection: TextDirection.ltr }) {
  return new Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: new Directionality(
      textDirection: textDirection,
      child: new Material(
        child: child,
      ),
    ),
  );
}

class StateMarker extends StatefulWidget {
  const StateMarker({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  StateMarkerState createState() => new StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String marker;

  @override
  Widget build(BuildContext context) {
    if (widget.child != null)
      return widget.child;
    return new Container();
  }
}

Widget buildFrame({
    Key tabBarKey,
    List<String> tabs,
    String value,
    bool isScrollable: false,
    Color indicatorColor,
  }) {
  return boilerplate(
    child: new DefaultTabController(
      initialIndex: tabs.indexOf(value),
      length: tabs.length,
      child: new TabBar(
        key: tabBarKey,
        tabs: tabs.map((String tab) => new Tab(text: tab)).toList(),
        isScrollable: isScrollable,
        indicatorColor: indicatorColor,
      ),
    ),
  );
}

typedef Widget TabControllerFrameBuilder(BuildContext context, TabController controller);

class TabControllerFrame extends StatefulWidget {
  const TabControllerFrame({ this.length, this.initialIndex: 0, this.builder });

  final int length;
  final int initialIndex;
  final TabControllerFrameBuilder builder;

  @override
  TabControllerFrameState createState() => new TabControllerFrameState();
}

class TabControllerFrameState extends State<TabControllerFrame> with SingleTickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TabController(
      vsync: this,
      length: widget.length,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}

Widget buildLeftRightApp({ List<String> tabs, String value }) {
  return new MaterialApp(
    theme: new ThemeData(platform: TargetPlatform.android),
    home: new DefaultTabController(
      initialIndex: tabs.indexOf(value),
      length: tabs.length,
      child: new Scaffold(
        appBar: new AppBar(
          title: const Text('tabs'),
          bottom: new TabBar(
            tabs: tabs.map((String tab) => new Tab(text: tab)).toList(),
          ),
        ),
        body: const TabBarView(
          children: const <Widget>[
            const Center(child: const Text('LEFT CHILD')),
            const Center(child: const Text('RIGHT CHILD'))
          ]
        )
      )
    )
  );
}

class TabIndicatorRecordingCanvas extends TestRecordingCanvas {
  TabIndicatorRecordingCanvas(this.indicatorColor);

  final Color indicatorColor;
  Rect indicatorRect;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    // Assuming that the indicatorWeight is 2.0, the default.
    const double indicatorWeight = 2.0;
    if (paint.color == indicatorColor)
      indicatorRect = new Rect.fromPoints(p1, p2).inflate(indicatorWeight / 2.0);
  }
}

class TestScrollPhysics extends ScrollPhysics {
  const TestScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  TestScrollPhysics applyTo(ScrollPhysics ancestor) {
    return new TestScrollPhysics(parent: buildParent(ancestor));
  }

  static final SpringDescription _kDefaultSpring = new SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 500.0,
    ratio: 1.1,
  );

  @override
  SpringDescription get spring => _kDefaultSpring;
}

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('TabBar tap selects tab', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    final TabController controller = DefaultTabController.of(tester.element(find.text('A')));
    expect(controller, isNotNull);
    expect(controller.index, 2);
    expect(controller.previousIndex, 2);

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(controller.indexIsChanging, true);
    await tester.pump(const Duration(seconds: 1)); // finish the animation
    expect(controller.index, 1);
    expect(controller.previousIndex, 2);
    expect(controller.indexIsChanging, false);

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.index, 2);
    expect(controller.previousIndex, 1);

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.index, 0);
    expect(controller.previousIndex, 2);
  });

  testWidgets('Scrollable TabBar tap selects tab', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    final TabController controller = DefaultTabController.of(tester.element(find.text('A')));
    expect(controller.index, 2);
    expect(controller.previousIndex, 2);

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(controller.index, 2);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(controller.index, 1);

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
  });

  testWidgets('Scrollable TabBar tap centers selected tab', (WidgetTester tester) async {
    final List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
    const Key tabBarKey = const Key('TabBar');
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAAAA', isScrollable: true, tabBarKey: tabBarKey));
    final TabController controller = DefaultTabController.of(tester.element(find.text('AAAAAA')));
    expect(controller, isNotNull);
    expect(controller.index, 0);

    expect(tester.getSize(find.byKey(tabBarKey)).width, equals(800.0));
    // The center of the FFFFFF item is to the right of the TabBar's center
    expect(tester.getCenter(find.text('FFFFFF')).dx, greaterThan(401.0));

    await tester.tap(find.text('FFFFFF'));
    await tester.pumpAndSettle();
    expect(controller.index, 5);
    // The center of the FFFFFF item is now at the TabBar's center
    expect(tester.getCenter(find.text('FFFFFF')).dx, closeTo(400.0, 1.0));
  });


  testWidgets('TabBar can be scrolled independent of the selection', (WidgetTester tester) async {
    final List<String> tabs = <String>['AAAA', 'BBBB', 'CCCC', 'DDDD', 'EEEE', 'FFFF', 'GGGG', 'HHHH', 'IIII', 'JJJJ', 'KKKK', 'LLLL'];
    const Key tabBarKey = const Key('TabBar');
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAA', isScrollable: true, tabBarKey: tabBarKey));
    final TabController controller = DefaultTabController.of(tester.element(find.text('AAAA')));
    expect(controller, isNotNull);
    expect(controller.index, 0);

    // Fling-scroll the TabBar to the left
    expect(tester.getCenter(find.text('HHHH')).dx, lessThan(700.0));
    await tester.fling(find.byKey(tabBarKey), const Offset(-200.0, 0.0), 10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(tester.getCenter(find.text('HHHH')).dx, lessThan(500.0));

    // Scrolling the TabBar doesn't change the selection
    expect(controller.index, 0);
  });

  testWidgets('TabBarView maintains state', (WidgetTester tester) async {
    final List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE'];
    String value = tabs[0];

    Widget builder() {
      return boilerplate(
        child: new DefaultTabController(
          initialIndex: tabs.indexOf(value),
          length: tabs.length,
          child: new TabBarView(
            children: tabs.map((String name) {
              return new StateMarker(
                child: new Text(name)
              );
            }).toList()
          ),
        ),
      );
    }

    StateMarkerState findStateMarkerState(String name) {
      return tester.state(find.widgetWithText(StateMarker, name));
    }

    await tester.pumpWidget(builder());
    final TabController controller = DefaultTabController.of(tester.element(find.text('AAAAAA')));

    TestGesture gesture = await tester.startGesture(tester.getCenter(find.text(tabs[0])));
    await gesture.moveBy(const Offset(-600.0, 0.0));
    await tester.pump();
    expect(value, equals(tabs[0]));
    findStateMarkerState(tabs[1]).marker = 'marked';
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    value = tabs[controller.index];
    expect(value, equals(tabs[1]));
    await tester.pumpWidget(builder());
    expect(findStateMarkerState(tabs[1]).marker, equals('marked'));

    // Move to the third tab.

    gesture = await tester.startGesture(tester.getCenter(find.text(tabs[1])));
    await gesture.moveBy(const Offset(-600.0, 0.0));
    await gesture.up();
    await tester.pump();
    expect(findStateMarkerState(tabs[1]).marker, equals('marked'));
    await tester.pump(const Duration(seconds: 1));
    value = tabs[controller.index];
    expect(value, equals(tabs[2]));
    await tester.pumpWidget(builder());

    // The state is now gone.

    expect(find.text(tabs[1]), findsNothing);

    // Move back to the second tab.

    gesture = await tester.startGesture(tester.getCenter(find.text(tabs[2])));
    await gesture.moveBy(const Offset(600.0, 0.0));
    await tester.pump();
    final StateMarkerState markerState = findStateMarkerState(tabs[1]);
    expect(markerState.marker, isNull);
    markerState.marker = 'marked';
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    value = tabs[controller.index];
    expect(value, equals(tabs[1]));
    await tester.pumpWidget(builder());
    expect(findStateMarkerState(tabs[1]).marker, equals('marked'));
  });

  testWidgets('TabBar left/right fling', (WidgetTester tester) async {
    final List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')));
    expect(controller.index, 0);

    // Fling to the left, switch from the 'LEFT' tab to the 'RIGHT'
    Offset flingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(flingStart, const Offset(-200.0, 0.0), 10000.0);
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(find.text('LEFT CHILD'), findsNothing);
    expect(find.text('RIGHT CHILD'), findsOneWidget);

    // Fling to the right, switch back to the 'LEFT' tab
    flingStart = tester.getCenter(find.text('RIGHT CHILD'));
    await tester.flingFrom(flingStart, const Offset(200.0, 0.0), 10000.0);
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);
  });

  testWidgets('TabBar left/right fling reverse (1)', (WidgetTester tester) async {
    final List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')));
    expect(controller.index, 0);

    final Offset flingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(flingStart, const Offset(200.0, 0.0), 10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(controller.index, 0);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);
  });

  testWidgets('TabBar left/right fling reverse (2)', (WidgetTester tester) async {
    final List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')));
    expect(controller.index, 0);

    final Offset flingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(flingStart, const Offset(-200.0, 0.0), 10000.0);
    await tester.pump();
    // this is similar to a test above, but that one does many more pumps
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(controller.index, 1);
    expect(find.text('LEFT CHILD'), findsNothing);
    expect(find.text('RIGHT CHILD'), findsOneWidget);
  });

  // A regression test for https://github.com/flutter/flutter/issues/5095
  testWidgets('TabBar left/right fling reverse (2)', (WidgetTester tester) async {
    final List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')));
    expect(controller.index, 0);

    final Offset flingStart = tester.getCenter(find.text('LEFT CHILD'));
    final TestGesture gesture = await tester.startGesture(flingStart);
    for (int index = 0; index > 50; index += 1) {
      await gesture.moveBy(const Offset(-10.0, 0.0));
      await tester.pump(const Duration(milliseconds: 1));
    }
    // End the fling by reversing direction. This should cause not cause
    // a change to the selected tab, everything should just settle back to
    // to where it started.
    for (int index = 0; index > 50; index += 1) {
      await gesture.moveBy(const Offset(10.0, 0.0));
      await tester.pump(const Duration(milliseconds: 1));
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(controller.index, 0);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);
  });

  // A regression test for https://github.com/flutter/flutter/issues/7133
  testWidgets('TabBar fling velocity', (WidgetTester tester) async {
    final List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
    int index = 0;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Align(
          alignment: Alignment.topLeft,
          child: new SizedBox(
            width: 300.0,
            height: 200.0,
            child: new DefaultTabController(
              length: tabs.length,
              child: new Scaffold(
                appBar: new AppBar(
                  title: const Text('tabs'),
                  bottom: new TabBar(
                    isScrollable: true,
                    tabs: tabs.map((String tab) => new Tab(text: tab)).toList(),
                  ),
                ),
                body: new TabBarView(
                  children: tabs.map((String name) => new Text('${index++}')).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // After a small slow fling to the left, we expect the second item to still be visible.
    await tester.fling(find.text('AAAAAA'), const Offset(-25.0, 0.0), 100.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    final RenderBox box = tester.renderObject(find.text('BBBBBB'));
    expect(box.localToGlobal(Offset.zero).dx, greaterThan(0.0));
  });

  testWidgets('TabController change notification', (WidgetTester tester) async {
    final List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')));

    expect(controller, isNotNull);
    expect(controller.index, 0);

    String value;
    controller.addListener(() {
      value = tabs[controller.index];
    });

    await tester.tap(find.text('RIGHT'));
    await tester.pumpAndSettle();
    expect(value, 'RIGHT');

    await tester.tap(find.text('LEFT'));
    await tester.pumpAndSettle();
    expect(value, 'LEFT');

    final Offset leftFlingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(leftFlingStart, const Offset(-200.0, 0.0), 10000.0);
    await tester.pumpAndSettle();
    expect(value, 'RIGHT');

    final Offset rightFlingStart = tester.getCenter(find.text('RIGHT CHILD'));
    await tester.flingFrom(rightFlingStart, const Offset(200.0, 0.0), 10000.0);
    await tester.pumpAndSettle();
    expect(value, 'LEFT');
  });

  testWidgets('Explicit TabController', (WidgetTester tester) async {
    final List<String> tabs = <String>['LEFT', 'RIGHT'];
    TabController tabController;

    Widget buildTabControllerFrame(BuildContext context, TabController controller) {
      tabController = controller;
      return new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: const Text('tabs'),
            bottom: new TabBar(
              controller: controller,
              tabs: tabs.map((String tab) => new Tab(text: tab)).toList(),
            ),
          ),
          body: new TabBarView(
            controller: controller,
            children: const <Widget>[
              const Center(child: const Text('LEFT CHILD')),
              const Center(child: const Text('RIGHT CHILD'))
            ]
          ),
        ),
      );
    }

    await tester.pumpWidget(new TabControllerFrame(
      builder: buildTabControllerFrame,
      length: tabs.length,
      initialIndex: 1,
    ));

    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsNothing);
    expect(find.text('RIGHT CHILD'), findsOneWidget);
    expect(tabController.index, 1);
    expect(tabController.previousIndex, 1);
    expect(tabController.indexIsChanging, false);
    expect(tabController.animation.value, 1.0);
    expect(tabController.animation.status, AnimationStatus.completed);

    tabController.index = 0;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    tabController.index = 1;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('LEFT CHILD'), findsNothing);
    expect(find.text('RIGHT CHILD'), findsOneWidget);
  });

  testWidgets('TabController listener resets index', (WidgetTester tester) async {
    // This is a regression test for the scenario brought up here
    // https://github.com/flutter/flutter/pull/7387#pullrequestreview-15630946

    final List<String> tabs = <String>['A', 'B', 'C'];
    TabController tabController;

    Widget buildTabControllerFrame(BuildContext context, TabController controller) {
      tabController = controller;
      return new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: const Text('tabs'),
            bottom: new TabBar(
              controller: controller,
              tabs: tabs.map((String tab) => new Tab(text: tab)).toList(),
            ),
          ),
          body: new TabBarView(
            controller: controller,
            children: const <Widget>[
              const Center(child: const Text('CHILD A')),
              const Center(child: const Text('CHILD B')),
              const Center(child: const Text('CHILD C')),
            ]
          ),
        ),
      );
    }

    await tester.pumpWidget(new TabControllerFrame(
      builder: buildTabControllerFrame,
      length: tabs.length,
    ));

    tabController.animation.addListener(() {
      if (tabController.animation.status == AnimationStatus.forward)
        tabController.index = 2;
      expect(tabController.indexIsChanging, true);
    });

    expect(tabController.index, 0);
    expect(tabController.indexIsChanging, false);

    tabController.animateTo(1, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tabController.index, 2);
    expect(tabController.indexIsChanging, false);
  });

  testWidgets('TabBarView child disposed during animation', (WidgetTester tester) async {
    // This is a regression test for the scenario brought up here
    // https://github.com/flutter/flutter/pull/7387#discussion_r95089191x

    final List<String> tabs = <String>['LEFT', 'RIGHT'];
    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));

    // Fling to the left, switch from the 'LEFT' tab to the 'RIGHT'
    final Offset flingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(flingStart, const Offset(-200.0, 0.0), 10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
  });

  testWidgets('TabBar unselectedLabelColor control test', (WidgetTester tester) async {
    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    Color firstColor;
    Color secondColor;

    await tester.pumpWidget(
      boilerplate(
        child: new TabBar(
          controller: controller,
          labelColor: Colors.green[500],
          unselectedLabelColor: Colors.blue[500],
          tabs: <Widget>[
            new Builder(
              builder: (BuildContext context) {
                firstColor = IconTheme.of(context).color;
                return const Text('First');
              }
            ),
            new Builder(
              builder: (BuildContext context) {
                secondColor = IconTheme.of(context).color;
                return const Text('Second');
              }
            ),
          ],
        ),
      ),
    );

    expect(firstColor, equals(Colors.green[500]));
    expect(secondColor, equals(Colors.blue[500]));
  });

  testWidgets('TabBarView page left and right test', (WidgetTester tester) async {
    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new TabBarView(
          controller: controller,
          children: const <Widget>[ const Text('First'), const Text('Second') ],
        ),
      ),
    );

    expect(controller.index, equals(0));

    TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    expect(controller.index, equals(0));

    // Drag to the left and right, by less than the TabBarView's width.
    // The selected index (controller.index) should not change.
    await gesture.moveBy(const Offset(-100.0, 0.0));
    await gesture.moveBy(const Offset(100.0, 0.0));
    expect(controller.index, equals(0));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);

    // Drag more than the TabBarView's width to the right. This forces
    // the selected index to change to 1.
    await gesture.moveBy(const Offset(-500.0, 0.0));
    await gesture.up();
    await tester.pump(); // start the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(controller.index, equals(1));
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    gesture = await tester.startGesture(const Offset(100.0, 100.0));
    expect(controller.index, equals(1));

    // Drag to the left and right, by less than the TabBarView's width.
    // The selected index (controller.index) should not change.
    await gesture.moveBy(const Offset(-100.0, 0.0));
    await gesture.moveBy(const Offset(100.0, 0.0));
    expect(controller.index, equals(1));
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    // Drag more than the TabBarView's width to the left. This forces
    // the selected index to change back to 0.
    await gesture.moveBy(const Offset(500.0, 0.0));
    await gesture.up();
    await tester.pump(); // start the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(controller.index, equals(0));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('TabBar tap animates the selection indicator', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/7479

    final List<String> tabs = <String>['A', 'B'];

    const Color indicatorColor = const Color(0xFFFF0000);
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'A', indicatorColor: indicatorColor));

    final RenderBox box = tester.renderObject(find.byType(TabBar));
    final TabIndicatorRecordingCanvas canvas = new TabIndicatorRecordingCanvas(indicatorColor);
    final TestRecordingPaintingContext context = new TestRecordingPaintingContext(canvas);

    box.paint(context, Offset.zero);
    final Rect indicatorRect0 = canvas.indicatorRect;
    expect(indicatorRect0.left, 0.0);
    expect(indicatorRect0.width, 400.0);
    expect(indicatorRect0.height, 2.0);

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    box.paint(context, Offset.zero);
    final Rect indicatorRect1 = canvas.indicatorRect;
    expect(indicatorRect1.left, greaterThan(indicatorRect0.left));
    expect(indicatorRect1.right, lessThan(800.0));
    expect(indicatorRect1.height, 2.0);

    await tester.pump(const Duration(milliseconds: 300));
    box.paint(context, Offset.zero);
    final Rect indicatorRect2 = canvas.indicatorRect;
    expect(indicatorRect2.left, 400.0);
    expect(indicatorRect2.width, 400.0);
    expect(indicatorRect2.height, 2.0);
  });

  testWidgets('TabBarView child disposed during animation', (WidgetTester tester) async {
    // This is a regression test for this patch:
    // https://github.com/flutter/flutter/pull/9015

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    Widget buildFrame() {
      return boilerplate(
        child: new TabBar(
          key: new UniqueKey(),
          controller: controller,
          tabs: const <Widget>[ const Text('A'), const Text('B') ],
        ),
      );
    }

    await tester.pumpWidget(buildFrame());

    // The original TabBar will be disposed. The controller should no
    // longer have any listeners from the original TabBar.
    await tester.pumpWidget(buildFrame());

    controller.index = 1;
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('TabBarView scrolls end very VERY close to a new page', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/9375

    final TabController tabController = new TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: 3,
    );

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new SizedBox.expand(
        child: new Center(
          child: new SizedBox(
            width: 400.0,
            height: 400.0,
            child: new TabBarView(
              controller: tabController,
              children: const <Widget>[
                const Center(child: const Text('0')),
                const Center(child: const Text('1')),
                const Center(child: const Text('2')),
              ],
            ),
          ),
        ),
      ),
    ));

    expect(tabController.index, 1);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    // The TabBarView's page width is 400, so page 0 is at scroll offset 0.0,
    // page 1 is at 400.0, page 2 is at 800.0.

    expect(position.pixels, 400.0);

    // Not close enough to switch to page 2
    pageController.jumpTo(800.0 - 1.25 * position.physics.tolerance.distance);
    expect(tabController.index, 1);

    // Close enough to switch to page 2
    pageController.jumpTo(800.0 - 0.75 * position.physics.tolerance.distance);
    expect(tabController.index, 2);
  });

  testWidgets('TabBarView scrolls end very close to a new page with custom physics', (WidgetTester tester) async {
    final TabController tabController = new TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: 3,
    );

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new SizedBox.expand(
        child: new Center(
          child: new SizedBox(
            width: 400.0,
            height: 400.0,
            child: new TabBarView(
              controller: tabController,
              physics: const TestScrollPhysics(),
              children: const <Widget>[
                const Center(child: const Text('0')),
                const Center(child: const Text('1')),
                const Center(child: const Text('2')),
              ],
            ),
          ),
        ),
      ),
    ));

    expect(tabController.index, 1);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    // The TabBarView's page width is 400, so page 0 is at scroll offset 0.0,
    // page 1 is at 400.0, page 2 is at 800.0.

    expect(position.pixels, 400.0);

    // Not close enough to switch to page 2
    pageController.jumpTo(800.0 - 1.25 * position.physics.tolerance.distance);
    expect(tabController.index, 1);

    // Close enough to switch to page 2
    pageController.jumpTo(800.0 - 0.75 * position.physics.tolerance.distance);
    expect(tabController.index, 2);
  });

  testWidgets('Scrollable TabBar with a non-zero TabController initialIndex', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/9374

    final List<Tab> tabs = new List<Tab>.generate(20, (int index) {
      return new Tab(text: 'TAB #$index');
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: tabs.length - 1,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new TabBar(
          isScrollable: true,
          controller: controller,
          tabs: tabs,
        ),
      ),
    );

    // The initialIndex tab should be visible and right justified
    expect(find.text('TAB #19'), findsOneWidget);

    // Tabs have a minimum width of 72.0 and 'TAB #19' is wider than
    // that. Tabs are padded horizontally with kTabLabelPadding.
    final double tabRight = 800.0 - kTabLabelPadding.right;

    expect(tester.getTopRight(find.widgetWithText(Tab, 'TAB #19')).dx, tabRight);
  });

  testWidgets('TabBar with indicatorWeight, indicatorPadding (LTR)', (WidgetTester tester) async {
    const Color indicatorColor = const Color(0xFF00FF00);
    const double indicatorWeight = 8.0;
    const double padLeft = 8.0;
    const double padRight = 4.0;

    final List<Widget> tabs = new List<Widget>.generate(4, (int index) {
      return new Tab(text: 'Tab $index');
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            indicatorWeight: indicatorWeight,
            indicatorColor: indicatorColor,
            indicatorPadding: const EdgeInsets.only(left: padLeft, right: padRight),
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox.size.height, 54.0); // 54 = _kTabHeight(46) + indicatorWeight(8.0)

    const double indicatorY = 54.0 - indicatorWeight / 2.0;
    double indicatorLeft = padLeft + indicatorWeight / 2.0;
    double indicatorRight = 200.0 - (padRight + indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));

    // Select tab 3
    controller.index = 3;
    await tester.pumpAndSettle();

    indicatorLeft = 600.0 + padLeft + indicatorWeight / 2.0;
    indicatorRight = 800.0 - (padRight + indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with indicatorWeight, indicatorPadding (RTL)', (WidgetTester tester) async {
    const Color indicatorColor = const Color(0xFF00FF00);
    const double indicatorWeight = 8.0;
    const double padLeft = 8.0;
    const double padRight = 4.0;

    final List<Widget> tabs = new List<Widget>.generate(4, (int index) {
      return new Tab(text: 'Tab $index');
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            indicatorWeight: indicatorWeight,
            indicatorColor: indicatorColor,
            indicatorPadding: const EdgeInsets.only(left: padLeft, right: padRight),
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox.size.height, 54.0); // 54 = _kTabHeight(46) + indicatorWeight(8.0)
    expect(tabBarBox.size.width, 800.0);

    const double indicatorY = 54.0 - indicatorWeight / 2.0;
    double indicatorLeft = 600.0 + padLeft + indicatorWeight / 2.0;
    double indicatorRight = 800.0 - padRight - indicatorWeight / 2.0;

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));

    // Select tab 3
    controller.index = 3;
    await tester.pumpAndSettle();

    indicatorLeft = padLeft + indicatorWeight / 2.0;
    indicatorRight = 200.0 - padRight -  indicatorWeight / 2.0;

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar changes indicator attributes', (WidgetTester tester) async {
    final List<Widget> tabs = new List<Widget>.generate(4, (int index) {
      return new Tab(text: 'Tab $index');
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    Color indicatorColor = const Color(0xFF00FF00);
    double indicatorWeight = 8.0;
    double padLeft = 8.0;
    double padRight = 4.0;

    Widget buildFrame() {
      return boilerplate(
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            indicatorWeight: indicatorWeight,
            indicatorColor: indicatorColor,
            indicatorPadding: new EdgeInsets.only(left: padLeft, right: padRight),
            controller: controller,
            tabs: tabs,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox.size.height, 54.0); // 54 = _kTabHeight(46) + indicatorWeight(8.0)

    double indicatorY = 54.0 - indicatorWeight / 2.0;
    double indicatorLeft = padLeft + indicatorWeight / 2.0;
    double indicatorRight = 200.0 - (padRight + indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));

    indicatorColor = const Color(0xFF0000FF);
    indicatorWeight = 4.0;
    padLeft = 4.0;
    padRight = 8.0;

    await tester.pumpWidget(buildFrame());

    expect(tabBarBox.size.height, 50.0); // 54 = _kTabHeight(46) + indicatorWeight(4.0)

    indicatorY = 50.0 - indicatorWeight / 2.0;
    indicatorLeft = padLeft + indicatorWeight / 2.0;
    indicatorRight = 200.0 - (padRight + indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with directional indicatorPadding (LTR)', (WidgetTester tester) async {
    final List<Widget> tabs = <Widget>[
      new SizedBox(key: new UniqueKey(), width: 130.0, height: 30.0),
      new SizedBox(key: new UniqueKey(), width: 140.0, height: 40.0),
      new SizedBox(key: new UniqueKey(), width: 150.0, height: 50.0),
    ];

    const double indicatorWeight = 2.0; // the default

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            indicatorPadding: const EdgeInsetsDirectional.only(start: 100.0),
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    const double tabBarHeight = 50.0 + indicatorWeight;  // 50 = max tab height
    expect(tabBarBox.size.height, tabBarHeight);

    // Tab0 width = 130, height = 30
    double tabLeft = kTabLabelPadding.left;
    double tabRight = tabLeft + 130.0;
    double tabTop = (tabBarHeight - indicatorWeight - 30.0) / 2.0;
    double tabBottom = tabTop + 30.0;
    Rect tabRect = new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key)), tabRect);


    // Tab1 width = 140, height = 40
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key)), tabRect);


    // Tab2 width = 150, height = 50
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 150.0;
    tabTop = (tabBarHeight - indicatorWeight - 50.0) / 2.0;
    tabBottom = tabTop + 50.0;
    tabRect = new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key)), tabRect);

    // Tab 0 selected, indicator padding resolves to left: 100.0
    const double indicatorLeft = 100.0 + indicatorWeight / 2.0;
    final double indicatorRight = 130.0 + kTabLabelPadding.horizontal - indicatorWeight / 2.0;
    final double indicatorY = tabBottom + indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with directional indicatorPadding (RTL)', (WidgetTester tester) async {
    final List<Widget> tabs = <Widget>[
      new SizedBox(key: new UniqueKey(), width: 130.0, height: 30.0),
      new SizedBox(key: new UniqueKey(), width: 140.0, height: 40.0),
      new SizedBox(key: new UniqueKey(), width: 150.0, height: 50.0),
    ];

    const double indicatorWeight = 2.0; // the default

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            indicatorPadding: const EdgeInsetsDirectional.only(start: 100.0),
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    const double tabBarHeight = 50.0 + indicatorWeight;  // 50 = max tab height
    expect(tabBarBox.size.height, tabBarHeight);

    // Tab2 width = 150, height = 50
    double tabLeft = kTabLabelPadding.left;
    double tabRight = tabLeft + 150.0;
    double tabTop = (tabBarHeight - indicatorWeight - 50.0) / 2.0;
    double tabBottom = tabTop + 50.0;
    Rect tabRect = new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key)), tabRect);

    // Tab1 width = 140, height = 40
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key)), tabRect);

    // Tab0 width = 130, height = 30
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 130.0;
    tabTop = (tabBarHeight - indicatorWeight - 30.0) / 2.0;
    tabBottom = tabTop + 30.0;
    tabRect = new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key)), tabRect);

    // Tab 0 selected, indicator padding resolves to right: 100.0
    final double indicatorLeft = tabLeft - kTabLabelPadding.left + indicatorWeight / 2.0;
    final double indicatorRight = tabRight + kTabLabelPadding.left - indicatorWeight / 2.0 - 100.0;
    const double indicatorY = 50.0 + indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('Overflowing RTL tab bar', (WidgetTester tester) async {
    final List<Widget> tabs = new List<Widget>.filled(100,
      // For convenience padded width of each tab will equal 100:
      // 76 + kTabLabelPadding.horizontal(24)
      new SizedBox(key: new UniqueKey(), width: 76.0, height: 40.0),
    );

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    const double indicatorWeight = 2.0; // the default

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    const double tabBarHeight = 40.0 + indicatorWeight;  // 40 = tab height
    expect(tabBarBox.size.height, tabBarHeight);

    // Tab 0 out of 100 selected
    double indicatorLeft = 99.0 * 100.0 + indicatorWeight / 2.0;
    double indicatorRight = 100.0 * 100.0 - indicatorWeight / 2.0;
    const double indicatorY = 40.0 + indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));

    controller.animateTo(tabs.length - 1, duration: const Duration(seconds: 1), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The x coordinates of p1 and p2 were derived empirically, not analytically.
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: const Offset(2476.0, indicatorY),
      p2: const Offset(2574.0, indicatorY),
    ));

    await tester.pump(const Duration(milliseconds: 501));

    // Tab 99 out of 100 selected, appears on the far left because RTL
    indicatorLeft = indicatorWeight / 2.0;
    indicatorRight = 100.0 - indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Tab> tabs = new List<Tab>.generate(2, (int index) {
      return new Tab(text: 'TAB #$index');
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Semantics(
          container: true,
          child: new TabBar(
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                new TestSemantics(
                  id: 3,
                  actions: SemanticsAction.tap.index,
                  flags: SemanticsFlag.isSelected.index,
                  label: 'TAB #0\nTab 1 of 2',
                  rect: new Rect.fromLTRB(0.0, 0.0, 108.0, kTextTabBarHeight),
                  transform: new Matrix4.translationValues(0.0, 276.0, 0.0),
                ),
                new TestSemantics(
                  id: 4,
                  actions: SemanticsAction.tap.index,
                  label: 'TAB #1\nTab 2 of 2',
                  rect: new Rect.fromLTRB(0.0, 0.0, 108.0, kTextTabBarHeight),
                  transform: new Matrix4.translationValues(108.0, 276.0, 0.0),
                ),
              ]
            )
          ],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('correct scrolling semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Tab> tabs = new List<Tab>.generate(20, (int index) {
      return new Tab(text: 'This is a very wide tab #$index');
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Semantics(
          container: true,
          child: new TabBar(
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    const String tab0title = 'This is a very wide tab #0\nTab 1 of 20';
    const String tab10title = 'This is a very wide tab #10\nTab 11 of 20';

    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollLeft]));
    expect(semantics, includesNodeWith(label: tab0title));
    expect(semantics, isNot(includesNodeWith(label: tab10title)));

    controller.index = 10;
    await tester.pumpAndSettle();

    expect(semantics, isNot(includesNodeWith(label: tab0title)));
    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollLeft, SemanticsAction.scrollRight]));
    expect(semantics, includesNodeWith(label: tab10title));

    controller.index = 19;
    await tester.pumpAndSettle();

    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollRight]));

    controller.index = 0;
    await tester.pumpAndSettle();

    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollLeft]));
    expect(semantics, includesNodeWith(label: tab0title));
    expect(semantics, isNot(includesNodeWith(label: tab10title)));

    semantics.dispose();
  });

  testWidgets('TabBar etc with zero tabs', (WidgetTester tester) async {
    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Column(
          children: <Widget>[
            new TabBar(
              controller: controller,
              tabs: const <Widget>[],
            ),
            new Flexible(
              child: new TabBarView(
                controller: controller,
                children: const <Widget>[],
              ),
            ),
          ],
        ),
      ),
    );

    expect(controller.index, 0);
    expect(tester.getSize(find.byType(TabBar)), const Size(800.0, 48.0));
    expect(tester.getSize(find.byType(TabBarView)), const Size(800.0, 600.0 - 48.0));

    // A fling in the TabBar or TabBarView, shouldn't do anything.

    await tester.fling(find.byType(TabBar), const Offset(-100.0, 0.0), 5000.0);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBarView), const Offset(100.0, 0.0), 5000.0);
    await tester.pumpAndSettle();

    expect(controller.index, 0);
  });

  testWidgets('TabBar etc with one tab', (WidgetTester tester) async {
    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: 1,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Column(
          children: <Widget>[
            new TabBar(
              controller: controller,
              tabs: const <Widget>[const Tab(text: 'TAB')],
            ),
            new Flexible(
              child: new TabBarView(
                controller: controller,
                children: const <Widget>[const Text('PAGE')],
              ),
            ),
          ],
        ),
      ),
    );

    expect(controller.index, 0);
    expect(find.text('TAB'), findsOneWidget);
    expect(find.text('PAGE'), findsOneWidget);
    expect(tester.getSize(find.byType(TabBar)), const Size(800.0, 48.0));
    expect(tester.getSize(find.byType(TabBarView)), const Size(800.0, 600.0 - 48.0));

    // The one tab should be center vis the app's width (800).
    final double tabLeft = tester.getTopLeft(find.widgetWithText(Tab, 'TAB')).dx;
    final double tabRight = tester.getTopRight(find.widgetWithText(Tab, 'TAB')).dx;
    expect(tabLeft + (tabRight - tabLeft) / 2.0, 400.0);

    // A fling in the TabBar or TabBarView, shouldn't move the tab.

    await tester.fling(find.byType(TabBar), const Offset(-100.0, 0.0), 5000.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.widgetWithText(Tab, 'TAB')).dx, tabLeft);
    expect(tester.getTopRight(find.widgetWithText(Tab, 'TAB')).dx, tabRight);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBarView), const Offset(100.0, 0.0), 5000.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.widgetWithText(Tab, 'TAB')).dx, tabLeft);
    expect(tester.getTopRight(find.widgetWithText(Tab, 'TAB')).dx, tabRight);
    await tester.pumpAndSettle();

    expect(controller.index, 0);
    expect(find.text('TAB'), findsOneWidget);
    expect(find.text('PAGE'), findsOneWidget);
  });

  testWidgets('can tap on indicator at very bottom of TabBar to switch tabs', (WidgetTester tester) async {
    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: 2,
      initialIndex: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Column(
          children: <Widget>[
            new TabBar(
              controller: controller,
              indicatorWeight: 30.0,
              tabs: const <Widget>[const Tab(text: 'TAB1'), const Tab(text: 'TAB2')],
            ),
            new Flexible(
              child: new TabBarView(
                controller: controller,
                children: const <Widget>[const Text('PAGE1'), const Text('PAGE2')],
              ),
            ),
          ],
        ),
      ),
    );

    expect(controller.index, 0);

    final Offset bottomRight = tester.getBottomRight(find.byType(TabBar)) - const Offset(1.0, 1.0);
    final TestGesture gesture = await tester.startGesture(bottomRight);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.index, 1);
  });

  testWidgets('can override semantics of tabs', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Tab> tabs = new List<Tab>.generate(2, (int index) {
      return new Tab(
        child: new Semantics(
          label: 'Semantics override $index',
          child: new ExcludeSemantics(
            child: new Text('TAB #$index'),
          ),
        ),
      );
    });

    final TabController controller = new TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: new Semantics(
          container: true,
          child: new TabBar(
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                new TestSemantics(
                  id: 3,
                  actions: SemanticsAction.tap.index,
                  flags: SemanticsFlag.isSelected.index,
                  label: 'Semantics override 0\nTab 1 of 2',
                  rect: new Rect.fromLTRB(0.0, 0.0, 108.0, kTextTabBarHeight),
                  transform: new Matrix4.translationValues(0.0, 276.0, 0.0),
                ),
                new TestSemantics(
                  id: 4,
                  actions: SemanticsAction.tap.index,
                  label: 'Semantics override 1\nTab 2 of 2',
                  rect: new Rect.fromLTRB(0.0, 0.0, 108.0, kTextTabBarHeight),
                  transform: new Matrix4.translationValues(108.0, 276.0, 0.0),
                ),
              ]
            )
          ],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  test('illegal constructor combinations', () {
    expect(() => new Tab(icon: nonconst(null)), throwsAssertionError);
    expect(() => new Tab(icon: new Container(), text: 'foo', child: new Container()), throwsAssertionError);
    expect(() => new Tab(text: 'foo', child: new Container()), throwsAssertionError);
  });


  testWidgets('TabController changes', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/14812

    Widget buildFrame(TabController controller) {
      return boilerplate(
        child: new Container(
          alignment: Alignment.topLeft,
          child: new TabBar(
            controller: controller,
            tabs: const <Tab>[
              const Tab(text: 'LEFT'),
              const Tab(text: 'RIGHT'),
            ],
          ),
        ),
      );
    }

    final TabController controller1 = new TabController(
      vsync: const TestVSync(),
      length: 2,
      initialIndex: 0,
    );

    final TabController controller2 = new TabController(
      vsync: const TestVSync(),
      length: 2,
      initialIndex: 0,
    );

    await tester.pumpWidget(buildFrame(controller1));
    await tester.pumpWidget(buildFrame(controller2));
    expect(controller1.index, 0);
    expect(controller2.index, 0);

    const double indicatorWeight = 2.0;
    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox.size.height, 48.0); // 48 = _kTabHeight(46) + indicatorWeight(2.0)

    const double indicatorY = 48.0 - indicatorWeight / 2.0;
    double indicatorLeft = indicatorWeight / 2.0;
    double indicatorRight = 400.0 - indicatorWeight / 2.0; // 400 = screen_width / 2
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));

    await tester.tap(find.text('RIGHT'));
    await tester.pumpAndSettle();
    expect(controller1.index, 0);
    expect(controller2.index, 1);

    // Verify that the TabBar's _IndicatorPainter is now listening to
    // tabController2.

    indicatorLeft = 400.0 + indicatorWeight / 2.0;
    indicatorRight = 800.0 - indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: new Offset(indicatorLeft, indicatorY),
      p2: new Offset(indicatorRight, indicatorY),
    ));
  });

}
