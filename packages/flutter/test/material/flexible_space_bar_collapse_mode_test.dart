// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Key blockKey = new UniqueKey();
const double expandedAppbarHeight = 250.0;
final Key appbarContainerKey = new UniqueKey();

void main() {
  testWidgets('FlexibleSpaceBar collapse mode none on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          body: new CustomScrollView(
            key: blockKey,
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    key: appbarContainerKey,
                  ),
                  collapseMode: CollapseMode.none,
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 10000.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

    expect(topBeforeScroll.dy, equals(0.0));
    expect(topAfterScroll.dy, equals(0.0));
  });

  testWidgets('FlexibleSpaceBar collapse mode none on IOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Scaffold(
          body: new CustomScrollView(
            key: blockKey,
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    key: appbarContainerKey,
                  ),
                  collapseMode: CollapseMode.none,
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 10000.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

    expect(topBeforeScroll.dy, equals(0.0));
    expect(topAfterScroll.dy, equals(0.0));
  });

  testWidgets('FlexibleSpaceBar collapse mode pin on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          body: new CustomScrollView(
            key: blockKey,
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    key: appbarContainerKey,
                  ),
                  collapseMode: CollapseMode.pin,
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 10000.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

    expect(topBeforeScroll.dy, equals(0.0));
    expect(topAfterScroll.dy, equals(-100.0));
  });

  testWidgets('FlexibleSpaceBar collapse mode pin on IOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Scaffold(
          body: new CustomScrollView(
            key: blockKey,
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    key: appbarContainerKey,
                  ),
                  collapseMode: CollapseMode.pin,
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 10000.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

    expect(topBeforeScroll.dy, equals(0.0));
    expect(topAfterScroll.dy, equals(-100.0));
  });



  testWidgets('FlexibleSpaceBar collapse mode parallax on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          body: new CustomScrollView(
            key: blockKey,
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    key: appbarContainerKey,
                  ),
                  collapseMode: CollapseMode.parallax,
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 10000.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

    expect(topBeforeScroll.dy, equals(0.0));
    expect(topAfterScroll.dy, lessThan(10.0));
    expect(topAfterScroll.dy, greaterThan(-50.0));
  });

  testWidgets('FlexibleSpaceBar collapse mode parallax on IOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Scaffold(
          body: new CustomScrollView(
            key: blockKey,
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    key: appbarContainerKey,
                  ),
                  collapseMode: CollapseMode.parallax,
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 10000.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

    expect(topBeforeScroll.dy, equals(0.0));
    expect(topAfterScroll.dy, lessThan(10.0));
    expect(topAfterScroll.dy, greaterThan(-50.0));
  });
}

Future<Null> slowDrag(WidgetTester tester, Key widget, Offset offset) async {
  final Offset target = tester.getCenter(find.byKey(widget));
  final TestGesture gesture = await tester.startGesture(target);
  await gesture.moveBy(offset);
  await tester.pump(const Duration(milliseconds: 10));
  await gesture.up();
}