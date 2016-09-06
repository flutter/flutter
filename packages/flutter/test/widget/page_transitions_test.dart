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
}
