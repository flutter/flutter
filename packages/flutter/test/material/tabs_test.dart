// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StateMarker extends StatefulWidget {
  StateMarker({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  StateMarkerState createState() => new StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String marker;

  @override
  Widget build(BuildContext context) {
    if (config.child != null)
      return config.child;
    return new Container();
  }
}

Widget buildFrame({ List<String> tabs, String value, bool isScrollable: false, Key tabBarKey }) {
  return new Material(
    child: new TabBarSelection<String>(
      value: value,
      values: tabs,
      child: new TabBar<String>(
        key: tabBarKey,
        labels: new Map<String, TabLabel>.fromIterable(tabs, value: (String tab) => new TabLabel(text: tab)),
        isScrollable: isScrollable
      )
    )
  );
}


Widget buildLeftRightApp({ List<String> tabs, String value }) {
  return new MaterialApp(
    theme: new ThemeData(platform: TargetPlatform.android),
    home: new TabBarSelection<String>(
      value: value,
      values: tabs,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('tabs'),
          bottom: new TabBar<String>(
            labels: new Map<String, TabLabel>.fromIterable(tabs, value: (String tab) => new TabLabel(text: tab)),
          )
        ),
        body: new TabBarView<String>(
          children: <Widget>[
            new Center(child: new Text('LEFT CHILD')),
            new Center(child: new Text('RIGHT CHILD'))
          ]
        )
      )
    )
  );
}

void main() {
  testWidgets('TabBar tap selects tab', (WidgetTester tester) async {
    List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    TabBarSelectionState<String> selection = TabBarSelection.of(tester.element(find.text('A')));
    expect(selection, isNotNull);
    expect(selection.indexOf('A'), equals(0));
    expect(selection.indexOf('B'), equals(1));
    expect(selection.indexOf('C'), equals(2));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(selection.index, equals(2));
    expect(selection.previousIndex, equals(2));
    expect(selection.value, equals('C'));
    expect(selection.previousValue, equals('C'));

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C' ,isScrollable: false));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(selection.valueIsChanging, true);
    await tester.pump(const Duration(seconds: 1)); // finish the animation
    expect(selection.valueIsChanging, false);
    expect(selection.value, equals('B'));
    expect(selection.previousValue, equals('C'));
    expect(selection.index, equals(1));
    expect(selection.previousIndex, equals(2));

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(selection.value, equals('C'));
    expect(selection.previousValue, equals('B'));
    expect(selection.index, equals(2));
    expect(selection.previousIndex, equals(1));

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(selection.value, equals('A'));
    expect(selection.previousValue, equals('C'));
    expect(selection.index, equals(0));
    expect(selection.previousIndex, equals(2));
  });

  testWidgets('Scrollable TabBar tap selects tab', (WidgetTester tester) async {
    List<String> tabs = <String>['A', 'B', 'C'];

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
    TabBarSelectionState<String> selection = TabBarSelection.of(tester.element(find.text('A')));
    expect(selection, isNotNull);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(selection.value, equals('C'));

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(selection.value, equals('B'));

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(selection.value, equals('C'));

    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(selection.value, equals('A'));
  });

  testWidgets('Scrollable TabBar tap centers selected tab', (WidgetTester tester) async {
    List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
    Key tabBarKey = new Key('TabBar');
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAAAA', isScrollable: true, tabBarKey: tabBarKey));
    TabBarSelectionState<String> selection = TabBarSelection.of(tester.element(find.text('AAAAAA')));
    expect(selection, isNotNull);
    expect(selection.value, equals('AAAAAA'));

    expect(tester.getSize(find.byKey(tabBarKey)).width, equals(800.0));
    // The center of the FFFFFF item is to the right of the TabBar's center
    expect(tester.getCenter(find.text('FFFFFF')).x, greaterThan(401.0));

    await tester.tap(find.text('FFFFFF'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(selection.value, equals('FFFFFF'));
    // The center of the FFFFFF item is now at the TabBar's center
    expect(tester.getCenter(find.text('FFFFFF')).x, closeTo(400.0, 1.0));
  });


  testWidgets('TabBar can be scrolled independent of the selection', (WidgetTester tester) async {
    List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
    Key tabBarKey = new Key('TabBar');
    await tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAAAA', isScrollable: true, tabBarKey: tabBarKey));
    TabBarSelectionState<String> selection = TabBarSelection.of(tester.element(find.text('AAAAAA')));
    expect(selection, isNotNull);
    expect(selection.value, equals('AAAAAA'));

    // Fling-scroll the TabBar to the left
    expect(tester.getCenter(find.text('HHHHHH')).x, lessThan(700.0));
    await tester.fling(find.byKey(tabBarKey), const Offset(-200.0, 0.0), 10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(tester.getCenter(find.text('HHHHHH')).x, lessThan(500.0));

    // Scrolling the TabBar doesn't change the selection
    expect(selection.value, equals('AAAAAA'));
  });

  testWidgets('TabView maintains state', (WidgetTester tester) async {
    List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE'];
    String value = tabs[0];

    void onTabSelectionChanged(String newValue) {
      value = newValue;
    }

    Widget builder() {
      return new Material(
        child: new TabBarSelection<String>(
          value: value,
          values: tabs,
          onChanged: onTabSelectionChanged,
          child: new TabBarView<String>(
            children: tabs.map((String name) {
              return new StateMarker(
                child: new Text(name)
              );
            }).toList()
          )
        )
      );
    }

    StateMarkerState findStateMarkerState(String name) {
      return tester.state(find.widgetWithText(StateMarker, name));
    }

    await tester.pumpWidget(builder());
    TestGesture gesture = await tester.startGesture(tester.getCenter(find.text(tabs[0])));
    await gesture.moveBy(new Offset(-600.0, 0.0));
    await tester.pump();
    expect(value, equals(tabs[0]));
    findStateMarkerState(tabs[1]).marker = 'marked';
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(value, equals(tabs[1]));
    await tester.pumpWidget(builder());
    expect(findStateMarkerState(tabs[1]).marker, equals('marked'));

    // Move to the third tab.

    gesture = await tester.startGesture(tester.getCenter(find.text(tabs[1])));
    await gesture.moveBy(new Offset(-600.0, 0.0));
    await gesture.up();
    await tester.pump();
    expect(findStateMarkerState(tabs[1]).marker, equals('marked'));
    await tester.pump(const Duration(seconds: 1));
    expect(value, equals(tabs[2]));
    await tester.pumpWidget(builder());

    // The state is now gone.

    expect(find.text(tabs[1]), findsNothing);

    // Move back to the second tab.

    gesture = await tester.startGesture(tester.getCenter(find.text(tabs[2])));
    await gesture.moveBy(new Offset(600.0, 0.0));
    await tester.pump();
    StateMarkerState markerState = findStateMarkerState(tabs[1]);
    expect(markerState.marker, isNull);
    markerState.marker = 'marked';
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(value, equals(tabs[1]));
    await tester.pumpWidget(builder());
    expect(findStateMarkerState(tabs[1]).marker, equals('marked'));
  });

  testWidgets('TabBar left/right fling', (WidgetTester tester) async {
    List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    TabBarSelectionState<String> selection = TabBarSelection.of(tester.element(find.text('LEFT')));
    expect(selection.value, equals('LEFT'));

    // Fling to the left, switch from the 'LEFT' tab to the 'RIGHT'
    Point flingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(flingStart, new Offset(-200.0, 0.0), 10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(selection.value, equals('RIGHT'));
    expect(find.text('LEFT CHILD'), findsNothing);
    expect(find.text('RIGHT CHILD'), findsOneWidget);

    // Fling to the right, switch back to the 'LEFT' tab
    flingStart = tester.getCenter(find.text('RIGHT CHILD'));
    await tester.flingFrom(flingStart, new Offset(200.0, 0.0), 10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(selection.value, equals('LEFT'));
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);
  });

  // A regression test for https://github.com/flutter/flutter/issues/5095
  testWidgets('TabBar left/right fling reverse', (WidgetTester tester) async {
    List<String> tabs = <String>['LEFT', 'RIGHT'];

    await tester.pumpWidget(buildLeftRightApp(tabs: tabs, value: 'LEFT'));
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);

    TabBarSelectionState<String> selection = TabBarSelection.of(tester.element(find.text('LEFT')));
    expect(selection.value, equals('LEFT'));

    // End the fling by reversing direction. This should cause not cause
    // a change to the selected tab, everything should just settle back to
    // to where it started.
    Point flingStart = tester.getCenter(find.text('LEFT CHILD'));
    await tester.flingFrom(flingStart, new Offset(-200.0, 0.0), -10000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(selection.value, equals('LEFT'));
    expect(find.text('LEFT CHILD'), findsOneWidget);
    expect(find.text('RIGHT CHILD'), findsNothing);
  });

}
