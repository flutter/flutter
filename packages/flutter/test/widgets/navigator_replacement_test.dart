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

    final TestObserver observer = TestObserver();
    final Widget myApp = MaterialApp(
      home: const Material(child: Text('home')),
      routes: <String, WidgetBuilder>{
        '/a': (BuildContext context) => const Material(child: Text('a')),
        '/b': (BuildContext context) => const Material(child: Text('b')),
        '/c': (BuildContext context) => const Material(child: Text('c')),
      },
      navigatorObservers: <NavigatorObserver>[observer],
    );

    testWidgets('notifies appropriately', (WidgetTester tester) async {

      await tester.pumpWidget(myApp);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsOneWidget);
      expect(find.text('a', skipOffstage: false), findsOneWidget);
      expect(find.text('b', skipOffstage: false), findsNothing);

      bool isPushed = false;
      bool aIsRemoved = false;
      bool homeIsRemoved = false;
      observer
        ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
          expectSync(route is PageRoute && route.settings.name == '/b', isTrue);
          expectSync(previousRoute is PageRoute && previousRoute.settings.name == '/a', isTrue);
          isPushed = true;
        }
        ..onRemoved = (Route<dynamic> route, Route<dynamic> previousRoute) {
          if (route.settings.name == '/a') {
            expectSync(previousRoute, null);
            aIsRemoved = true;
          } else if (route.settings.name == '/') {
            expectSync(previousRoute, null);
            homeIsRemoved = true;
          }
        };

      // Remove all routes below
      navigator.pushNamedAndRemoveUntil('/b', (Route<dynamic> route) => false);
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsNothing);
      expect(find.text('a', skipOffstage: false), findsNothing);
      expect(find.text('b', skipOffstage: false), findsOneWidget);
      expect(isPushed, isTrue);
      expect(aIsRemoved, isTrue);
      expect(homeIsRemoved, isTrue);

      observer.onPushed = null;

      navigator.pushNamed('/');
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsOneWidget);
      expect(find.text('a', skipOffstage: false), findsNothing);
      expect(find.text('b', skipOffstage: false), findsOneWidget);

      isPushed = false;
      homeIsRemoved = false;
      observer
        ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
          expectSync(route is PageRoute && route.settings.name == '/a', isTrue);
          expectSync(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
          isPushed = true;
        }
        ..onRemoved = (Route<dynamic> route, Route<dynamic> previousRoute) {
          expectSync(route is PageRoute && route.settings.name == '/', isTrue);
          expectSync(previousRoute is PageRoute && previousRoute.settings.name == '/b', isTrue);
          homeIsRemoved = true;
        };

      // Remove only some routes below
      navigator.pushNamedAndRemoveUntil('/a', ModalRoute.withName('/b'));
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsNothing);
      expect(find.text('a', skipOffstage: false), findsOneWidget);
      expect(find.text('b', skipOffstage: false), findsOneWidget);
      expect(isPushed, isTrue);
      expect(homeIsRemoved, isTrue);
    });

    testWidgets('triggers page transition animation for pushed route', (WidgetTester tester) async {

      observer
        ..onPushed = null
        ..onRemoved = null;

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
