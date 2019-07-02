// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'observer_tester.dart';

void main() {

  testWidgets('Back during pushReplacement', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Material(child: Text('home')),
      routes: <String, WidgetBuilder>{
        '/a': (BuildContext context) => const Material(child: Text('a')),
        '/b': (BuildContext context) => const Material(child: Text('b')),
      },
    ));

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/a');
    await tester.pumpAndSettle();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    navigator.pushReplacementNamed('/b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    navigator.pop();

    await tester.pumpAndSettle();

    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  group('pushAndRemoveUntil', () {

    testWidgets('notifies appropriately', (WidgetTester tester) async {
      final TestObserver observer = TestObserver();
      final Widget myApp = MaterialApp(
        home: const Material(child: Text('home')),
        routes: <String, WidgetBuilder>{
          '/a': (BuildContext context) => const Material(child: Text('a')),
          '/b': (BuildContext context) => const Material(child: Text('b')),
        },
        navigatorObservers: <NavigatorObserver>[observer],
      );

      await tester.pumpWidget(myApp);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsOneWidget);
      expect(find.text('a', skipOffstage: false), findsOneWidget);
      expect(find.text('b', skipOffstage: false), findsNothing);

      final List<String> log = <String>[];
      observer
        ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
          expectSync(route is PageRoute && route.settings.name == '/b', isTrue);
          expectSync(previousRoute is PageRoute && previousRoute.settings.name == '/a', isTrue);
          log.add('/b pushed, previous route: /a');
        }
        ..onRemoved = (Route<dynamic> route, Route<dynamic> previousRoute) {
          if (route.settings.name == '/a') {
            expectSync(previousRoute, null);
            log.add('/a removed, previous route: null');
          } else if (route.settings.name == '/') {
            expectSync(previousRoute, null);
            log.add('/ removed, previous route: null');
          }
        };

      // Remove all routes below
      navigator.pushNamedAndRemoveUntil('/b', (Route<dynamic> route) => false);
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsNothing);
      expect(find.text('a', skipOffstage: false), findsNothing);
      expect(find.text('b', skipOffstage: false), findsOneWidget);
      expect(log, contains('/b pushed, previous route: /a'));
      expect(log, contains('/a removed, previous route: null'));
      expect(log, contains('/ removed, previous route: null'));

      observer.onPushed = null;
      log.clear();


      navigator.pushNamed('/');
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsOneWidget);
      expect(find.text('a', skipOffstage: false), findsNothing);
      expect(find.text('b', skipOffstage: false), findsOneWidget);

      observer
        ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
          expectSync(route is PageRoute && route.settings.name == '/a', isTrue);
          expectSync(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
          log.add('/a pushed, previous route: /');
        }
        ..onRemoved = (Route<dynamic> route, Route<dynamic> previousRoute) {
          expectSync(route is PageRoute && route.settings.name == '/', isTrue);
          expectSync(previousRoute is PageRoute && previousRoute.settings.name == '/b', isTrue);
          log.add('/ removed, previous route: /b');
        };

      // Remove only some routes below
      navigator.pushNamedAndRemoveUntil('/a', ModalRoute.withName('/b'));
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsNothing);
      expect(find.text('a', skipOffstage: false), findsOneWidget);
      expect(find.text('b', skipOffstage: false), findsOneWidget);
      expect(log, contains('/a pushed, previous route: /'));
      expect(log, contains('/ removed, previous route: /b'));

      observer.onPushed = null;
      log.clear();
    });

    testWidgets('triggers page transition animation for pushed route', (WidgetTester tester) async {

      final Widget myApp = MaterialApp(
        home: const Material(child: Text('home')),
        routes: <String, WidgetBuilder>{
          '/a': (BuildContext context) => const Material(child: Text('a')),
          '/b': (BuildContext context) => const Material(child: Text('b')),
        },
      );

      await tester.pumpWidget(myApp);
      final NavigatorState navigator = tester.state(find.byType(Navigator));

      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      navigator.pushNamedAndRemoveUntil('/b', (Route<dynamic> route) => false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // We are mid-transition, both pages are onstage
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);

      // Complete transition
      await tester.pumpAndSettle();
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('Hero transition triggers when appropriate', (WidgetTester tester) async {
      const String kHeroTag = 'hero';
      final Widget myApp = MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const Material(child: Text('home')),
          '/a': (BuildContext context) => const Material(child: Hero(
            tag: kHeroTag,
            child: Text('a'),
          )),
          '/b': (BuildContext context) => const Material(child: Padding(
            padding: EdgeInsets.all(100.0),
            child: Hero(
              tag: kHeroTag,
              child: Text('b'),
            ),
          )),
        },
      );

      await tester.pumpWidget(myApp);
      final NavigatorState navigator = tester.state(find.byType(Navigator));

      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      navigator.pushNamedAndRemoveUntil('/b', ModalRoute.withName('/'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('b'), isOnstage);

      // 'b' text is heroing to its new location
      final Offset bOffset = tester.getTopLeft(find.text('b'));
      expect(bOffset.dx, greaterThan(0.0));
      expect(bOffset.dx, lessThan(100.0));
      expect(bOffset.dy, greaterThan(0.0));
      expect(bOffset.dy, lessThan(100.0));

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('a'), findsNothing);
      expect(find.text('b'), isOnstage);
    });

    testWidgets('Hero transition does not trigger when appropriate', (WidgetTester tester) async {
      const String kHeroTag = 'hero';
      final Widget myApp = MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const Material(child: Hero(
            tag:kHeroTag,
            child: Text('home'),
          )),
          '/a': (BuildContext context) => const Material(child: Text('a')),
          '/b': (BuildContext context) => const Material(child: Padding(
            padding: EdgeInsets.all(100.0),
            child: Hero(
              tag: kHeroTag,
              child: Text('b'),
            ),
          )),
        },
      );

      await tester.pumpWidget(myApp);
      final NavigatorState navigator = tester.state(find.byType(Navigator));

      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      navigator.pushNamedAndRemoveUntil('/b', ModalRoute.withName('/'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('b'), isOnstage);

      // 'b' text is sliding in from the right, no hero transition
      final Offset bOffset = tester.getTopLeft(find.text('b'));
      expect(bOffset.dx, 100.0);
      expect(bOffset.dy, greaterThan(100.0));
    });
  });
}
