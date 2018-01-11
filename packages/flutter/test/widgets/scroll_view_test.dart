// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'states.dart';

void main() {
  testWidgets('ListView control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: kStates.map<Widget>((String state) {
            return new GestureDetector(
              onTap: () {
                log.add(state);
              },
              child: new Container(
                height: 200.0,
                color: const Color(0xFF0000FF),
                child: new Text(state),
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
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: kStates.take(n).map<Widget>((String state) {
            return new Container(
              height: 200.0,
              color: const Color(0xFF0000FF),
              child: new Text(state),
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new CustomScrollView(
          slivers: <Widget>[
            new SliverList(
              delegate: new SliverChildListDelegate(
                kStates.map<Widget>((String state) {
                  return new GestureDetector(
                    onTap: () {
                      log.add(state);
                    },
                    child: new Container(
                      height: 200.0,
                      color: const Color(0xFF0000FF),
                      child: new Text(state),
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
    final ScrollController controller = new ScrollController();

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            log.add(notification.runtimeType);
            return false;
          },
          child: new ListView(
            controller: controller,
            children: kStates.map<Widget>((String state) {
              return new Container(
                height: 200.0,
                child: new Text(state),
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
    final CustomScrollView view = new CustomScrollView(scrollDirection: Axis.vertical);
    expect(view.primary, isTrue);
  });

  testWidgets('Vertical ListViews are primary by default', (WidgetTester tester) async {
    final ListView view = new ListView(scrollDirection: Axis.vertical);
    expect(view.primary, isTrue);
  });

  testWidgets('Vertical GridViews are primary by default', (WidgetTester tester) async {
    final GridView view = new GridView.count(
      scrollDirection: Axis.vertical,
      crossAxisCount: 1,
    );
    expect(view.primary, isTrue);
  });

  testWidgets('Horizontal CustomScrollViews are non-primary by default', (WidgetTester tester) async {
    final CustomScrollView view = new CustomScrollView(scrollDirection: Axis.horizontal);
    expect(view.primary, isFalse);
  });

  testWidgets('Horizontal ListViews are non-primary by default', (WidgetTester tester) async {
    final ListView view = new ListView(scrollDirection: Axis.horizontal);
    expect(view.primary, isFalse);
  });

  testWidgets('Horizontal GridViews are non-primary by default', (WidgetTester tester) async {
    final GridView view = new GridView.count(
      scrollDirection: Axis.horizontal,
      crossAxisCount: 1,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('CustomScrollViews with controllers are non-primary by default', (WidgetTester tester) async {
    final CustomScrollView view = new CustomScrollView(
      controller: new ScrollController(),
      scrollDirection: Axis.vertical,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('ListViews with controllers are non-primary by default', (WidgetTester tester) async {
    final ListView view = new ListView(
      controller: new ScrollController(),
      scrollDirection: Axis.vertical,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('GridViews with controllers are non-primary by default', (WidgetTester tester) async {
    final GridView view = new GridView.count(
      controller: new ScrollController(),
      scrollDirection: Axis.vertical,
      crossAxisCount: 1,
    );
    expect(view.primary, isFalse);
  });

  testWidgets('CustomScrollView sets PrimaryScrollController when primary', (WidgetTester tester) async {
    final ScrollController primaryScrollController = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new PrimaryScrollController(
          controller: primaryScrollController,
          child: new CustomScrollView(primary: true),
        ),
      ),
    );
    final Scrollable scrollable = tester.widget(find.byType(Scrollable));
    expect(scrollable.controller, primaryScrollController);
  });

  testWidgets('ListView sets PrimaryScrollController when primary', (WidgetTester tester) async {
    final ScrollController primaryScrollController = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new PrimaryScrollController(
          controller: primaryScrollController,
          child: new ListView(primary: true),
        ),
      ),
    );
    final Scrollable scrollable = tester.widget(find.byType(Scrollable));
    expect(scrollable.controller, primaryScrollController);
  });

  testWidgets('GridView sets PrimaryScrollController when primary', (WidgetTester tester) async {
    final ScrollController primaryScrollController = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new PrimaryScrollController(
          controller: primaryScrollController,
          child: new GridView.count(primary: true, crossAxisCount: 1),
        ),
      ),
    );
    final Scrollable scrollable = tester.widget(find.byType(Scrollable));
    expect(scrollable.controller, primaryScrollController);
  });

  testWidgets('Nested scrollables have a null PrimaryScrollController', (WidgetTester tester) async {
    const Key innerKey = const Key('inner');
    final ScrollController primaryScrollController = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new PrimaryScrollController(
          controller: primaryScrollController,
          child: new ListView(
            primary: true,
            children: <Widget>[
              new Container(
                constraints: const BoxConstraints(maxHeight: 200.0),
                child: new ListView(key: innerKey, primary: true),
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
    final ListView view = new ListView(primary: true);
    expect(view.physics, const isInstanceOf<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('Non-primary ListViews are not always scrollable', (WidgetTester tester) async {
    final ListView view = new ListView(primary: false);
    expect(view.physics, isNot(const isInstanceOf<AlwaysScrollableScrollPhysics>()));
  });

  testWidgets('Defaulting-to-primary ListViews are always scrollable', (WidgetTester tester) async {
    final ListView view = new ListView(scrollDirection: Axis.vertical);
    expect(view.physics, const isInstanceOf<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('Defaulting-to-not-primary ListViews are not always scrollable', (WidgetTester tester) async {
    final ListView view = new ListView(scrollDirection: Axis.horizontal);
    expect(view.physics, isNot(const isInstanceOf<AlwaysScrollableScrollPhysics>()));
  });

  testWidgets('primary:true leads to scrolling', (WidgetTester tester) async {
    bool scrolled = false;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: new ListView(
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: new ListView(
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: new ListView(
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new NotificationListener<OverscrollNotification>(
          onNotification: (OverscrollNotification message) { scrolled = true; return false; },
          child: new ListView(
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
}
