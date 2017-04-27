// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTest() {
  return new MediaQuery(
    data: const MediaQueryData(),
    child: new Scaffold(
      body: new DefaultTabController(
        length: 4,
        child: new NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              new SliverAppBar(
                title: const Text('TTTTTTTT'),
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
}