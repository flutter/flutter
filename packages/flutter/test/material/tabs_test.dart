// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

Widget boilerplate({ Widget? child, TextDirection textDirection = TextDirection.ltr }) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Directionality(
      textDirection: textDirection,
      child: Material(
        child: child,
      ),
    ),
  );
}

class StateMarker extends StatefulWidget {
  const StateMarker({ Key? key, this.child }) : super(key: key);

  final Widget? child;

  @override
  StateMarkerState createState() => StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String? marker;

  @override
  Widget build(BuildContext context) {
    if (widget.child != null)
      return widget.child!;
    return Container();
  }
}

class AlwaysKeepAliveWidget extends StatefulWidget {
  const AlwaysKeepAliveWidget({ Key? key}) : super(key: key);
  static String text = 'AlwaysKeepAlive';
  @override
  AlwaysKeepAliveState createState() => AlwaysKeepAliveState();
}

class AlwaysKeepAliveState extends State<AlwaysKeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(AlwaysKeepAliveWidget.text);
  }
}

class _NestedTabBarContainer extends StatelessWidget {
  const _NestedTabBarContainer({
    this.tabController,
  });

  final TabController? tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Column(
        children: <Widget>[
          TabBar(
            controller: tabController,
            tabs: const <Tab>[
              Tab(text: 'Yellow'),
              Tab(text: 'Grey'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: <Widget>[
                Container(color: Colors.yellow),
                Container(color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildFrame({
  Key? tabBarKey,
  required List<String> tabs,
  required String value,
  bool isScrollable = false,
  Color? indicatorColor,
  Duration? animationDuration,
}) {
  return boilerplate(
    child: DefaultTabController(
      animationDuration: animationDuration,
      initialIndex: tabs.indexOf(value),
      length: tabs.length,
      child: TabBar(
        key: tabBarKey,
        tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
        isScrollable: isScrollable,
        indicatorColor: indicatorColor,
      ),
    ),
  );
}

typedef TabControllerFrameBuilder = Widget Function(BuildContext context, TabController controller);

class TabControllerFrame extends StatefulWidget {
  const TabControllerFrame({
    Key? key,
    required this.length,
    this.initialIndex = 0,
    required this.builder,
  }) : super(key: key);

  final int length;
  final int initialIndex;
  final TabControllerFrameBuilder builder;

  @override
  TabControllerFrameState createState() => TabControllerFrameState();
}

class TabControllerFrameState extends State<TabControllerFrame> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
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

Widget buildLeftRightApp({required List<String> tabs, required String value, bool automaticIndicatorColorAdjustment = true}) {
  return MaterialApp(
    theme: ThemeData(platform: TargetPlatform.android),
    home: DefaultTabController(
      initialIndex: tabs.indexOf(value),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('tabs'),
          bottom: TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            automaticIndicatorColorAdjustment: automaticIndicatorColorAdjustment,
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            Center(child: Text('LEFT CHILD')),
            Center(child: Text('RIGHT CHILD')),
          ],
        ),
      ),
    ),
  );
}

class TabIndicatorRecordingCanvas extends TestRecordingCanvas {
  TabIndicatorRecordingCanvas(this.indicatorColor);

  final Color indicatorColor;
  late Rect indicatorRect;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    // Assuming that the indicatorWeight is 2.0, the default.
    const double indicatorWeight = 2.0;
    if (paint.color == indicatorColor)
      indicatorRect = Rect.fromPoints(p1, p2).inflate(indicatorWeight / 2.0);
  }
}

class TestScrollPhysics extends ScrollPhysics {
  const TestScrollPhysics({ ScrollPhysics? parent }) : super(parent: parent);

  @override
  TestScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TestScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset == 10 ? 20 : offset;
  }

  static final SpringDescription _kDefaultSpring = SpringDescription.withDampingRatio(
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

  testWidgets('Tab sizing - icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: Material(child: Tab(icon: SizedBox(width: 10.0, height: 10.0))))),
    );
    expect(tester.getSize(find.byType(Tab)), const Size(10.0, 46.0));
  });

  testWidgets('Tab sizing - child', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: Material(child: Tab(child: SizedBox(width: 10.0, height: 10.0))))),
    );
    expect(tester.getSize(find.byType(Tab)), const Size(10.0, 46.0));
  });

  testWidgets('Tab sizing - text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData(fontFamily: 'Ahem'), home: const Center(child: Material(child: Tab(text: 'x')))),
    );
    expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).text.style!.fontFamily, 'Ahem');
    expect(tester.getSize(find.byType(Tab)), const Size(14.0, 46.0));
  });

  testWidgets('Tab sizing - icon and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData(fontFamily: 'Ahem'), home: const Center(child: Material(child: Tab(icon: SizedBox(width: 10.0, height: 10.0), text: 'x')))),
    );
    expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).text.style!.fontFamily, 'Ahem');
    expect(tester.getSize(find.byType(Tab)), const Size(14.0, 72.0));
  });

  testWidgets('Tab sizing - icon, iconMargin and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Ahem'),
        home: const Center(
          child: Material(
            child: Tab(
              icon: SizedBox(
                width: 10.0,
                height: 10.0,
              ),
              iconMargin: EdgeInsets.symmetric(
                horizontal: 100.0,
              ),
              text: 'x',
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).text.style!.fontFamily, 'Ahem');
    expect(tester.getSize(find.byType(Tab)), const Size(210.0, 72.0));
  });

  testWidgets('Tab sizing - icon and child', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData(fontFamily: 'Ahem'), home: const Center(child: Material(child: Tab(icon: SizedBox(width: 10.0, height: 10.0), child: Text('x'))))),
    );
    expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).text.style!.fontFamily, 'Ahem');
    expect(tester.getSize(find.byType(Tab)), const Size(14.0, 72.0));
  });

  testWidgets('Tab color - normal', (WidgetTester tester) async {
    final Widget tabBar = TabBar(tabs: const <Widget>[SizedBox.shrink()], controller: TabController(length: 1, vsync: tester));
    await tester.pumpWidget(
      MaterialApp(home: Material(child: tabBar)),
    );
    expect(find.byType(TabBar), paints..line(color: Colors.blue[500]));
  });

  testWidgets('Tab color - match', (WidgetTester tester) async {
    final Widget tabBar = TabBar(tabs: const <Widget>[SizedBox.shrink()], controller: TabController(length: 1, vsync: tester));
    await tester.pumpWidget(
      MaterialApp(home: Material(color: const Color(0xff2196f3), child: tabBar)),
    );
    expect(find.byType(TabBar), paints..line(color: Colors.white));
  });

  testWidgets('Tab color - transparency', (WidgetTester tester) async {
    final Widget tabBar = TabBar(tabs: const <Widget>[SizedBox.shrink()], controller: TabController(length: 1, vsync: tester));
    await tester.pumpWidget(
      MaterialApp(home: Material(type: MaterialType.transparency, child: tabBar)),
    );
    expect(find.byType(TabBar), paints..line(color: Colors.blue[500]));
  });

  testWidgets('TabBar tap selects tab', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C'));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    final TabController controller = DefaultTabController.of(tester.element(find.text('A')))!;
    expect(controller, isNotNull);
    expect(controller.index, 2);
    expect(controller.previousIndex, 2);

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C'));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(controller.indexIsChanging, true);
    await tester.pump(const Duration(seconds: 1)); // finish the animation
    expect(controller.index, 1);
    expect(controller.previousIndex, 2);
    expect(controller.indexIsChanging, false);

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C'));
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.index, 2);
    expect(controller.previousIndex, 1);

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C'));
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
    final TabController controller = DefaultTabController.of(tester.element(find.text('A')))!;
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
    const Key tabBarKey = Key('TabBar');
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAAAA', isScrollable: true, tabBarKey: tabBarKey));
    final TabController controller = DefaultTabController.of(tester.element(find.text('AAAAAA')))!;
    expect(controller, isNotNull);
    expect(controller.index, 0);

    expect(tester.getSize(find.byKey(tabBarKey)).width, equals(800.0));
    // The center of the FFFFFF item is to the right of the TabBar's center
    expect(tester.getCenter(find.text('FFFFFF')).dx, greaterThan(401.0));

    await tester.tap(find.text('FFFFFF'));
    await tester.pumpAndSettle();
    expect(controller.index, 5);
    // The center of the FFFFFF item is now at the TabBar's center
    expect(tester.getCenter(find.text('FFFFFF')).dx, moreOrLessEquals(400.0, epsilon: 1.0));
  });


  testWidgets('TabBar can be scrolled independent of the selection', (WidgetTester tester) async {
    final List<String> tabs = <String>['AAAA', 'BBBB', 'CCCC', 'DDDD', 'EEEE', 'FFFF', 'GGGG', 'HHHH', 'IIII', 'JJJJ', 'KKKK', 'LLLL'];
    const Key tabBarKey = Key('TabBar');
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAA', isScrollable: true, tabBarKey: tabBarKey));
    final TabController controller = DefaultTabController.of(tester.element(find.text('AAAA')))!;
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
        child: DefaultTabController(
          initialIndex: tabs.indexOf(value),
          length: tabs.length,
          child: TabBarView(
            children: tabs.map<Widget>((String name) {
              return StateMarker(
                child: Text(name),
              );
            }).toList(),
          ),
        ),
      );
    }

    StateMarkerState findStateMarkerState(String name) {
      return tester.state(find.widgetWithText(StateMarker, name, skipOffstage: false));
    }

    await tester.pumpWidget(builder());
    final TabController controller = DefaultTabController.of(tester.element(find.text('AAAAAA')))!;

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

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')))!;
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

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')))!;
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

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')))!;
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

    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')))!;
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

  // A regression test for https://github.com/flutter/flutter/pull/88878.
  testWidgets('TabController notifies the index to change when left flinging', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];
    late TabController tabController;

    Widget buildTabControllerFrame(BuildContext context, TabController controller) {
      tabController = controller;
      return MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('tabs'),
            bottom: TabBar(
              controller: controller,
              tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            ),
          ),
          body: TabBarView(
            controller: controller,
            children: const <Widget>[
              Center(child: Text('CHILD A')),
              Center(child: Text('CHILD B')),
              Center(child: Text('CHILD C')),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(TabControllerFrame(
      builder: buildTabControllerFrame,
      length: tabs.length,
      initialIndex: tabs.indexOf('C'),
    ));
    expect(tabController.index, tabs.indexOf('C'));

    tabController.addListener(() {
      final int indexOfB = tabs.indexOf('B');
      expect(tabController.index, indexOfB);
    });
    final Offset flingStart = tester.getCenter(find.text('CHILD C'));
    await tester.flingFrom(flingStart, const Offset(600, 0.0), 10000.0);
    await tester.pumpAndSettle();
  });

  // A regression test for https://github.com/flutter/flutter/issues/7133
  testWidgets('TabBar fling velocity', (WidgetTester tester) async {
    final List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300.0,
            height: 200.0,
            child: DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('tabs'),
                  bottom: TabBar(
                    isScrollable: true,
                    tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
                  ),
                ),
                body: TabBarView(
                  children: tabs.map<Widget>((String name) => Text('${index++}')).toList(),
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
    final TabController controller = DefaultTabController.of(tester.element(find.text('LEFT')))!;

    expect(controller, isNotNull);
    expect(controller.index, 0);

    late String value;
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
    late TabController tabController;

    Widget buildTabControllerFrame(BuildContext context, TabController controller) {
      tabController = controller;
      return MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('tabs'),
            bottom: TabBar(
              controller: controller,
              tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            ),
          ),
          body: TabBarView(
            controller: controller,
            children: const <Widget>[
              Center(child: Text('LEFT CHILD')),
              Center(child: Text('RIGHT CHILD')),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(TabControllerFrame(
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
    expect(tabController.animation!.value, 1.0);
    expect(tabController.animation!.status, AnimationStatus.forward);

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
    late TabController tabController;

    Widget buildTabControllerFrame(BuildContext context, TabController controller) {
      tabController = controller;
      return MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('tabs'),
            bottom: TabBar(
              controller: controller,
              tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            ),
          ),
          body: TabBarView(
            controller: controller,
            children: const <Widget>[
              Center(child: Text('CHILD A')),
              Center(child: Text('CHILD B')),
              Center(child: Text('CHILD C')),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(TabControllerFrame(
      builder: buildTabControllerFrame,
      length: tabs.length,
    ));

    tabController.animation!.addListener(() {
      if (tabController.animation!.status == AnimationStatus.forward)
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
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    late Color firstColor;
    late Color secondColor;

    await tester.pumpWidget(
      boilerplate(
        child: TabBar(
          controller: controller,
          labelColor: Colors.green[500],
          unselectedLabelColor: Colors.blue[500],
          tabs: <Widget>[
            Builder(
              builder: (BuildContext context) {
                firstColor = IconTheme.of(context).color!;
                return const Text('First');
              },
            ),
            Builder(
              builder: (BuildContext context) {
                secondColor = IconTheme.of(context).color!;
                return const Text('Second');
              },
            ),
          ],
        ),
      ),
    );

    expect(firstColor, equals(Colors.green[500]));
    expect(secondColor, equals(Colors.blue[500]));
  });

  testWidgets('TabBarView page left and right test', (WidgetTester tester) async {
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    await tester.pumpWidget(
      boilerplate(
        child: TabBarView(
          controller: controller,
          children: const <Widget>[ Text('First'), Text('Second') ],
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

  testWidgets('TabBar animationDuration sets indicator animation duration', (WidgetTester tester) async {
    const Duration animationDuration = Duration(milliseconds: 100);
    final List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'B', animationDuration: animationDuration));
    final TabController controller = DefaultTabController.of(tester.element(find.text('A')))!;

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(controller.indexIsChanging, true);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(animationDuration);
    expect(controller.index, 0);
    expect(controller.previousIndex, 1);
    expect(controller.indexIsChanging, false);

    //Test when index diff is greater than 1
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'B', animationDuration: animationDuration));
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(controller.indexIsChanging, true);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(animationDuration);
    expect(controller.index, 2);
    expect(controller.previousIndex, 0);
    expect(controller.indexIsChanging, false);
  });

  testWidgets('TabBarView controller sets animation duration', (WidgetTester tester) async {
    const Duration animationDuration = Duration(milliseconds: 100);
    final List<String> tabs = <String>['A', 'B', 'C'];

    final TabController tabController = TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: tabs.length,
      animationDuration: animationDuration,
    );
    await tester.pumpWidget(boilerplate(
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            controller: tabController,
          ),
          SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
              ],
            ),
          ),
        ],
      ),
    ));

    expect(tabController.index, 1);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    // The TabBarView's page width is 400, so page 0 is at scroll offset 0.0,
    // page 1 is at 400.0, page 2 is at 800.0.
    expect(position.pixels, 400);
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(position.pixels, 400);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(animationDuration);
    expect(position.pixels, 800);
  });

  testWidgets('TabBarView viewportFraction sets PageView viewport fraction', (WidgetTester tester) async {
    const Duration animationDuration = Duration(milliseconds: 100);
    final List<String> tabs = <String>['A', 'B', 'C'];

    final TabController tabController = TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: tabs.length,
      animationDuration: animationDuration,
    );
    await tester.pumpWidget(boilerplate(
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            controller: tabController,
          ),
          SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              viewportFraction: 0.8,
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
              ],
            ),
          ),
        ],
      ),
    ));

    expect(tabController.index, 1);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;

    // The TabView was initialized with viewportFraction as 0.8
    // So it's expected the PageView inside would obtain the same viewportFraction
    expect(pageController.viewportFraction, 0.8);
  });

  testWidgets('TabBarView viewportFraction is 1 by default', (WidgetTester tester) async {
    const Duration animationDuration = Duration(milliseconds: 100);
    final List<String> tabs = <String>['A', 'B', 'C'];

    final TabController tabController = TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: tabs.length,
      animationDuration: animationDuration,
    );
    await tester.pumpWidget(boilerplate(
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            controller: tabController,
          ),
          SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
              ],
            ),
          ),
        ],
      ),
    ));

    expect(tabController.index, 1);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;

    // The TabView was initialized with default viewportFraction
    // So it's expected the PageView inside would obtain the value 1
    expect(pageController.viewportFraction, 1);
  });

  testWidgets('TabBar tap skips indicator animation when disabled in controller', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B'];

    const Color indicatorColor = Color(0xFFFF0000);
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'A', indicatorColor: indicatorColor, animationDuration: Duration.zero));

    final RenderBox box = tester.renderObject(find.byType(TabBar));
    final TabIndicatorRecordingCanvas canvas = TabIndicatorRecordingCanvas(indicatorColor);
    final TestRecordingPaintingContext context = TestRecordingPaintingContext(canvas);

    box.paint(context, Offset.zero);
    final Rect indicatorRect0 = canvas.indicatorRect;
    expect(indicatorRect0.left, 0.0);
    expect(indicatorRect0.width, 400.0);
    expect(indicatorRect0.height, 2.0);

    await tester.tap(find.text('B'));
    await tester.pump();
    box.paint(context, Offset.zero);
    final Rect indicatorRect2 = canvas.indicatorRect;
    expect(indicatorRect2.left, 400.0);
    expect(indicatorRect2.width, 400.0);
    expect(indicatorRect2.height, 2.0);
  });

  testWidgets('TabBar tap changes index instantly when animation is disabled in controller', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'B', animationDuration: Duration.zero));
    final TabController controller = DefaultTabController.of(tester.element(find.text('A')))!;

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(controller.index, 0);
    expect(controller.previousIndex, 1);
    expect(controller.indexIsChanging, false);

    //Test when index diff is greater than 1
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'B', animationDuration: Duration.zero));
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(controller.index, 2);
    expect(controller.previousIndex, 0);
    expect(controller.indexIsChanging, false);
  });

  testWidgets('TabBarView skips animation when disabled in controller', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];
    final TabController tabController = TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: tabs.length,
      animationDuration: Duration.zero,
    );
    await tester.pumpWidget(boilerplate(
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            controller: tabController,
          ),
          SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
              ],
            ),
          ),
        ],
      ),
    ));

    expect(tabController.index, 1);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    // The TabBarView's page width is 400, so page 0 is at scroll offset 0.0,
    // page 1 is at 400.0, page 2 is at 800.0.
    expect(position.pixels, 400);
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(position.pixels, 800);
  });

  testWidgets('TabBarView skips animation when disabled in controller - skip tabs', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B', 'C'];
    final TabController tabController = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      animationDuration: Duration.zero,
    );
    await tester.pumpWidget(boilerplate(
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            controller: tabController,
          ),
          SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
              ],
            ),
          ),
        ],
      ),
    ));

    expect(tabController.index, 0);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    // The TabBarView's page width is 400, so page 0 is at scroll offset 0.0,
    // page 1 is at 400.0, page 2 is at 800.0.
    expect(position.pixels, 0);
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(position.pixels, 800);
  });

  testWidgets('TabBarView skips animation when disabled in controller - two tabs', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B'];
    final TabController tabController = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      animationDuration: Duration.zero,
    );
    await tester.pumpWidget(boilerplate(
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            controller: tabController,
          ),
          SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
              ],
            ),
          ),
        ],
      ),
    ));

    expect(tabController.index, 0);

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    // The TabBarView's page width is 400, so page 0 is at scroll offset 0.0,
    // page 1 is at 400.0, page 2 is at 800.0.
    expect(position.pixels, 0);
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(position.pixels, 400);
  });

  testWidgets('TabBar tap animates the selection indicator', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/7479

    final List<String> tabs = <String>['A', 'B'];

    const Color indicatorColor = Color(0xFFFF0000);
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'A', indicatorColor: indicatorColor));

    final RenderBox box = tester.renderObject(find.byType(TabBar));
    final TabIndicatorRecordingCanvas canvas = TabIndicatorRecordingCanvas(indicatorColor);
    final TestRecordingPaintingContext context = TestRecordingPaintingContext(canvas);

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

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    Widget buildFrame() {
      return boilerplate(
        child: TabBar(
          key: UniqueKey(),
          controller: controller,
          tabs: const <Widget>[ Text('A'), Text('B') ],
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

  testWidgets('TabBarView scrolls end close to a new page', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/9375

    final TabController tabController = TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: 3,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(
        child: Center(
          child: SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
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
    pageController.jumpTo(500.0);
    expect(tabController.index, 1);

    // Close enough to switch to page 2
    pageController.jumpTo(700.0);
    expect(tabController.index, 2);

    // Same behavior going left: not left enough to get to page 0
    pageController.jumpTo(300.0);
    expect(tabController.index, 1);

    // Left enough to get to page 0
    pageController.jumpTo(100.0);
    expect(tabController.index, 0);
  });

  testWidgets('Can switch to non-neighboring tab in nested TabBarView without crashing', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/18756
    final TabController mainTabController = TabController(length: 4, vsync: const TestVSync());
    final TabController nestedTabController = TabController(length: 2, vsync: const TestVSync());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Exception for Nested Tabs'),
            bottom: TabBar(
              controller: mainTabController,
              tabs: const <Widget>[
                Tab(icon: Icon(Icons.add), text: 'A'),
                Tab(icon: Icon(Icons.add), text: 'B'),
                Tab(icon: Icon(Icons.add), text: 'C'),
                Tab(icon: Icon(Icons.add), text: 'D'),
              ],
            ),
          ),
          body: TabBarView(
            controller: mainTabController,
            children: <Widget>[
              Container(color: Colors.red),
              _NestedTabBarContainer(tabController: nestedTabController),
              Container(color: Colors.green),
              Container(color: Colors.indigo),
            ],
          ),
        ),
      ),
    );

    // expect first tab to be selected
    expect(mainTabController.index, 0);

    // tap on third tab
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();

    // expect third tab to be selected without exceptions
    expect(mainTabController.index, 2);
  });

  testWidgets('TabBarView can warp when child is kept alive and contains ink', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/57662.
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 3,
    );

    await tester.pumpWidget(
      boilerplate(
        child: TabBarView(
          controller: controller,
          children: const <Widget>[
            Text('Page 1'),
            Text('Page 2'),
            KeepAliveInk('Page 3'),
          ],
        ),
      ),
    );

    expect(controller.index, equals(0));
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    controller.index = 2;
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);

    controller.index = 0;
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('TabBarView scrolls end close to a new page with custom physics', (WidgetTester tester) async {
    final TabController tabController = TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: 3,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(
        child: Center(
          child: SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              physics: const TestScrollPhysics(),
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
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
    pageController.jumpTo(500.0);
    expect(tabController.index, 1);

    // Close enough to switch to page 2
    pageController.jumpTo(700.0);
    expect(tabController.index, 2);

    // Same behavior going left: not left enough to get to page 0
    pageController.jumpTo(300.0);
    expect(tabController.index, 1);

    // Left enough to get to page 0
    pageController.jumpTo(100.0);
    expect(tabController.index, 0);
  });

  testWidgets('TabBar accepts custom physics', (WidgetTester tester) async {
    final List<Tab> tabs = List<Tab>.generate(20, (int index) {
      return Tab(text: 'TAB #$index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: tabs.length - 1,
    );

    await tester.pumpWidget(
      boilerplate(
        child: TabBar(
          isScrollable: true,
          controller: controller,
          tabs: tabs,
          physics: const TestScrollPhysics(),
        ),
      ),
    );

    final TabBar tabBar = tester.widget(find.byType(TabBar));
    final double position = tabBar.physics!.applyPhysicsToUserOffset(MockScrollMetrics(), 10);

    expect(position, equals(20));
  });

  testWidgets('Scrollable TabBar with a non-zero TabController initialIndex', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/9374

    final List<Tab> tabs = List<Tab>.generate(20, (int index) {
      return Tab(text: 'TAB #$index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: tabs.length - 1,
    );

    await tester.pumpWidget(
      boilerplate(
        child: TabBar(
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
    const Color indicatorColor = Color(0xFF00FF00);
    const double indicatorWeight = 8.0;
    const double padLeft = 8.0;
    const double padRight = 4.0;

    final List<Widget> tabs = List<Widget>.generate(4, (int index) {
      return Tab(text: 'Tab $index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));

    // Select tab 3
    controller.index = 3;
    await tester.pumpAndSettle();

    indicatorLeft = 600.0 + padLeft + indicatorWeight / 2.0;
    indicatorRight = 800.0 - (padRight + indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with indicatorWeight, indicatorPadding (RTL)', (WidgetTester tester) async {
    const Color indicatorColor = Color(0xFF00FF00);
    const double indicatorWeight = 8.0;
    const double padLeft = 8.0;
    const double padRight = 4.0;

    final List<Widget> tabs = List<Widget>.generate(4, (int index) {
      return Tab(text: 'Tab $index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));

    // Select tab 3
    controller.index = 3;
    await tester.pumpAndSettle();

    indicatorLeft = padLeft + indicatorWeight / 2.0;
    indicatorRight = 200.0 - padRight -  indicatorWeight / 2.0;

    expect(tabBarBox, paints..line(
      color: indicatorColor,
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar changes indicator attributes', (WidgetTester tester) async {
    final List<Widget> tabs = List<Widget>.generate(4, (int index) {
      return Tab(text: 'Tab $index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    Color indicatorColor = const Color(0xFF00FF00);
    double indicatorWeight = 8.0;
    double padLeft = 8.0;
    double padRight = 4.0;

    Widget buildFrame() {
      return boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            indicatorWeight: indicatorWeight,
            indicatorColor: indicatorColor,
            indicatorPadding: EdgeInsets.only(left: padLeft, right: padRight),
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with directional indicatorPadding (LTR)', (WidgetTester tester) async {
    final List<Widget> tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: 130.0, height: 30.0),
      SizedBox(key: UniqueKey(), width: 140.0, height: 40.0),
      SizedBox(key: UniqueKey(), width: 150.0, height: 50.0),
    ];

    const double indicatorWeight = 2.0; // the default

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
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
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);


    // Tab1 width = 140, height = 40
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);


    // Tab2 width = 150, height = 50
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 150.0;
    tabTop = (tabBarHeight - indicatorWeight - 50.0) / 2.0;
    tabBottom = tabTop + 50.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key!)), tabRect);

    // Tab 0 selected, indicator padding resolves to left: 100.0
    const double indicatorLeft = 100.0 + indicatorWeight / 2.0;
    final double indicatorRight = 130.0 + kTabLabelPadding.horizontal - indicatorWeight / 2.0;
    final double indicatorY = tabBottom + indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with directional indicatorPadding (RTL)', (WidgetTester tester) async {
    final List<Widget> tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: 130.0, height: 30.0),
      SizedBox(key: UniqueKey(), width: 140.0, height: 40.0),
      SizedBox(key: UniqueKey(), width: 150.0, height: 50.0),
    ];

    const double indicatorWeight = 2.0; // the default

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
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
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key!)), tabRect);

    // Tab1 width = 140, height = 40
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);

    // Tab0 width = 130, height = 30
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 130.0;
    tabTop = (tabBarHeight - indicatorWeight - 30.0) / 2.0;
    tabBottom = tabTop + 30.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);

    // Tab 0 selected, indicator padding resolves to right: 100.0
    final double indicatorLeft = tabLeft - kTabLabelPadding.left + indicatorWeight / 2.0;
    final double indicatorRight = tabRight + kTabLabelPadding.left - indicatorWeight / 2.0 - 100.0;
    const double indicatorY = 50.0 + indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('TabBar with custom indicator and indicatorPadding(LTR)', (WidgetTester tester) async {
    const Color indicatorColor = Color(0xFF00FF00);
    const double padTop = 10.0;
    const double padBottom = 12.0;
    const double padLeft = 8.0;
    const double padRight = 4.0;
    const Decoration indicator = BoxDecoration(color: indicatorColor);

    final List<Widget> tabs = List<Widget>.generate(4, (int index) {
      return Tab(text: 'Tab $index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            indicator: indicator,
            indicatorPadding:
            const EdgeInsets.fromLTRB(padLeft, padTop, padRight, padBottom),
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox =
    tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox.size.height, 48.0);
    // 48 = _kTabHeight(46) + indicatorWeight(2.0) ~default

    const double indicatorBottom = 48.0 - padBottom;
    const double indicatorTop = padTop;
    double indicatorLeft = padLeft;
    double indicatorRight = 200.0 - padRight;

    expect(tabBarBox, paints..rect(
      rect: Rect.fromLTRB(
        indicatorLeft,
        indicatorTop,
        indicatorRight,
        indicatorBottom,
      ),
      color: indicatorColor,
    ));

    // Select tab 3
    controller.index = 3;
    await tester.pumpAndSettle();

    indicatorLeft = 600.0 + padLeft;
    indicatorRight = 800.0 - padRight;

    expect(tabBarBox, paints..rect(
      rect: Rect.fromLTRB(
        indicatorLeft,
        indicatorTop,
        indicatorRight,
        indicatorBottom,
      ),
      color: indicatorColor,
    ));
  });

  testWidgets('TabBar with custom indicator and indicatorPadding (RTL)', (WidgetTester tester) async {
    const Color indicatorColor = Color(0xFF00FF00);
    const double padTop = 10.0;
    const double padBottom = 12.0;
    const double padLeft = 8.0;
    const double padRight = 4.0;
    const Decoration indicator = BoxDecoration(color: indicatorColor);

    final List<Widget> tabs = List<Widget>.generate(4, (int index) {
      return Tab(text: 'Tab $index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
          indicator: indicator,
          indicatorPadding: const EdgeInsets.fromLTRB(padLeft, padTop, padRight, padBottom),
          controller: controller,
          tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox =
    tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox.size.height, 48.0);
    // 48 = _kTabHeight(46) + indicatorWeight(2.0) ~default
    expect(tabBarBox.size.width, 800.0);
    const double indicatorBottom = 48.0 - padBottom;
    const double indicatorTop = padTop;
    double indicatorLeft = 600.0 + padLeft;
    double indicatorRight = 800.0 - padRight;

    expect(tabBarBox, paints..rect(
      rect: Rect.fromLTRB(
        indicatorLeft,
        indicatorTop,
        indicatorRight,
        indicatorBottom,
      ),
      color: indicatorColor,
    ));

    // Select tab 3
    controller.index = 3;
    await tester.pumpAndSettle();

    indicatorLeft = padLeft;
    indicatorRight = 200.0 - padRight;

    expect(tabBarBox,paints..rect(
      rect: Rect.fromLTRB(
        indicatorLeft,
        indicatorTop,
        indicatorRight,
        indicatorBottom,
      ),
      color: indicatorColor,
    ));
  });

  testWidgets('TabBar with custom indicator - directional indicatorPadding (LTR)', (WidgetTester tester) async {
    final List<Widget > tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: 130.0, height: 30.0),
      SizedBox(key: UniqueKey(), width: 140.0, height: 40.0),
      SizedBox(key: UniqueKey(), width: 150.0, height: 50.0),
    ];
    const Color indicatorColor = Color(0xFF00FF00);
    const double padTop = 10.0;
    const double padBottom = 12.0;
    const double padStart = 8.0;
    const double padEnd = 4.0;
    const Decoration indicator = BoxDecoration(color: indicatorColor);
    const double indicatorWeight = 2.0; // the default

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            indicator: indicator,
            indicatorPadding: const EdgeInsetsDirectional.fromSTEB(padStart, padTop, padEnd, padBottom),
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    const double tabBarHeight = 50.0 + indicatorWeight; // 50 = max tab height
    expect(tabBarBox.size.height, tabBarHeight);

    // Tab0 width = 130, height = 30
    double tabLeft = kTabLabelPadding.left;
    double tabRight = tabLeft + 130.0;
    double tabTop = (tabBarHeight - indicatorWeight - 30.0) / 2.0;
    double tabBottom = tabTop + 30.0;
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);

    // Tab1 width = 140, height = 40
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);

    // Tab2 width = 150, height = 50
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 150.0;
    tabTop = (tabBarHeight - indicatorWeight - 50.0) / 2.0;
    tabBottom = tabTop + 50.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key!)), tabRect);

    // Tab 0 selected, indicator padding resolves to left: 8.0, right: 4.0
    const double indicatorLeft = padStart;
    final double indicatorRight = 130.0 + kTabLabelPadding.horizontal - padEnd;
    const double indicatorTop = padTop;
    const double indicatorBottom = tabBarHeight - padBottom;
    expect(tabBarBox, paints..rect(
      rect: Rect.fromLTRB(
        indicatorLeft,
        indicatorTop,
        indicatorRight,
        indicatorBottom,
      ),
      color: indicatorColor,
    ));
  });

  testWidgets('TabBar with custom indicator - directional indicatorPadding (RTL)', (WidgetTester tester) async {
    final List<Widget> tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: 130.0, height: 30.0),
      SizedBox(key: UniqueKey(), width: 140.0, height: 40.0),
      SizedBox(key: UniqueKey(), width: 150.0, height: 50.0),
    ];
    const Color indicatorColor = Color(0xFF00FF00);
    const double padTop = 10.0;
    const double padBottom = 12.0;
    const double padStart = 8.0;
    const double padEnd = 4.0;
    const Decoration indicator = BoxDecoration(color: indicatorColor);
    const double indicatorWeight = 2.0; // the default

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            indicator: indicator,
            indicatorPadding: const EdgeInsetsDirectional.fromSTEB(padStart, padTop, padEnd, padBottom),
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox =
    tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    const double tabBarHeight = 50.0 + indicatorWeight; // 50 = max tab height
    expect(tabBarBox.size.height, tabBarHeight);

    // Tab2 width = 150, height = 50
    double tabLeft = kTabLabelPadding.left;
    double tabRight = tabLeft + 150.0;
    double tabTop = (tabBarHeight - indicatorWeight - 50.0) / 2.0;
    double tabBottom = tabTop + 50.0;
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key!)), tabRect);

    // Tab1 width = 140, height = 40
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);

    // Tab0 width = 130, height = 30
    tabLeft = tabRight + kTabLabelPadding.right + kTabLabelPadding.left;
    tabRight = tabLeft + 130.0;
    tabTop = (tabBarHeight - indicatorWeight - 30.0) / 2.0;
    tabBottom = tabTop + 30.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);

    // Tab 0 selected, indicator padding resolves to left: 4.0, right: 8.0
    final double indicatorLeft = tabLeft - kTabLabelPadding.left + padEnd;
    final double indicatorRight = tabRight + kTabLabelPadding.left - padStart;
    const double indicatorTop = padTop;
    const double indicatorBottom = tabBarHeight - padBottom;

    expect(tabBarBox, paints..rect(
      rect: Rect.fromLTRB(
        indicatorLeft,
        indicatorTop,
        indicatorRight,
        indicatorBottom,
      ),
      color: indicatorColor,
    ));
  });

   testWidgets('TabBar with padding isScrollable: false', (WidgetTester tester) async {
    const double indicatorWeight = 2.0; // default indicator weight
    const EdgeInsets padding = EdgeInsets.only(left: 3.0, top: 7.0, right: 5.0, bottom: 3.0);

    final List<Widget> tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: double.infinity, height: 30.0),
      SizedBox(key: UniqueKey(), width: double.infinity, height: 40.0),
    ];

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            padding: padding,
            labelPadding: EdgeInsets.zero,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    final double tabBarHeight = 40.0 + indicatorWeight + padding.top + padding.bottom;  // 40 = max tab height
    expect(tabBarBox.size.height, tabBarHeight);

    final double tabSize = (tabBarBox.size.width - padding.horizontal) / 2.0;

    // Tab0 height = 30
    double tabLeft = padding.left;
    double tabRight = tabLeft + tabSize;
    double tabTop = (tabBarHeight - indicatorWeight + (padding.top - padding.bottom) - 30.0) / 2.0;
    double tabBottom = tabTop + 30.0;
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);

    // Tab1 height = 40
    tabLeft = tabRight;
    tabRight = tabLeft + tabSize;
    tabTop = (tabBarHeight - indicatorWeight + (padding.top - padding.bottom) - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);

    tabRight += padding.right;
    expect(tabBarBox.size.width, tabRight);
  });

  testWidgets('TabBar with padding isScrollable: true', (WidgetTester tester) async {
    const double indicatorWeight = 2.0; // default indicator weight
    const EdgeInsets padding = EdgeInsets.only(left: 3.0, top: 7.0, right: 5.0, bottom: 3.0);

    final List<Widget> tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: 130.0, height: 30.0),
      SizedBox(key: UniqueKey(), width: 140.0, height: 40.0),
      SizedBox(key: UniqueKey(), width: 150.0, height: 50.0),
    ];

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            padding: padding,
            labelPadding: EdgeInsets.zero,
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    final double tabBarHeight = 50.0 + indicatorWeight + padding.top + padding.bottom;  // 50 = max tab height
    expect(tabBarBox.size.height, tabBarHeight);

    // Tab0 width = 130, height = 30
    double tabLeft = padding.left;
    double tabRight = tabLeft + 130.0;
    double tabTop = (tabBarHeight - indicatorWeight + (padding.top - padding.bottom) - 30.0) / 2.0;
    double tabBottom = tabTop + 30.0;
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);

    // Tab1 width = 140, height = 40
    tabLeft = tabRight;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight + (padding.top - padding.bottom) - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);

    // Tab2 width = 150, height = 50
    tabLeft = tabRight;
    tabRight = tabLeft + 150.0;
    tabTop = (tabBarHeight - indicatorWeight + (padding.top - padding.bottom) - 50.0) / 2.0;
    tabBottom = tabTop + 50.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key!)), tabRect);

    tabRight += padding.right;
    expect(tabBarBox.size.width, tabRight);
  });

  testWidgets('TabBar with labelPadding', (WidgetTester tester) async {
    const double indicatorWeight = 2.0; // default indicator weight
    const EdgeInsets labelPadding = EdgeInsets.only(left: 3.0, right: 7.0);
    const EdgeInsets indicatorPadding = labelPadding;

    final List<Widget> tabs = <Widget>[
      SizedBox(key: UniqueKey(), width: 130.0, height: 30.0),
      SizedBox(key: UniqueKey(), width: 140.0, height: 40.0),
      SizedBox(key: UniqueKey(), width: 150.0, height: 50.0),
    ];

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            labelPadding: labelPadding,
            indicatorPadding: labelPadding,
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
    double tabLeft = labelPadding.left;
    double tabRight = tabLeft + 130.0;
    double tabTop = (tabBarHeight - indicatorWeight - 30.0) / 2.0;
    double tabBottom = tabTop + 30.0;
    Rect tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[0].key!)), tabRect);

    // Tab1 width = 140, height = 40
    tabLeft = tabRight + labelPadding.right + labelPadding.left;
    tabRight = tabLeft + 140.0;
    tabTop = (tabBarHeight - indicatorWeight - 40.0) / 2.0;
    tabBottom = tabTop + 40.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[1].key!)), tabRect);

    // Tab2 width = 150, height = 50
    tabLeft = tabRight + labelPadding.right + labelPadding.left;
    tabRight = tabLeft + 150.0;
    tabTop = (tabBarHeight - indicatorWeight - 50.0) / 2.0;
    tabBottom = tabTop + 50.0;
    tabRect = Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
    expect(tester.getRect(find.byKey(tabs[2].key!)), tabRect);

    // Tab 0 selected, indicatorPadding == labelPadding
    final double indicatorLeft = indicatorPadding.left + indicatorWeight / 2.0;
    final double indicatorRight = 130.0 + labelPadding.horizontal - indicatorPadding.right - indicatorWeight / 2.0;
    final double indicatorY = tabBottom + indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('Overflowing RTL tab bar', (WidgetTester tester) async {
    final List<Widget> tabs = List<Widget>.filled(100,
      // For convenience padded width of each tab will equal 100:
      // 68 + kTabLabelPadding.horizontal(32)
      SizedBox(key: UniqueKey(), width: 68.0, height: 40.0),
    );

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    const double indicatorWeight = 2.0; // the default

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));

    controller.animateTo(tabs.length - 1, duration: const Duration(seconds: 1), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: const Offset(4951.0, indicatorY),
      p2: const Offset(5049.0, indicatorY),
    ));

    await tester.pump(const Duration(milliseconds: 501));

    // Tab 99 out of 100 selected, appears on the far left because RTL
    indicatorLeft = indicatorWeight / 2.0;
    indicatorRight = 100.0 - indicatorWeight / 2.0;
    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('Tab indicator animation test', (WidgetTester tester) async {
    const double indicatorWeight = 8.0;

    final List<Widget> tabs = List<Widget>.generate(4, (int index) {
      return Tab(text: 'Tab $index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            indicatorWeight: indicatorWeight,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));

    // Initial indicator position.
    const double indicatorY = 54.0 - indicatorWeight / 2.0;
    double indicatorLeft = indicatorWeight / 2.0;
    double indicatorRight = 200.0 - (indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));

    // Select tab 1.
    controller.animateTo(1, duration: const Duration(milliseconds: 1000), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    indicatorLeft = 100.0 + indicatorWeight / 2.0;
    indicatorRight = 300.0 - (indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));

    // Select tab 2 when animation is running.
    controller.animateTo(2, duration: const Duration(milliseconds: 1000), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    indicatorLeft = 250.0 + indicatorWeight / 2.0;
    indicatorRight = 450.0 - (indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));

    // Final indicator position.
    await tester.pumpAndSettle();
    indicatorLeft = 400.0 + indicatorWeight / 2.0;
    indicatorRight = 600.0 - (indicatorWeight / 2.0);

    expect(tabBarBox, paints..line(
      strokeWidth: indicatorWeight,
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final List<Tab> tabs = List<Tab>.generate(2, (int index) {
      return Tab(text: 'TAB #$index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Semantics(
          container: true,
          child: TabBar(
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                    id: 3,
                    rect: TestSemantics.fullScreen,
                    flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 4,
                        actions: <SemanticsAction>[SemanticsAction.tap],
                        flags: <SemanticsFlag>[
                          SemanticsFlag.isSelected,
                          SemanticsFlag.isFocusable,
                        ],
                        label: 'TAB #0\nTab 1 of 2',
                        rect: const Rect.fromLTRB(0.0, 0.0, 116.0, kTextTabBarHeight),
                        transform: Matrix4.translationValues(0.0, 276.0, 0.0),
                      ),
                      TestSemantics(
                        id: 5,
                        flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                        actions: <SemanticsAction>[SemanticsAction.tap],
                        label: 'TAB #1\nTab 2 of 2',
                        rect: const Rect.fromLTRB(0.0, 0.0, 116.0, kTextTabBarHeight),
                        transform: Matrix4.translationValues(116.0, 276.0, 0.0),
                      ),
                    ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('correct scrolling semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final List<Tab> tabs = List<Tab>.generate(20, (int index) {
      return Tab(text: 'This is a very wide tab #$index');
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Semantics(
          container: true,
          child: TabBar(
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
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 0,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              tabs: const <Widget>[],
            ),
            Flexible(
              child: TabBarView(
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

    await tester.fling(find.byType(TabBar), const Offset(-100.0, 0.0), 5000.0, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBarView), const Offset(100.0, 0.0), 5000.0);
    await tester.pumpAndSettle();

    expect(controller.index, 0);
  });

  testWidgets('TabBar etc with one tab', (WidgetTester tester) async {
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 1,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              tabs: const <Widget>[Tab(text: 'TAB')],
            ),
            Flexible(
              child: TabBarView(
                controller: controller,
                children: const <Widget>[Text('PAGE')],
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
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              indicatorWeight: 30.0,
              tabs: const <Widget>[Tab(text: 'TAB1'), Tab(text: 'TAB2')],
            ),
            Flexible(
              child: TabBarView(
                controller: controller,
                children: const <Widget>[Text('PAGE1'), Text('PAGE2')],
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
    final SemanticsTester semantics = SemanticsTester(tester);

    final List<Tab> tabs = List<Tab>.generate(2, (int index) {
      return Tab(
        child: Semantics(
          label: 'Semantics override $index',
          child: ExcludeSemantics(
            child: Text('TAB #$index'),
          ),
        ),
      );
    });

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Semantics(
          container: true,
          child: TabBar(
            isScrollable: true,
            controller: controller,
            tabs: tabs,
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                    id: 3,
                    rect: TestSemantics.fullScreen,
                    flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 4,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.isSelected,
                          SemanticsFlag.isFocusable,
                        ],
                        actions: <SemanticsAction>[SemanticsAction.tap],
                        label: 'Semantics override 0\nTab 1 of 2',
                        rect: const Rect.fromLTRB(0.0, 0.0, 116.0, kTextTabBarHeight),
                        transform: Matrix4.translationValues(0.0, 276.0, 0.0),
                      ),
                      TestSemantics(
                        id: 5,
                        flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                        actions: <SemanticsAction>[SemanticsAction.tap],
                        label: 'Semantics override 1\nTab 2 of 2',
                        rect: const Rect.fromLTRB(0.0, 0.0, 116.0, kTextTabBarHeight),
                        transform: Matrix4.translationValues(116.0, 276.0, 0.0),
                      ),
                    ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('can be notified of TabBar onTap behavior', (WidgetTester tester) async {
    int tabIndex = -1;

    Widget buildFrame({
      required TabController controller,
      required List<String> tabs,
    }) {
      return boilerplate(
        child: TabBar(
          controller: controller,
          tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
          onTap: (int index) {
            tabIndex = index;
          },
        ),
      );
    }

    final List<String> tabs = <String>['A', 'B', 'C'];
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
      initialIndex: tabs.indexOf('C'),
    );

    await tester.pumpWidget(buildFrame(tabs: tabs, controller: controller));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(controller, isNotNull);
    expect(controller.index, 2);
    expect(tabIndex, -1); // no tap so far so tabIndex should reflect that

    // Verify whether the [onTap] notification works when the [TabBar] animates.

    await tester.pumpWidget(buildFrame(tabs: tabs, controller: controller));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(controller.indexIsChanging, true);
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(controller.previousIndex, 2);
    expect(controller.indexIsChanging, false);
    expect(tabIndex, controller.index);

    tabIndex = -1;

    await tester.pumpWidget(buildFrame(tabs: tabs, controller: controller));
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.index, 2);
    expect(controller.previousIndex, 1);
    expect(tabIndex, controller.index);

    tabIndex = -1;

    await tester.pumpWidget(buildFrame(tabs: tabs, controller: controller));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(controller.previousIndex, 2);
    expect(tabIndex, controller.index);

    tabIndex = -1;

    // Verify whether [onTap] is called even when the [TabController] does
    // not change.

    final int currentControllerIndex = controller.index;
    await tester.pumpWidget(buildFrame(tabs: tabs, controller: controller));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.index, currentControllerIndex); // controller has not changed
    expect(tabIndex, 0);
  });

  test('illegal constructor combinations', () {
    expect(() => Tab(icon: nonconst(null)), throwsAssertionError);
    expect(() => Tab(icon: Container(), text: 'foo', child: Container()), throwsAssertionError);
    expect(() => Tab(text: 'foo', child: Container()), throwsAssertionError);
  });

  testWidgets('Tabs changes mouse cursor when a tab is hovered', (WidgetTester tester) async {
    final List<String> tabs = <String>['A', 'B'];
    await tester.pumpWidget(MaterialApp(home: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          body: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: TabBar(
              mouseCursor: SystemMouseCursors.text,
              tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
    ));

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(Tab).first));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(MaterialApp(home: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          body: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: TabBar(
              tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
    ));
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);
  });

  testWidgets('TabController changes', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/14812

    Widget buildFrame(TabController controller) {
      return boilerplate(
        child: Container(
          alignment: Alignment.topLeft,
          child: TabBar(
            controller: controller,
            tabs: const <Tab>[
              Tab(text: 'LEFT'),
              Tab(text: 'RIGHT'),
            ],
          ),
        ),
      );
    }

    final TabController controller1 = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    final TabController controller2 = TabController(
      vsync: const TestVSync(),
      length: 2,
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
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
      p1: Offset(indicatorLeft, indicatorY),
      p2: Offset(indicatorRight, indicatorY),
    ));
  });

  testWidgets('Default tab indicator color is white', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/15958
    final List<String> tabs = <String>['LEFT', 'RIGHT'];
    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(tabBarBox, paints..line(
      color: Colors.white,
    ));
  });

  testWidgets('Tab indicator color should not be adjusted when disable [automaticIndicatorColorAdjustment]', (WidgetTester tester) async {
     // Regression test for https://github.com/flutter/flutter/issues/68077
     final List<String> tabs = <String>['LEFT', 'RIGHT'];
     await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT', automaticIndicatorColorAdjustment: false));
     final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
     expect(tabBarBox, paints..line(
       color: const Color(0xff2196f3),
     ));
  });

  group('Tab feedback', () {
    late FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback.dispose();
    });

    testWidgets('Tab feedback is enabled (default)', (WidgetTester tester) async {
      await tester.pumpWidget(
        boilerplate(
          child: const DefaultTabController(
            length: 1,
            child: TabBar(
              tabs: <Tab>[
                Tab(text: 'A'),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);

      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('Tab feedback is disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        boilerplate(
          child: const DefaultTabController(
            length: 1,
            child: TabBar(
              tabs: <Tab>[
                Tab(text: 'A'),
              ],
              enableFeedback: false,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });
  });

  group('Tab overlayColor affects ink response', () {
    testWidgets("Tab's ink well changes color on hover with Tab overlayColor", (WidgetTester tester) async {
      await tester.pumpWidget(
        boilerplate(
          child: DefaultTabController(
            length: 1,
            child: TabBar(
              tabs: const <Tab>[
                Tab(text: 'A'),
              ],
              overlayColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                 if (states.contains(MaterialState.hovered))
                    return const Color(0xff00ff00);
                  if (states.contains(MaterialState.pressed))
                    return const Color(0xf00fffff);
                  return const Color(0xffbadbad); // Shouldn't happen.
                },
              ),
            ),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(Tab)));
      await tester.pumpAndSettle();
      final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
      expect(inkFeatures, paints..rect(rect: const Rect.fromLTRB(0.0, 276.0, 800.0, 324.0), color: const Color(0xff00ff00)));
    });

    testWidgets(
      "Tab's ink response splashColor matches resolved Tab overlayColor for MaterialState.pressed",
      (WidgetTester tester) async {
        const Color splashColor = Color(0xf00fffff);
        await tester.pumpWidget(
          boilerplate(
            child: DefaultTabController(
              length: 1,
              child: TabBar(
                tabs: const <Tab>[
                  Tab(text: 'A'),
                ],
                overlayColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.hovered))
                      return const Color(0xff00ff00);
                    if (states.contains(MaterialState.pressed))
                      return splashColor;
                    return const Color(0xffbadbad); // Shouldn't happen.
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final TestGesture gesture = await tester.startGesture(tester.getRect(find.byType(InkWell)).center);
        await tester.pump(const Duration(milliseconds: 200)); // unconfirmed splash is well underway
        final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
        expect(inkFeatures, paints..circle(x: 400, y: 24, color: splashColor));
        await gesture.up();
      },
    );
  });

  testWidgets('Skipping tabs with global key does not crash', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/24660
    final List<String> tabs = <String>[
      'Tab1',
      'Tab2',
      'Tab3',
      'Tab4',
    ];
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300.0,
            height: 200.0,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('tabs'),
                bottom: TabBar(
                  controller: controller,
                  tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
                ),
              ),
              body: TabBarView(
                controller: controller,
                children: <Widget>[
                  Text('1', key: GlobalKey()),
                  Text('2', key: GlobalKey()),
                  Text('3', key: GlobalKey()),
                  Text('4', key: GlobalKey()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    await tester.tap(find.text('Tab4'));
    await tester.pumpAndSettle();
    expect(controller.index, 3);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('Skipping tabs with a KeepAlive child works', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/11895
    final List<String> tabs = <String>[
      'Tab1',
      'Tab2',
      'Tab3',
      'Tab4',
      'Tab5',
    ];
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: tabs.length,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300.0,
            height: 200.0,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('tabs'),
                bottom: TabBar(
                  controller: controller,
                  tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
                ),
              ),
              body: TabBarView(
                controller: controller,
                children: <Widget>[
                  AlwaysKeepAliveWidget(key: UniqueKey()),
                  const Text('2'),
                  const Text('3'),
                  const Text('4'),
                  const Text('5'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text(AlwaysKeepAliveWidget.text), findsOneWidget);
    expect(find.text('4'), findsNothing);
    await tester.tap(find.text('Tab4'));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(controller.index, 3);
    expect(find.text(AlwaysKeepAliveWidget.text, skipOffstage: false), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('tabbar does not scroll when viewport dimensions initially change from zero to non-zero', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/10531.

    const List<Widget> tabs = <Widget>[
      Tab(text: 'NEW MEXICO'),
      Tab(text: 'GABBA'),
      Tab(text: 'HEY'),
    ];
    final TabController controller = TabController(vsync: const TestVSync(), length: tabs.length);

    Widget buildTestWidget({double? width, double? height}) {
      return MaterialApp(
        home: Center(
          child: SizedBox(
            height: height,
            width: width,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('AppBarBug'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(30.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Align(
                      alignment: FractionalOffset.center,
                      child: TabBar(
                        controller: controller,
                        isScrollable: true,
                        tabs: tabs,
                      ),
                    ),
                  ),
                ),
              ),
              body: const Center(
                child: Text('Hello World'),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildTestWidget(
        width: 0.0,
        height: 0.0,
      ),
    );

    await tester.pumpWidget(
      buildTestWidget(
        width: 300.0,
        height: 400.0,
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
    expect(await tester.pumpAndSettle(), 1); // no more frames are scheduled.
  });

  // Regression test for https://github.com/flutter/flutter/issues/20292.
  testWidgets('Number of tabs can be updated dynamically', (WidgetTester tester) async {
    final List<String> threeTabs = <String>['A', 'B', 'C'];
    final List<String> twoTabs = <String>['A', 'B'];
    final List<String> oneTab = <String>['A'];
    final Key key = UniqueKey();
    Widget buildTabs(List<String> tabs) {
      return boilerplate(
        child: DefaultTabController(
          key: key,
          length: tabs.length,
          child: TabBar(
            tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
          ),
        ),
      );
    }
    TabController getController() => DefaultTabController.of(tester.element(find.text('A')))!;

    await tester.pumpWidget(buildTabs(threeTabs));
    await tester.tap(find.text('B'));
    await tester.pump();
    TabController controller = getController();
    expect(controller.previousIndex, 0);
    expect(controller.index, 1);
    expect(controller.length, 3);

    await tester.pumpWidget(buildTabs(twoTabs));
    controller = getController();
    expect(controller.previousIndex, 0);
    expect(controller.index, 1);
    expect(controller.length, 2);

    await tester.pumpWidget(buildTabs(oneTab));
    controller = getController();
    expect(controller.previousIndex, 1);
    expect(controller.index, 0);
    expect(controller.length, 1);

    await tester.pumpWidget(buildTabs(twoTabs));
    controller = getController();
    expect(controller.previousIndex, 1);
    expect(controller.index, 0);
    expect(controller.length, 2);
  });

  // Regression test for https://github.com/flutter/flutter/issues/15008.
  testWidgets('TabBar with one tab has correct color', (WidgetTester tester) async {
    const Tab tab = Tab(text: 'A');
    const Color selectedTabColor = Color(0x00000001);
    const Color unselectedTabColor = Color(0x00000002);

    await tester.pumpWidget(boilerplate(
      child: const DefaultTabController(
        length: 1,
        child: TabBar(
          tabs: <Tab>[tab],
          labelColor: selectedTabColor,
          unselectedLabelColor: unselectedTabColor,
        ),
      ),
    ));

    final IconThemeData iconTheme = IconTheme.of(tester.element(find.text('A')));
    expect(iconTheme.color, equals(selectedTabColor));
  });

  testWidgets('Replacing the tabController after disposing the old one', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/32428

    TabController controller = TabController(vsync: const TestVSync(), length: 2);
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  controller: controller,
                  tabs: List<Widget>.generate(controller.length, (int index) => Tab(text: 'Tab$index')),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Change TabController length'),
                    onPressed: () {
                      setState(() {
                        controller.dispose();
                        controller = TabController(vsync: const TestVSync(), length: 3);
                      });
                    },
                  ),
                ],
              ),
              body: TabBarView(
                controller: controller,
                children: List<Widget>.generate(controller.length, (int index) => Center(child: Text('Tab $index'))),
              ),
            );
          },
        ),
      ),
    );

    expect(controller.index, 0);
    expect(controller.length, 2);
    expect(find.text('Tab0'), findsOneWidget);
    expect(find.text('Tab1'), findsOneWidget);
    expect(find.text('Tab2'), findsNothing);

    await tester.tap(find.text('Change TabController length'));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(controller.length, 3);
    expect(find.text('Tab0'), findsOneWidget);
    expect(find.text('Tab1'), findsOneWidget);
    expect(find.text('Tab2'), findsOneWidget);
  });

  testWidgets('DefaultTabController should allow for a length of zero', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/20292.
    List<String> tabTextContent = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DefaultTabController(
              length: tabTextContent.length,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Default TabBar Preview'),
                  bottom: tabTextContent.isNotEmpty
                    ? TabBar(
                        isScrollable: true,
                        tabs: tabTextContent.map((String textContent) => Tab(text: textContent)).toList(),
                      )
                    : null,
                ),
                body: tabTextContent.isNotEmpty
                  ? TabBarView(
                      children: tabTextContent.map((String textContent) => Tab(text: "$textContent's view")).toList(),
                    )
                  : const Center(child: Text('No tabs')),
                bottomNavigationBar: BottomAppBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        key: const Key('Add tab'),
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            tabTextContent = List<String>.from(tabTextContent)
                              ..add('Tab ${tabTextContent.length + 1}');
                          });
                        },
                      ),
                      IconButton(
                        key: const Key('Delete tab'),
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            tabTextContent = List<String>.from(tabTextContent)
                              ..removeLast();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Initializes with zero tabs properly
    expect(find.text('No tabs'), findsOneWidget);
    await tester.tap(find.byKey(const Key('Add tab')));
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text("Tab 1's view"), findsOneWidget);

    // Dynamically updates to zero tabs properly
    await tester.tap(find.byKey(const Key('Delete tab')));
    await tester.pumpAndSettle();
    expect(find.text('No tabs'), findsOneWidget);
  });

  testWidgets('DefaultTabController should allow dynamic length of tabs', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/94504.
    final List<String> tabTitles = <String>[];

    void _onTabAdd(StateSetter setState) {
      setState(() {
        tabTitles.add('Tab ${tabTitles.length + 1}');
      });
    }

    void _onTabRemove(StateSetter setState) {
      setState(() {
        tabTitles.removeLast();
      });
    }

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DefaultTabController(
              length: tabTitles.length,
              child: Scaffold(
                appBar: AppBar(
                  actions: <Widget>[
                    TextButton(
                      key: const Key('Add tab'),
                      child: const Text('Add tab'),
                      onPressed: () => _onTabAdd(setState),
                    ),
                    TextButton(
                      key: const Key('Remove tab'),
                      child: const Text('Remove tab'),
                      onPressed: () => _onTabRemove(setState),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(40.0),
                    child: Expanded(
                      child: TabBar(
                        tabs: tabTitles
                            .map((String title) => Tab(text: title))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Tab 1'), findsNothing);
    expect(find.text('Tab 2'), findsNothing);

    await tester.tap(find.byKey(const Key('Add tab'))); // +1
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('Tab 2'), findsNothing);

    await tester.tap(find.byKey(const Key('Add tab'))); // +2
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('Tab 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('Remove tab'))); // -2
    await tester.tap(find.byKey(const Key('Remove tab'))); // -1
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsNothing);
    expect(find.text('Tab 2'), findsNothing);
  });

  testWidgets('TabBar - updating to and from zero tabs', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/68962.
    final List<String> tabTitles = <String>[];
    TabController tabController = TabController(length: tabTitles.length, vsync: const TestVSync());

    void _onTabAdd(StateSetter setState) {
      setState(() {
        tabTitles.add('Tab ${tabTitles.length + 1}');
        tabController = TabController(length: tabTitles.length, vsync: const TestVSync());
      });
    }

    void _onTabRemove(StateSetter setState) {
      setState(() {
        tabTitles.removeLast();
        tabController = TabController(length: tabTitles.length, vsync: const TestVSync());
      });
    }

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  TextButton(
                    key: const Key('Add tab'),
                    child: const Text('Add tab'),
                    onPressed: () => _onTabAdd(setState),
                  ),
                  TextButton(
                    key: const Key('Remove tab'),
                    child: const Text('Remove tab'),
                    onPressed: () => _onTabRemove(setState),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40.0),
                  child: Expanded(
                    child: TabBar(
                      controller: tabController,
                      tabs: tabTitles
                        .map((String title) => Tab(text: title))
                        .toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Tab 1'), findsNothing);
    expect(find.text('Add tab'), findsOneWidget);
    await tester.tap(find.byKey(const Key('Add tab')));
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('Remove tab')));
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsNothing);
  });

   testWidgets('TabBar expands vertically to accommodate the Icon and child Text() pair the same amount it would expand for Icon and text pair.', (WidgetTester tester) async {
    const List<Widget> tabListWithText = <Widget>[
      Tab(icon: Icon(Icons.notifications), text: 'Test'),
    ];
    const List<Widget> tabListWithTextChild = <Widget>[
      Tab(icon: Icon(Icons.notifications), child: Text('Test')),
    ];

    const TabBar tabBarWithText = TabBar(tabs: tabListWithText);
    const TabBar tabBarWithTextChild = TabBar(tabs: tabListWithTextChild);

    expect(tabBarWithText.preferredSize, tabBarWithTextChild.preferredSize);
   });

  testWidgets('Setting TabController index should make TabBar indicator immediately pop into the position', (WidgetTester tester) async {
    const List<Tab> tabs = <Tab>[
      Tab(text: 'A'), Tab(text: 'B'), Tab(text: 'C'),
    ];
    const Color indicatorColor = Color(0xFFFF0000);
    late TabController tabController;

    Widget buildTabControllerFrame(BuildContext context, TabController controller) {
      tabController = controller;
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              controller: controller,
              tabs: tabs,
              indicatorColor: indicatorColor,
            ),
          ),
          body: TabBarView(
            controller: controller,
            children: tabs.map((Tab tab) {
              return Center(child: Text(tab.text!));
            }).toList(),
          ),
        ),
      );
    }

    await tester.pumpWidget(TabControllerFrame(
      builder: buildTabControllerFrame,
      length: tabs.length,
    ));

    final RenderBox box = tester.renderObject(find.byType(TabBar));
    final TabIndicatorRecordingCanvas canvas = TabIndicatorRecordingCanvas(indicatorColor);
    final TestRecordingPaintingContext context = TestRecordingPaintingContext(canvas);

    box.paint(context, Offset.zero);
    double expectedIndicatorLeft = canvas.indicatorRect.left;

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    void pageControllerListener() {
      // Whenever TabBarView scrolls due to changing TabController's index,
      // check if indicator stays idle in its expectedIndicatorLeft
      box.paint(context, Offset.zero);
      expect(canvas.indicatorRect.left, expectedIndicatorLeft);
    }

    // Moving from index 0 to 2 (distanced tabs)
    tabController.index = 2;
    box.paint(context, Offset.zero);
    expectedIndicatorLeft = canvas.indicatorRect.left;
    pageController.addListener(pageControllerListener);
    await tester.pumpAndSettle();

    // Moving from index 2 to 1 (neighboring tabs)
    tabController.index = 1;
    box.paint(context, Offset.zero);
    expectedIndicatorLeft = canvas.indicatorRect.left;
    await tester.pumpAndSettle();
    pageController.removeListener(pageControllerListener);
  });

  testWidgets('Setting BouncingScrollPhysics on TabBarView does not include ClampingScrollPhysics', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/57708
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 10,
        child: Scaffold(
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: List<Widget>.generate(10, (int i) => Center(child: Text('index $i'))),
          ),
        ),
      ),
    ));

    final PageView pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics.toString().contains('ClampingScrollPhysics'), isFalse);
  });

  testWidgets('TabController changes offset attribute', (WidgetTester tester) async {
    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    late Color firstColor;
    late Color secondColor;

    await tester.pumpWidget(
      boilerplate(
        child: TabBar(
          controller: controller,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          tabs: <Widget>[
            Builder(builder: (BuildContext context) {
              firstColor = DefaultTextStyle.of(context).style.color!;
              return const Text('First');
            }),
            Builder(builder: (BuildContext context) {
              secondColor = DefaultTextStyle.of(context).style.color!;
              return const Text('Second');
            }),
          ],
        ),
      ),
    );

    expect(firstColor, equals(Colors.white));
    expect(secondColor, equals(Colors.black));

    controller.offset = 0.6;
    await tester.pump();

    expect(firstColor, equals(Color.lerp(Colors.white, Colors.black, 0.6)));
    expect(secondColor, equals(Color.lerp(Colors.black, Colors.white, 0.6)));

    controller.index = 1;
    await tester.pump();

    expect(firstColor, equals(Colors.black));
    expect(secondColor, equals(Colors.white));

    controller.offset = 0.6;
    await tester.pump();

    expect(firstColor, equals(Colors.black));
    expect(secondColor, equals(Colors.white));
  });

  testWidgets('Crash on dispose', (WidgetTester tester) async {
    await tester.pumpWidget(const Padding(padding: EdgeInsets.only(right: 200.0), child: TabBarDemo()));
    await tester.tap(find.byIcon(Icons.directions_bike));
    // There was a time where this would throw an exception
    // because we tried to send a notification on dispose.
  });

  testWidgets("TabController's animation value should be in sync with TabBarView's scroll value when user interrupts ballistic scroll", (WidgetTester tester) async {
    final TabController tabController = TabController(
      vsync: const TestVSync(),
      length: 3,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(
        child: Center(
          child: SizedBox(
            width: 400.0,
            height: 400.0,
            child: TabBarView(
              controller: tabController,
              children: const <Widget>[
                Center(child: Text('0')),
                Center(child: Text('1')),
                Center(child: Text('2')),
              ],
            ),
          ),
        ),
      ),
    ));

    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    final ScrollPosition position = pageController.position;

    expect(tabController.index, 0);
    expect(position.pixels, 0.0);

    pageController.jumpTo(300.0);
    await tester.pump();
    expect(tabController.animation!.value, pageController.page);

    // Touch TabBarView while ballistic scrolling is happening and
    // check if tabController's animation value properly follows page value.
    await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    expect(tabController.animation!.value, pageController.page);
  });

  testWidgets('Does not instantiate intermediate tabs during animation', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/14316.
    final List<String> log = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(text: 'car'),
                Tab(text: 'transit'),
                Tab(text: 'bike'),
                Tab(text: 'boat'),
                Tab(text: 'bus'),
              ],
            ),
            title: const Text('Tabs Test'),
          ),
          body: TabBarView(
            children: <Widget>[
              TabBody(index: 0, log: log),
              TabBody(index: 1, log: log),
              TabBody(index: 2, log: log),
              TabBody(index: 3, log: log),
              TabBody(index: 4, log: log),
            ],
          ),
        ),
      ),
    ));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(log, <String>['init: 0']);

    await tester.tap(find.text('boat'));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
    expect(find.text('3'), findsOneWidget);

    // No other tab got instantiated during the animation.
    expect(log, <String>['init: 0', 'init: 3', 'dispose: 0']);
  });

  testWidgets("TabController's animation value should be updated when TabController's index >= tabs's length", (WidgetTester tester) async {
    // This is a regression test for the issue brought up here
    // https://github.com/flutter/flutter/issues/79226

    final List<String> tabs = <String>['A', 'B', 'C'];
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(
                    tabs: tabs.map<Widget>((String tab) => Tab(text: tab)).toList(),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Remove Last Tab'),
                      onPressed: () {
                        setState(() {
                          tabs.removeLast();
                        });
                      },
                    ),
                  ],
                ),
                body: TabBarView(
                  children: tabs.map<Widget>((String tab) => Tab(text: 'Tab child $tab')).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );

    TabController getController() => DefaultTabController.of(tester.element(find.text('B')))!;
    TabController controller = getController();

    controller.animateTo(2, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    controller = getController();
    expect(controller.index, 2);
    expect(controller.animation!.value, 2);

    await tester.tap(find.text('Remove Last Tab'));
    await tester.pumpAndSettle();

    controller = getController();
    expect(controller.index, 1);
    expect(controller.animation!.value, 1);
  });

  testWidgets('Tab preferredSize gives correct value', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Row(
            children: const <Tab>[
              Tab(icon: Icon(Icons.message)),
              Tab(text: 'Two'),
              Tab(text: 'Three', icon: Icon(Icons.chat)),
            ],
          ),
        ),
      ),
    );

    final Tab firstTab = tester.widget(find.widgetWithIcon(Tab, Icons.message));
    final Tab secondTab = tester.widget(find.widgetWithText(Tab, 'Two'));
    final Tab thirdTab = tester.widget(find.widgetWithText(Tab, 'Three'));

    expect(firstTab.preferredSize, const Size.fromHeight(46.0));
    expect(secondTab.preferredSize, const Size.fromHeight(46.0));
    expect(thirdTab.preferredSize, const Size.fromHeight(72.0));
  });

  testWidgets('TabBar preferredSize gives correct value when there are both icon and text in tabs', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(text: 'car'),
                Tab(text: 'transit'),
                Tab(text: 'bike'),
                Tab(text: 'boat', icon: Icon(Icons.message)),
                Tab(text: 'bus'),
              ],
            ),
            title: const Text('Tabs Test'),
          ),
        ),
      ),
    ));

    final TabBar tabBar = tester.widget(find.widgetWithText(TabBar, 'car'));

    expect(tabBar.preferredSize, const Size.fromHeight(74.0));
  });

  testWidgets('TabBar preferredSize gives correct value when there is only icon or text in tabs', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(text: 'car'),
                Tab(icon: Icon(Icons.message)),
                Tab(text: 'bike'),
                Tab(icon: Icon(Icons.chat)),
                Tab(text: 'bus'),
              ],
            ),
            title: const Text('Tabs Test'),
          ),
        ),
      ),
    ));

    final TabBar tabBar = tester.widget(find.widgetWithText(TabBar, 'car'));

    expect(tabBar.preferredSize, const Size.fromHeight(48.0));
  });

  testWidgets('Tabs are given uniform padding in case of few tabs having both text and icon', (WidgetTester tester) async {
    const EdgeInsetsGeometry expectedPaddingAdjusted = EdgeInsets.symmetric(vertical: 13.0, horizontal: 16.0);
    const EdgeInsetsGeometry expectedPaddingDefault = EdgeInsets.symmetric(horizontal: 16.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              controller: TabController(length: 3, vsync: const TestVSync()),
              tabs: const <Widget>[
                Tab(text: 'Tab 1', icon: Icon(Icons.plus_one)),
                Tab(text: 'Tab 2'),
                Tab(text: 'Tab 3'),
              ],
            ),
          ),
        ),
      ),
    );

    final Padding tabOne = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 1').first);
    final Padding tabTwo = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 2').first);
    final Padding tabThree = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 3').first);

    expect(tabOne.padding, expectedPaddingDefault);
    expect(tabTwo.padding, expectedPaddingAdjusted);
    expect(tabThree.padding, expectedPaddingAdjusted);
  });

  testWidgets('Tabs are given uniform padding when labelPadding is given', (WidgetTester tester) async {
    const EdgeInsetsGeometry labelPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0);
    const EdgeInsetsGeometry expectedPaddingAdjusted = EdgeInsets.symmetric(vertical: 23.0, horizontal: 20.0);
    const EdgeInsetsGeometry expectedPaddingDefault = EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              labelPadding: labelPadding,
              controller: TabController(length: 3, vsync: const TestVSync()),
              tabs: const <Widget>[
                Tab(text: 'Tab 1', icon: Icon(Icons.plus_one)),
                Tab(text: 'Tab 2'),
                Tab(text: 'Tab 3'),
              ],
            ),
          ),
        ),
      ),
    );

    final Padding tabOne = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 1').first);
    final Padding tabTwo = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 2').first);
    final Padding tabThree = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 3').first);

    expect(tabOne.padding, expectedPaddingDefault);
    expect(tabTwo.padding, expectedPaddingAdjusted);
    expect(tabThree.padding, expectedPaddingAdjusted);
  });

  testWidgets('Tabs are given uniform padding TabBarTheme.labelPadding is given', (WidgetTester tester) async {
    const EdgeInsetsGeometry labelPadding = EdgeInsets.symmetric(vertical: 15.0, horizontal: 20);
    const EdgeInsetsGeometry expectedPaddingAdjusted = EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0);
    const EdgeInsetsGeometry expectedPaddingDefault = EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          tabBarTheme: const TabBarTheme(labelPadding: labelPadding),
        ),
        home: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              controller: TabController(length: 3, vsync: const TestVSync()),
              tabs: const <Widget>[
                Tab(text: 'Tab 1', icon: Icon(Icons.plus_one)),
                Tab(text: 'Tab 2'),
                Tab(text: 'Tab 3'),
              ],
            ),
          ),
        ),
      ),
    );

    final Padding tabOne = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 1').first);
    final Padding tabTwo = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 2').first);
    final Padding tabThree = tester.widget<Padding>(find.widgetWithText(Padding, 'Tab 3').first);

    expect(tabOne.padding, expectedPaddingDefault);
    expect(tabTwo.padding, expectedPaddingAdjusted);
    expect(tabThree.padding, expectedPaddingAdjusted);
  });

  testWidgets('Change tab bar height', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.check,size: 40),
                  height: 85,
                  child: Text('1 - OK',style: TextStyle(fontSize: 25),),
                ), // icon and child
                Tab(
                  height: 85,
                  child: Text('2 - OK',style: TextStyle(fontSize: 25),),
                ), // child
                Tab(
                  icon: Icon(Icons.done,size: 40),
                  height: 85,
                ), // icon
                Tab(
                  text: '4 - OK',
                  height: 85,
                ), // text
              ],
            ),
          ),
        ),
      ),
    ));
    final Tab firstTab = tester.widget(find.widgetWithIcon(Tab, Icons.check));
    final Tab secTab = tester.widget(find.widgetWithText(Tab, '2 - OK' ));
    final Tab thirdTab = tester.widget(find.widgetWithIcon(Tab, Icons.done));
    final Tab fourthTab = tester.widget(find.widgetWithText(Tab, '4 - OK' ));
    expect(firstTab.preferredSize.height, 85);
    expect(firstTab.height, 85);
    expect(secTab.height, 85);
    expect(thirdTab.height, 85);
    expect(fourthTab.height, 85);
  });

  testWidgets('Change tab bar height 2', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 1,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.check,size: 40),
                  text: '1 - OK',
                  height: 85,
                ), // icon and text
              ],
            ),
          ),
        ),
      ),
    ));
    final Tab firstTab = tester.widget(find.widgetWithIcon(Tab, Icons.check));
    expect(firstTab.height, 85);
  });

  testWidgets('Test semantics of TabPageSelector', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final TabController controller = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    await tester.pumpWidget(
      boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              indicatorWeight: 30.0,
              tabs: const <Widget>[Tab(text: 'TAB1'), Tab(text: 'TAB2')],
            ),
            Flexible(
              child: TabBarView(
                controller: controller,
                children: const <Widget>[Text('PAGE1'), Text('PAGE2')],
              ),
            ),
            Expanded(
              child: TabPageSelector(
                controller: controller
              )
            ),
          ],
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'Tab 1 of 2',
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              label: 'TAB1\nTab 1 of 2',
              flags: <SemanticsFlag>[SemanticsFlag.isFocusable, SemanticsFlag.isSelected],
              id: 2,
              rect: TestSemantics.fullScreen,
              actions: 1,
            ),
            TestSemantics(
              label: 'TAB2\nTab 2 of 2',
              flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
              id: 3,
              rect: TestSemantics.fullScreen,
              actions: <SemanticsAction>[SemanticsAction.tap],
            ),
            TestSemantics(
              id: 4,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                  id: 6,
                  rect: TestSemantics.fullScreen,
                  actions: <SemanticsAction>[SemanticsAction.scrollLeft],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 5,
                      rect: TestSemantics.fullScreen,
                      label: 'PAGE1'
                    ),
                  ]
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Change the TabController should make both TabBar and TabBarView return to the initial index.', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/93237

    Widget buildFrame(TabController controller, {required bool showLast}) {
      return boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              tabs: <Tab>[
                const Tab(text: 'one'),
                const Tab(text: 'two'),
                if (showLast) const Tab(text: 'three'),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: controller,
                children: <Widget>[
                  const Text('PAGE1'),
                  const Text('PAGE2'),
                  if (showLast) const Text('PAGE3'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final TabController controller1 = TabController(
      vsync: const TestVSync(),
      length: 3,
    );

    final TabController controller2 = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    final TabController controller3 = TabController(
      vsync: const TestVSync(),
      length: 3,
    );

    await tester.pumpWidget(buildFrame(controller1, showLast: true));
    final PageView pageView = tester.widget(find.byType(PageView));
    final PageController pageController = pageView.controller;
    await tester.tap(find.text('three'));
    await tester.pumpAndSettle();
    expect(controller1.index, 2);
    expect(pageController.page, 2);

    // Change TabController from 3 items to 2.
    await tester.pumpWidget(buildFrame(controller2, showLast: false));
    await tester.pumpAndSettle();
    expect(controller2.index, 0);
    expect(pageController.page, 0);

    // Change TabController from 2 items to 3.
    await tester.pumpWidget(buildFrame(controller3, showLast: true));
    await tester.pumpAndSettle();
    expect(controller3.index, 0);
    expect(pageController.page, 0);

    await tester.tap(find.text('three'));
    await tester.pumpAndSettle();

    expect(controller3.index, 2);
    expect(pageController.page, 2);
  });

  testWidgets('Do not crash when the new TabController.index is longer than the old length.', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/97441

    Widget buildFrame(TabController controller, {required bool showLast}) {
      return boilerplate(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: controller,
              tabs: <Tab>[
                const Tab(text: 'one'),
                const Tab(text: 'two'),
                if (showLast) const Tab(text: 'three'),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: controller,
                children: <Widget>[
                  const Text('PAGE1'),
                  const Text('PAGE2'),
                  if (showLast) const Text('PAGE3'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final TabController controller1 = TabController(
      vsync: const TestVSync(),
      length: 3,
    );

    final TabController controller2 = TabController(
      vsync: const TestVSync(),
      length: 2,
    );

    await tester.pumpWidget(buildFrame(controller1, showLast: true));
    PageView pageView = tester.widget(find.byType(PageView));
    PageController pageController = pageView.controller;
    await tester.tap(find.text('three'));
    await tester.pumpAndSettle();
    expect(controller1.index, 2);
    expect(pageController.page, 2);

    // Change TabController from controller1 to controller2.
    await tester.pumpWidget(buildFrame(controller2, showLast: false));
    await tester.pumpAndSettle();
    pageView = tester.widget(find.byType(PageView));
    pageController = pageView.controller;
    expect(controller2.index, 0);
    expect(pageController.page, 0);

    // Change TabController back to 'controller1' whose index is 2.
    await tester.pumpWidget(buildFrame(controller1, showLast: true));
    await tester.pumpAndSettle();
    pageView = tester.widget(find.byType(PageView));
    pageController = pageView.controller;
    expect(controller1.index, 2);
    expect(pageController.page, 2);
  });

  testWidgets('TabBar InkWell splashFactory and overlayColor', (WidgetTester tester) async {
    const InteractiveInkFeatureFactory splashFactory = NoSplash.splashFactory;
    final MaterialStateProperty<Color?> overlayColor = MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) => Colors.transparent,
    );

    // TabBarTheme splashFactory and overlayColor
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          tabBarTheme: TabBarTheme(
            splashFactory: splashFactory,
            overlayColor: overlayColor,
          )),
        home: DefaultTabController(
          length: 1,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabs: <Widget>[
                  Container(width: 100, height: 100, color: Colors.green),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).splashFactory, splashFactory);
    expect(tester.widget<InkWell>(find.byType(InkWell)).overlayColor, overlayColor);

    // TabBar splashFactory and overlayColor
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 1,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                splashFactory: splashFactory,
                overlayColor: overlayColor,
                tabs: <Widget>[
                  Container(width: 100, height: 100, color: Colors.green),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(); // theme animation
    expect(tester.widget<InkWell>(find.byType(InkWell)).splashFactory, splashFactory);
    expect(tester.widget<InkWell>(find.byType(InkWell)).overlayColor, overlayColor);
  });

  testWidgets('splashBorderRadius is passed to InkWell.borderRadius', (WidgetTester tester) async {
    const Color hoverColor = Color(0xfff44336);
    const double radius = 20;
    await tester.pumpWidget(
      boilerplate(
        child: DefaultTabController(
          length: 1,
          child: TabBar(
            overlayColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return hoverColor;
                }
                return Colors.black54;
              },
            ),
            splashBorderRadius: BorderRadius.circular(radius),
            tabs: const <Widget>[
              Tab(
                child: Text(''),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.moveTo(tester.getCenter(find.byType(Tab)));
    await tester.pumpAndSettle();
    final RenderObject object = tester.allRenderObjects.firstWhere((RenderObject element) => element.runtimeType.toString() == '_RenderInkFeatures');
    expect(
      object,
      paints..rrect(
        color: hoverColor,
        rrect: RRect.fromRectAndRadius(
          tester.getRect(find.byType(InkWell)),
          const Radius.circular(radius)
        ),
      ),
    );
    gesture.removePointer();
  });
}

class KeepAliveInk extends StatefulWidget {
  const KeepAliveInk(this.title, {Key? key}) : super(key: key);
  final String title;
  @override
  State<StatefulWidget> createState() {
    return _KeepAliveInkState();
  }
}

class _KeepAliveInkState extends State<KeepAliveInk> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Ink(
      child: Text(widget.title),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class TabBarDemo extends StatelessWidget {
  const TabBarDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.directions_car)),
                Tab(icon: Icon(Icons.directions_transit)),
                Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: const TabBarView(
            children: <Widget>[
              Icon(Icons.directions_car),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
            ],
          ),
        ),
      ),
    );
  }
}

class MockScrollMetrics extends Fake implements ScrollMetrics { }

class TabBody extends StatefulWidget {
  const TabBody({ Key? key, required this.index, required this.log }) : super(key: key);

  final int index;
  final List<String> log;

  @override
  State<TabBody> createState() => TabBodyState();
}

class TabBodyState extends State<TabBody> {
  @override
  void initState() {
    widget.log.add('init: ${widget.index}');
    super.initState();
  }

  @override
  void didUpdateWidget(TabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // To keep the logging straight, widgets must not change their index.
    assert(oldWidget.index == widget.index);
  }

  @override
  void dispose() {
    widget.log.add('dispose: ${widget.index}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('${widget.index}'),
    );
  }
}
