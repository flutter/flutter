// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

import 'states.dart';

void main() {
  testWidgets('ListView control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: kStates.map<Widget>((String state) {
            return GestureDetector(
              onTap: () {
                log.add(state);
              },
              child: Container(
                height: 200.0,
                color: const Color(0xFF0000FF),
                child: Text(state),
              ),
            );
          }).toList(),
        ),
      ),
    );

    await tester.tap(find.text('Alabama'));
    expect(log, equals(<String>['Alabama']));
    log.clear();

    expect(find.text('Nevada'), findsNothing);

    await tester.drag(find.text('Alabama'), const Offset(0.0, -4000.0));
    await tester.pump();

    expect(find.text('Alabama'), findsNothing);
    expect(tester.getCenter(find.text('Massachusetts')), equals(const Offset(400.0, 100.0)));

    await tester.tap(find.text('Massachusetts'));
    expect(log, equals(<String>['Massachusetts']));
    log.clear();
  });

  testWidgets('ListView restart ballistic activity out of range', (WidgetTester tester) async {
    Widget buildListView(int n) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: kStates.take(n).map<Widget>((String state) {
            return Container(
              height: 200.0,
              color: const Color(0xFF0000FF),
              child: Text(state),
            );
          }).toList(),
        ),
      );
    }

    await tester.pumpWidget(buildListView(30));
    await tester.fling(find.byType(ListView), const Offset(0.0, -4000.0), 4000.0);
    await tester.pumpWidget(buildListView(15));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final Viewport viewport = tester.widget(find.byType(Viewport));
    expect(viewport.offset.pixels, equals(2400.0));
  });

  testWidgets('CustomScrollView control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildListDelegate(
                kStates.map<Widget>((String state) {
                  return GestureDetector(
                    onTap: () {
                      log.add(state);
                    },
                    child: Container(
                      height: 200.0,
                      color: const Color(0xFF0000FF),
                      child: Text(state),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Alabama'));
    expect(log, equals(<String>['Alabama']));
    log.clear();

    expect(find.text('Nevada'), findsNothing);

    await tester.drag(find.text('Alabama'), const Offset(0.0, -4000.0));
    await tester.pump();

    expect(find.text('Alabama'), findsNothing);
    expect(tester.getCenter(find.text('Massachusetts')), equals(const Offset(400.0, 100.0)));

    await tester.tap(find.text('Massachusetts'));
    expect(log, equals(<String>['Massachusetts']));
    log.clear();
  });

  testWidgets('Can jumpTo during drag', (WidgetTester tester) async {
    final List<Type> log = <Type>[];
    final ScrollController controller = ScrollController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            log.add(notification.runtimeType);
            return false;
          },
          child: ListView(
            controller: controller,
            children: kStates.map<Widget>((String state) {
              return Container(
                height: 200.0,
                child: Text(state),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(log, isEmpty);

    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await gesture.moveBy(const Offset(0.0, -100.0));

    expect(log, equals(<Type>[
      ScrollStartNotification,
      UserScrollNotification,
      ScrollUpdateNotification,
    ]));
    log.clear();

    await tester.pump();

    controller.jumpTo(550.0);

    expect(controller.offset, equals(550.0));
    expect(log, equals(<Type>[
      ScrollEndNotification,
      UserScrollNotification,
      ScrollStartNotification,
      ScrollUpdateNotification,
      ScrollEndNotification,
    ]));
    log.clear();

    await tester.pump();
    await gesture.moveBy(const Offset(0.0, -100.0));

    expect(controller.offset, equals(550.0));
    expect(log, isEmpty);
  });

  testWidgets('Vertical CustomScrollViews are primary by default', (WidgetTester tester) async {
    const CustomScrollView view = CustomScrollView(scrollDirection: Axis.vertical);
    expect(view.primary, isTrue);
  });

  testWidgets('Vertical ListViews are primary by default', (WidgetTester tester) async {
    final ListView view = ListView(scrollDirection: Axis.vertical);
    expect(view.primary, isTrue);
  });

  testWidgets('Vertical GridViews are primary by default', (WidgetTester tester) async {
    final GridView view = GridView.count(
      scrollDirection: Axis.vertical,
      crossAxisCount: 1,
    );
    expect(view.primary, isTrue);
  });

  testWidgets('Horizontal CustomScrollViews are non-primary by default', (WidgetTester tester) async {
    const CustomScrollView view = CustomScrollView(scrollDirection: Axis.horizontal);
    expect(view.primary, isFalse);
  });

  testWidgets('Horizontal ListViews are non-primary by default', (WidgetTester tester) async {
    final ListView view = ListView(scrollDirection: Axis.horizontal);
    expect(view.primary, isFalse);
  });

  testWidgets('Horizontal GridViews are non-primary by default', (WidgetTester tester) async {
    final GridView view = GridView.count(
      scrollDirection: Axis.horizontal,
      crossAxisCount: 1,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('CustomScrollViews with controllers are non-primary by default', (WidgetTester tester) async {
    final CustomScrollView view = CustomScrollView(
      controller: ScrollController(),
      scrollDirection: Axis.vertical,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('ListViews with controllers are non-primary by default', (WidgetTester tester) async {
    final ListView view = ListView(
      controller: ScrollController(),
      scrollDirection: Axis.vertical,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('GridViews with controllers are non-primary by default', (WidgetTester tester) async {
    final GridView view = GridView.count(
      controller: ScrollController(),
      scrollDirection: Axis.vertical,
      crossAxisCount: 1,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('CustomScrollView sets PrimaryScrollController when primary', (WidgetTester tester) async {
    final ScrollController primaryScrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PrimaryScrollController(
          controller: primaryScrollController,
          child: const CustomScrollView(primary: true),
        ),
      ),
    );
    final Scrollable scrollable = tester.widget(find.byType(Scrollable));
    expect(scrollable.controller, primaryScrollController);
  });

  testWidgets('ListView sets PrimaryScrollController when primary', (WidgetTester tester) async {
    final ScrollController primaryScrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PrimaryScrollController(
          controller: primaryScrollController,
          child: ListView(primary: true),
        ),
      ),
    );
    final Scrollable scrollable = tester.widget(find.byType(Scrollable));
    expect(scrollable.controller, primaryScrollController);
  });

  testWidgets('GridView sets PrimaryScrollController when primary', (WidgetTester tester) async {
    final ScrollController primaryScrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PrimaryScrollController(
          controller: primaryScrollController,
          child: GridView.count(primary: true, crossAxisCount: 1),
        ),
      ),
    );
    final Scrollable scrollable = tester.widget(find.byType(Scrollable));
    expect(scrollable.controller, primaryScrollController);
  });

  testWidgets('Nested scrollables have a null PrimaryScrollController', (WidgetTester tester) async {
    const Key innerKey = Key('inner');
    final ScrollController primaryScrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PrimaryScrollController(
          controller: primaryScrollController,
          child: ListView(
            primary: true,
            children: <Widget>[
              Container(
                constraints: const BoxConstraints(maxHeight: 200.0),
                child: ListView(key: innerKey, primary: true),
              ),
            ],
          ),
        ),
      ),
    );

    final Scrollable innerScrollable = tester.widget(
      find.descendant(
        of: find.byKey(innerKey),
        matching: find.byType(Scrollable),
      ),
    );
    expect(innerScrollable.controller, isNull);
  });

  testWidgets('Primary ListViews are always scrollable', (WidgetTester tester) async {
    final ListView view = ListView(primary: true);
    expect(view.physics, isInstanceOf<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('Non-primary ListViews are not always scrollable', (WidgetTester tester) async {
    final ListView view = ListView(primary: false);
    expect(view.physics, isNot(isInstanceOf<AlwaysScrollableScrollPhysics>()));
  });

  testWidgets('Defaulting-to-primary ListViews are always scrollable', (WidgetTester tester) async {
    final ListView view = ListView(scrollDirection: Axis.vertical);
    expect(view.physics, isInstanceOf<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('Defaulting-to-not-primary ListViews are not always scrollable', (WidgetTester tester) async {
    final ListView view = ListView(scrollDirection: Axis.horizontal);
    expect(view.physics, isNot(isInstanceOf<AlwaysScrollableScrollPhysics>()));
  });

  testWidgets('primary:true leads to scrolling', (WidgetTester tester) async {
    bool scrolled = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: ListView(
            primary: true,
            children: const <Widget>[],
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(100.0, 100.0), const Offset(0.0, 100.0));
    expect(scrolled, isTrue);
  });

  testWidgets('primary:false leads to no scrolling', (WidgetTester tester) async {
    bool scrolled = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: ListView(
            primary: false,
            children: const <Widget>[],
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(100.0, 100.0), const Offset(0.0, 100.0));
    expect(scrolled, isFalse);
  });

  testWidgets('physics:AlwaysScrollableScrollPhysics actually overrides primary:false default behavior', (WidgetTester tester) async {
    bool scrolled = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: ListView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[],
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(100.0, 100.0), const Offset(0.0, 100.0));
    expect(scrolled, isTrue);
  });

  testWidgets('physics:ScrollPhysics actually overrides primary:true default behavior', (WidgetTester tester) async {
    bool scrolled = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: ListView(
            primary: true,
            physics: const ScrollPhysics(),
            children: const <Widget>[],
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(100.0, 100.0), const Offset(0.0, 100.0));
    expect(scrolled, isFalse);
  });

  testWidgets('separatorBuilder must return something', (WidgetTester tester) async {
    const List<String> listOfValues = <String>['ALPHA', 'BETA', 'GAMMA', 'DELTA'];

    Widget buildFrame(Widget firstSeparator) {
      return MaterialApp(
        home: Material(
          child: ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              return Text(listOfValues[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return firstSeparator;
              } else  {
                return const Divider();
              }
            },
            itemCount: listOfValues.length,
          ),
        ),
      );
    }

    // A separatorBuilder that always returns a Divider is fine
    await tester.pumpWidget(buildFrame(const Divider()));
    expect(tester.takeException(), isNull);

    // A separatorBuilder that returns null throws a FlutterError
    await tester.pumpWidget(buildFrame(null));
    expect(tester.takeException(), isInstanceOf<FlutterError>());
    expect(find.byType(ErrorWidget), findsOneWidget);
  });

  testWidgets('itemBuilder can return null', (WidgetTester tester) async {
    const List<String> listOfValues = <String>['ALPHA', 'BETA', 'GAMMA', 'DELTA'];
    const Key key = Key('list');
    const int RENDER_NULL_AT = 2; // only render the first 2 values

    Widget buildFrame() {
      return MaterialApp(
        home: Material(
          child: ListView.builder(
            key: key,
            itemBuilder: (BuildContext context, int index) {
              if (index == RENDER_NULL_AT) {
                return null;
              }
              return Text(listOfValues[index]);
            },
            itemCount: listOfValues.length,
          ),
        ),
      );
    }

    // The length of a list is itemCount or the index of the first itemBuilder
    // that returns null, whichever is smaller
    await tester.pumpWidget(buildFrame());
    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(Text), findsNWidgets(RENDER_NULL_AT));
  });

  testWidgets('when itemBuilder throws, creates Error Widget', (WidgetTester tester) async {
    const List<String> listOfValues = <String>['ALPHA', 'BETA', 'GAMMA', 'DELTA'];

    Widget buildFrame(bool throwOnFirstItem) {
      return MaterialApp(
        home: Material(
          child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              if (index == 0 && throwOnFirstItem) {
                throw Exception('itemBuilder fail');
              }
              return Text(listOfValues[index]);
            },
            itemCount: listOfValues.length,
          ),
        ),
      );
    }

    // When itemBuilder doesn't throw, no ErrorWidget
    await tester.pumpWidget(buildFrame(false));
    expect(tester.takeException(), isNull);
    final Finder finder = find.byType(ErrorWidget);
    expect(find.byType(ErrorWidget), findsNothing);

    // When it does throw, one error widget is rendered in the item's place
    await tester.pumpWidget(buildFrame(true));
    expect(tester.takeException(), isInstanceOf<Exception>());
    expect(finder, findsOneWidget);
  });

  testWidgets('when separatorBuilder throws, creates ErrorWidget', (WidgetTester tester) async {
    const List<String> listOfValues = <String>['ALPHA', 'BETA', 'GAMMA', 'DELTA'];
    const Key key = Key('list');

    Widget buildFrame(bool throwOnFirstSeparator) {
      return MaterialApp(
        home: Material(
          child: ListView.separated(
            key: key,
            itemBuilder: (BuildContext context, int index) {
              return Text(listOfValues[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              if (index == 0 && throwOnFirstSeparator) {
                throw Exception('separatorBuilder fail');
              }
              return const Divider();
            },
            itemCount: listOfValues.length,
          ),
        ),
      );
    }

    // When separatorBuilder doesn't throw, no ErrorWidget
    await tester.pumpWidget(buildFrame(false));
    expect(tester.takeException(), isNull);
    final Finder finder = find.byType(ErrorWidget);
    expect(find.byType(ErrorWidget), findsNothing);

    // When it does throw, one error widget is rendered in the separator's place
    await tester.pumpWidget(buildFrame(true));
    expect(tester.takeException(), isInstanceOf<Exception>());
    expect(finder, findsOneWidget);
  });
}
