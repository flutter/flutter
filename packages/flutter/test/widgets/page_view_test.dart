// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'states.dart';

const Duration _frameDuration = const Duration(milliseconds: 100);

void main() {
  testWidgets('PageView control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(new PageView(
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
    ));

    await tester.tap(find.text('Alabama'));
    expect(log, equals(<String>['Alabama']));
    log.clear();

    expect(find.text('Alaska'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-10.0, 0.0));
    await tester.pump();

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    await tester.pumpAndSettle(_frameDuration);

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-401.0, 0.0));
    await tester.pumpAndSettle(_frameDuration);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    await tester.tap(find.text('Alaska'));
    expect(log, equals(<String>['Alaska']));
    log.clear();

    await tester.fling(find.byType(PageView), const Offset(-200.0, 0.0), 1000.0);
    await tester.pumpAndSettle(_frameDuration);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsNothing);
    expect(find.text('Arizona'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(200.0, 0.0), 1000.0);
    await tester.pumpAndSettle(_frameDuration);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);
  });

  testWidgets('PageView does not squish when overscrolled',
      (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      theme: new ThemeData(platform: TargetPlatform.iOS),
      home: new PageView(
        children: new List<Widget>.generate(10, (int i) {
          return new Container(
            key: new ValueKey<int>(i),
            color: const Color(0xFF0000FF),
          );
        }),
      ),
    ));

    Size sizeOf(int i) => tester.getSize(find.byKey(new ValueKey<int>(i)));
    double leftOf(int i) => tester.getTopLeft(find.byKey(new ValueKey<int>(i))).dx;

    expect(leftOf(0), equals(0.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));

    await tester.drag(find.byType(PageView), const Offset(100.0, 0.0));
    await tester.pump();

    expect(leftOf(0), equals(100.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));

    await tester.drag(find.byType(PageView), const Offset(-200.0, 0.0));
    await tester.pump();

    expect(leftOf(0), equals(-100.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));
  });

  testWidgets('PageController control test', (WidgetTester tester) async {
    final PageController controller = new PageController(initialPage: 4);

    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 600.0,
        height: 400.0,
        child: new PageView(
          controller: controller,
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('California'), findsOneWidget);

    controller.nextPage(duration: const Duration(milliseconds: 150), curve: Curves.ease);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Colorado'), findsOneWidget);

    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 300.0,
        height: 400.0,
        child: new PageView(
          controller: controller,
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('Colorado'), findsOneWidget);

    controller.previousPage(duration: const Duration(milliseconds: 150), curve: Curves.ease);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('California'), findsOneWidget);
  });

  testWidgets('PageController page stability', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 600.0,
        height: 400.0,
        child: new PageView(
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('Alabama'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-1250.0, 0.0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Arizona'), findsOneWidget);

    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 250.0,
        height: 100.0,
        child: new PageView(
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('Arizona'), findsOneWidget);

    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 450.0,
        height: 400.0,
        child: new PageView(
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('Arizona'), findsOneWidget);
  });

  testWidgets('PageView in zero-size container', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 0.0,
        height: 0.0,
        child: new PageView(
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('Alabama'), findsOneWidget);

    await tester.pumpWidget(new Center(
      child: new SizedBox(
        width: 200.0,
        height: 200.0,
        child: new PageView(
          children: kStates.map<Widget>((String state) => new Text(state)).toList(),
        ),
      ),
    ));

    expect(find.text('Alabama'), findsOneWidget);
  });

  testWidgets('Page changes at halfway point', (WidgetTester tester) async {
    final List<int> log = <int>[];
    await tester.pumpWidget(new PageView(
      onPageChanged: log.add,
      children: kStates.map<Widget>((String state) => new Text(state)).toList(),
    ));

    expect(log, isEmpty);

    final TestGesture gesture =
        await tester.startGesture(const Offset(100.0, 100.0));
    // The page view is 800.0 wide, so this move is just short of halfway.
    await gesture.moveBy(const Offset(-380.0, 0.0));

    expect(log, isEmpty);

    // We've crossed the halfway mark.
    await gesture.moveBy(const Offset(-40.0, 0.0));

    expect(log, equals(const <int>[1]));
    log.clear();

    // Moving a bit more should not generate redundant notifications.
    await gesture.moveBy(const Offset(-40.0, 0.0));

    expect(log, isEmpty);

    await gesture.moveBy(const Offset(-40.0, 0.0));
    await tester.pump();

    await gesture.moveBy(const Offset(-40.0, 0.0));
    await tester.pump();

    await gesture.moveBy(const Offset(-40.0, 0.0));
    await tester.pump();

    expect(log, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(log, isEmpty);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
  });

  testWidgets('PageView viewportFraction', (WidgetTester tester) async {
    PageController controller = new PageController(viewportFraction: 7/8);

    Widget build(PageController controller) {
      return new PageView.builder(
        controller: controller,
        itemCount: kStates.length,
        itemBuilder: (BuildContext context, int index) {
          return new Container(
            height: 200.0,
            color: index % 2 == 0
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00),
            child: new Text(kStates[index]),
          );
        },
      );
    }

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Alabama')), const Offset(50.0, 0.0));
    expect(tester.getTopLeft(find.text('Alaska')), const Offset(750.0, 0.0));

    controller.jumpToPage(10);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Georgia')), const Offset(-650.0, 0.0));
    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(50.0, 0.0));
    expect(tester.getTopLeft(find.text('Idaho')), const Offset(750.0, 0.0));

    controller = new PageController(viewportFraction: 39/40);

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Georgia')), const Offset(-770.0, 0.0));
    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(10.0, 0.0));
    expect(tester.getTopLeft(find.text('Idaho')), const Offset(790.0, 0.0));
  });

  testWidgets('PageView small viewportFraction', (WidgetTester tester) async {
    final PageController controller = new PageController(viewportFraction: 1/8);

    Widget build(PageController controller) {
      return new PageView.builder(
        controller: controller,
        itemCount: kStates.length,
        itemBuilder: (BuildContext context, int index) {
          return new Container(
            height: 200.0,
            color: index % 2 == 0
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00),
            child: new Text(kStates[index]),
          );
        },
      );
    }

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Alabama')), const Offset(350.0, 0.0));
    expect(tester.getTopLeft(find.text('Alaska')), const Offset(450.0, 0.0));
    expect(tester.getTopLeft(find.text('Arizona')), const Offset(550.0, 0.0));
    expect(tester.getTopLeft(find.text('Arkansas')), const Offset(650.0, 0.0));
    expect(tester.getTopLeft(find.text('California')), const Offset(750.0, 0.0));

    controller.jumpToPage(10);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Connecticut')), const Offset(-50.0, 0.0));
    expect(tester.getTopLeft(find.text('Delaware')), const Offset(50.0, 0.0));
    expect(tester.getTopLeft(find.text('Florida')), const Offset(150.0, 0.0));
    expect(tester.getTopLeft(find.text('Georgia')), const Offset(250.0, 0.0));
    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(350.0, 0.0));
    expect(tester.getTopLeft(find.text('Idaho')), const Offset(450.0, 0.0));
    expect(tester.getTopLeft(find.text('Illinois')), const Offset(550.0, 0.0));
    expect(tester.getTopLeft(find.text('Indiana')), const Offset(650.0, 0.0));
    expect(tester.getTopLeft(find.text('Iowa')), const Offset(750.0, 0.0));
  });

  testWidgets('PageView large viewportFraction', (WidgetTester tester) async {
    final PageController controller =
        new PageController(viewportFraction: 5/4);

    Widget build(PageController controller) {
      return new PageView.builder(
        controller: controller,
        itemCount: kStates.length,
        itemBuilder: (BuildContext context, int index) {
          return new Container(
            height: 200.0,
            color: index % 2 == 0
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00),
            child: new Text(kStates[index]),
          );
        },
      );
    }

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Alabama')), const Offset(-100.0, 0.0));
    expect(tester.getBottomRight(find.text('Alabama')), const Offset(900.0, 600.0));

    controller.jumpToPage(10);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(-100.0, 0.0));
  });

  testWidgets('PageView does not report page changed on overscroll',
      (WidgetTester tester) async {
    final PageController controller = new PageController(
      initialPage: kStates.length - 1,
    );
    int changeIndex = 0;
    Widget build() {
      return new PageView(
        children:
            kStates.map<Widget>((String state) => new Text(state)).toList(),
        controller: controller,
        onPageChanged: (int page) {
          changeIndex = page;
        },
      );
    }

    await tester.pumpWidget(build());
    controller.jumpToPage(kStates.length * 2); // try to move beyond max range
    // change index should be zero, shouldn't fire onPageChanged
    expect(changeIndex, 0);
    await tester.pump();
    expect(changeIndex, 0);
  });

  testWidgets('PageView can restore page',
      (WidgetTester tester) async {
    final PageController controller = new PageController();
    final PageStorageBucket bucket = new PageStorageBucket();
    await tester.pumpWidget(
      new PageStorage(
        bucket: bucket,
        child: new PageView(
          controller: controller,
          children: <Widget>[
            const Placeholder(),
            const Placeholder(),
            const Placeholder(),
          ],
        ),
      ),
    );
    expect(controller.page, 0);
    controller.jumpToPage(2);
    expect(await tester.pumpAndSettle(const Duration(minutes: 1)), 1);
    expect(controller.page, 2);
    await tester.pumpWidget(
      new PageStorage(
        bucket: bucket,
        child: new Container(),
      ),
    );
    expect(() => controller.page, throwsAssertionError);
    await tester.pumpWidget(
      new PageStorage(
        bucket: bucket,
        child: new PageView(
          controller: controller,
          children: <Widget>[
            const Placeholder(),
            const Placeholder(),
            const Placeholder(),
          ],
        ),
      ),
    );
    expect(controller.page, 2);
    await tester.pumpWidget(
      new PageStorage(
        bucket: bucket,
        child: new PageView(
          key: const Key('Check it again against your list and see consistency!'),
          controller: controller,
          children: <Widget>[
            const Placeholder(),
            const Placeholder(),
            const Placeholder(),
          ],
        ),
      ),
    );
    expect(controller.page, 0);
  });
}
