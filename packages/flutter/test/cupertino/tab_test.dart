// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Use home', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          builder: (BuildContext context) => const Text('home'),
        ),
      ),
    );

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Use routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const Text('first route'),
          },
        ),
      ),
    );

    expect(find.text('first route'), findsOneWidget);
  });

  testWidgets('Use home and named routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('go to second page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/2');
              },
            );
          },
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second named route'),
          },
        ),
      ),
    );

    expect(find.text('go to second page'), findsOneWidget);
    await tester.tap(find.text('go to second page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second named route'), findsOneWidget);
  });

  testWidgets('Use onGenerateRoute', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == Navigator.defaultRouteName) {
              return CupertinoPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) {
                  return const Text('generated home');
                },
              );
            }
            return null;
          },
        ),
      ),
    );

    expect(find.text('generated home'), findsOneWidget);
  });

  testWidgets('Use onUnknownRoute', (WidgetTester tester) async {
    String unknownForRouteCalled;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          onUnknownRoute: (RouteSettings settings) {
            unknownForRouteCalled = settings.name;
            return null;
          },
        ),
      ),
    );

    expect(tester.takeException(), isFlutterError);
    expect(unknownForRouteCalled, '/');
  });

  testWidgets('Can use navigatorKey to navigate', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          navigatorKey: key,
          builder: (BuildContext context) => const Text('first route'),
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second route'),
          },
        ),
      ),
    );

    key.currentState.pushNamed('/2');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second route'), findsOneWidget);
  });

  testWidgets('Changing the key resets the navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('go to second page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/2');
              },
            );
          },
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second route'),
          },
        ),
      ),
    );

    expect(find.text('go to second page'), findsOneWidget);
    await tester.tap(find.text('go to second page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second route'), findsOneWidget);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          key: key,
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('go to second page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/2');
              },
            );
          },
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second route'),
          },
        ),
      ),
    );

    // The stack is gone and we're back to a re-built page 1.
    expect(find.text('go to second page'), findsOneWidget);
    expect(find.text('second route'), findsNothing);
  });

  testWidgets('Throws FlutterError when onUnknownRoute is null', (
      WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          navigatorKey: key,
          builder: (BuildContext context) => const Text('first route'),
          onUnknownRoute: null,
        ),
      ),
    );
    FlutterError error;
    try {
      key.currentState.pushNamed('/2');
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   Could not find a generator for route RouteSettings("/2", null) in\n'
      '   the _CupertinoTabViewState.\n'
      '   Generators for routes are searched for in the following order:\n'
      '    1. For the "/" route, the "builder" property, if non-null, is\n'
      '   used.\n'
      '    2. Otherwise, the "routes" table is used, if it has an entry for\n'
      '   the route.\n'
      '    3. Otherwise, onGenerateRoute is called. It should return a\n'
      '   non-null value for any valid route not handled by "builder" and\n'
      '   "routes".\n'
      '    4. Finally if all else fails onUnknownRoute is called.\n'
      '   Unfortunately, onUnknownRoute was not set.\n'
    ));
  });

  testWidgets('Throws FlutterError when onUnknownRoute returns null', (
      WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          navigatorKey: key,
          builder: (BuildContext context) => const Text('first route'),
          onUnknownRoute: (_) => null,
        ),
      ),
    );
    FlutterError error;
    try {
      key.currentState.pushNamed('/2');
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   The onUnknownRoute callback returned null.\n'
      '   When the _CupertinoTabViewState requested the route\n'
      '   RouteSettings("/2", null) from its onUnknownRoute callback, the\n'
      '   callback returned null. Such callbacks must never return null.\n'
    ));
  });
}
