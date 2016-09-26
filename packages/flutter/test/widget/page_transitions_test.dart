// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class TestOverlayRoute extends OverlayRoute<Null> {
  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield new OverlayEntry(builder: _build);
  }
  Widget _build(BuildContext context) => new Text('Overlay');
}

void main() {
  testWidgets('Check onstage/offstage handling around transitions', (WidgetTester tester) async {
    GlobalKey containerKey1 = new GlobalKey();
    GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Container(key: containerKey1, child: new Text('Home')),
      '/settings': (_) => new Container(key: containerKey2, child: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey1.currentContext), isFalse);
    Navigator.pushNamed(containerKey1.currentContext, '/settings');
    expect(Navigator.canPop(containerKey1.currentContext), isTrue);

    await tester.pump();

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings', skipOffstage: false), isOffstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    Navigator.push(containerKey2.currentContext, new TestOverlayRoute());

    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), isOnstage);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), isOnstage);

    expect(Navigator.canPop(containerKey2.currentContext), isTrue);
    Navigator.pop(containerKey2.currentContext);
    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey2.currentContext), isTrue);
    Navigator.pop(containerKey2.currentContext);
    await tester.pump();

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey1.currentContext), isFalse);
  });

  testWidgets('Check back gesture works on iOS', (WidgetTester tester) async {
    GlobalKey containerKey1 = new GlobalKey();
    GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.iOS),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture.
    TestGesture gesture = await tester.startGesture(new Point(5.0, 100.0));
    await gesture.moveBy(new Offset(50.0, 0.0));
    await tester.pump();

    // Home is now visible.
    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
  });

  testWidgets('Check back gesture does nothing on android', (WidgetTester tester) async {
    GlobalKey containerKey1 = new GlobalKey();
    GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.android),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture.
    TestGesture gesture = await tester.startGesture(new Point(5.0, 100.0));
    await gesture.moveBy(new Offset(50.0, 0.0));
    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
  });

  testWidgets('Check page transition positioning on iOS', (WidgetTester tester) async {
    GlobalKey containerKey1 = new GlobalKey();
    GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.iOS),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);

    // Home page is staying in place.
    Point homeOffset = tester.getTopLeft(find.text('Home'));
    expect(homeOffset.x, 0.0);
    expect(homeOffset.y, 0.0);

    // Settings page is sliding up from the bottom.
    Point settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, 0.0);
    expect(settingsOffset.y, greaterThan(0.0));

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Settings page is in position.
    settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, 0.0);
    expect(settingsOffset.y, 0.0);

    Navigator.pop(containerKey1.currentContext);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // Home page is staying in place.
    homeOffset = tester.getTopLeft(find.text('Home'));
    expect(homeOffset.x, 0.0);
    expect(homeOffset.y, 0.0);

    // Settings page is sliding down off the bottom.
    settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, 0.0);
    expect(settingsOffset.y, greaterThan(0.0));

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Check back gesture disables Heroes', (WidgetTester tester) async {
    GlobalKey containerKey1 = new GlobalKey();
    GlobalKey containerKey2 = new GlobalKey();
    const String kHeroTag = 'hero';
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(
        key: containerKey1,
        body: new Container(
          decoration: new BoxDecoration(backgroundColor: const Color(0xff00ffff)),
          child: new Hero(
            tag: kHeroTag,
            child: new Text('Home')
          )
        )
      ),
      '/settings': (_) => new Scaffold(
        key: containerKey2,
        body: new Container(
          padding: const EdgeInsets.all(100.0),
          decoration: new BoxDecoration(backgroundColor: const Color(0xffff00ff)),
          child: new Hero(
            tag: kHeroTag,
            child: new Text('Settings')
          )
        )
      ),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.iOS),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Settings'), isOnstage);

    // Settings text is heroing to its new location
    Point settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, greaterThan(0.0));
    expect(settingsOffset.x, lessThan(100.0));
    expect(settingsOffset.y, greaterThan(0.0));
    expect(settingsOffset.y, lessThan(100.0));

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture.
    TestGesture gesture = await tester.startGesture(new Point(5.0, 100.0));
    await gesture.moveBy(new Offset(50.0, 0.0));
    await tester.pump();

    // Home is now visible.
    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);

    // Home page is sliding in from the left, no heroes.
    Point homeOffset = tester.getTopLeft(find.text('Home'));
    expect(homeOffset.x, lessThan(0.0));
    expect(homeOffset.y, 0.0);

    // Settings page is sliding off to the right, no heroes.
    settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, greaterThan(100.0));
    expect(settingsOffset.y, 100.0);
  });

  testWidgets('Check back gesture doesnt start during transitions', (WidgetTester tester) async {
    GlobalKey containerKey1 = new GlobalKey();
    GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.iOS),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // We are mid-transition, both pages are on stage.
    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture. (near bottom so we grab
    // the Settings page as it comes up).
    TestGesture gesture = await tester.startGesture(new Point(5.0, 550.0));
    await gesture.moveBy(new Offset(500.0, 0.0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // The original forward navigation should have completed, instead of the
    // back gesture, since we were mid transition.
    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Try again now that we're settled.
    gesture = await tester.startGesture(new Point(5.0, 550.0));
    await gesture.moveBy(new Offset(500.0, 0.0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
  });
}
