// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'observer_tester.dart';
import 'widgets_app_tester.dart';

void main() {
  testWidgets('Back during pushReplacement', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildApp(
        home: const Text('home'),
        routes: <String, WidgetBuilder>{
          '/a': (BuildContext context) => const Text('a'),
          '/b': (BuildContext context) => const Text('b'),
        },
      ),
    );

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
      final observer = TestObserver();
      final Widget myApp = _buildApp(
        home: const Text('home'),
        routes: <String, WidgetBuilder>{
          '/a': (BuildContext context) => const Text('a'),
          '/b': (BuildContext context) => const Text('b'),
        },
        navigatorObservers: <NavigatorObserver>[observer],
      );

      await tester.pumpWidget(myApp);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      final log = <String>[];
      observer
        ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
          log.add(
            '${route!.settings.name} pushed, previous route: ${previousRoute!.settings.name}',
          );
        }
        ..onRemoved = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
          log.add(
            '${route!.settings.name} removed, previous route: ${previousRoute?.settings.name}',
          );
        };

      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsOneWidget);
      expect(find.text('a', skipOffstage: false), findsOneWidget);
      expect(find.text('b', skipOffstage: false), findsNothing);

      // Remove all routes below
      navigator.pushNamedAndRemoveUntil('/b', (Route<dynamic> route) => false);
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsNothing);
      expect(find.text('a', skipOffstage: false), findsNothing);
      expect(find.text('b', skipOffstage: false), findsOneWidget);
      expect(
        log,
        equals(<String>[
          '/a pushed, previous route: /',
          '/b pushed, previous route: /a',
          '/a removed, previous route: null',
          '/ removed, previous route: null',
        ]),
      );

      log.clear();

      navigator.pushNamed('/');
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsOneWidget);
      expect(find.text('a', skipOffstage: false), findsNothing);
      expect(find.text('b', skipOffstage: false), findsOneWidget);

      // Remove only some routes below
      navigator.pushNamedAndRemoveUntil('/a', ModalRoute.withName('/b'));
      await tester.pumpAndSettle();

      expect(find.text('home', skipOffstage: false), findsNothing);
      expect(find.text('a', skipOffstage: false), findsOneWidget);
      expect(find.text('b', skipOffstage: false), findsOneWidget);
      expect(
        log,
        equals(<String>[
          '/ pushed, previous route: /b',
          '/a pushed, previous route: /',
          '/ removed, previous route: /b',
        ]),
      );
    });

    testWidgets('triggers page transition animation for pushed route', (WidgetTester tester) async {
      final Widget myApp = _buildApp(
        home: const Text('home'),
        routes: <String, WidgetBuilder>{
          '/a': (BuildContext context) => const Text('a'),
          '/b': (BuildContext context) => const Text('b'),
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

    testWidgets(
      'Hero transition triggers when preceding route contains hero, and predicate route does not',
      (WidgetTester tester) async {
        const kHeroTag = 'hero';
        final Widget myApp = _buildApp(
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const Text('home'),
            '/a': (BuildContext context) => const Hero(tag: kHeroTag, child: Text('a')),
            '/b': (BuildContext context) => const Padding(
              padding: EdgeInsets.all(100.0),
              child: Hero(tag: kHeroTag, child: Text('b')),
            ),
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
      },
    );

    testWidgets(
      'Hero transition does not trigger when preceding route does not contain hero, but predicate route does',
      (WidgetTester tester) async {
        const kHeroTag = 'hero';
        final Widget myApp = _buildApp(
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const Hero(tag: kHeroTag, child: Text('home')),
            '/a': (BuildContext context) => const Text('a'),
            '/b': (BuildContext context) => const Padding(
              padding: EdgeInsets.all(100.0),
              child: Hero(tag: kHeroTag, child: Text('b')),
            ),
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
      },
    );
  });
}

/// Builds a [TestWidgetsApp] for navigator replacement tests.
Widget _buildApp({
  Widget? home,
  String? initialRoute,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
  List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
}) {
  return TestWidgetsApp(
    home: home,
    initialRoute: initialRoute,
    routes: routes,
    pageRouteBuilder: _pageRouteBuilder,
    navigatorObservers: <NavigatorObserver>[HeroController(), ...navigatorObservers],
    textStyle: const TextStyle(color: Color(0xFF000000), fontSize: 14.0),
  );
}

/// Creates a page route with the transition used by the replacement tests.
PageRoute<T> _pageRouteBuilder<T>(RouteSettings settings, WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder:
        (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
            builder(context),
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero),
            ),
            child: child,
          );
        },
  );
}
