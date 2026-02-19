// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

void main() {
  group('TestWidgetsApp', () {
    testWidgets('home widget is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const TestWidgetsApp(home: Text('Home Widget')));

      expect(find.text('Home Widget'), findsOneWidget);
    });

    testWidgets('uses default color (white) when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(const TestWidgetsApp(home: Placeholder()));

      final WidgetsApp widgetsApp = tester.widget(find.byType(WidgetsApp));
      expect(widgetsApp.color, const Color(0xFFFFFFFF));
    });

    testWidgets('uses custom color when specified', (WidgetTester tester) async {
      const customColor = Color(0xFF123456);

      await tester.pumpWidget(const TestWidgetsApp(home: Placeholder(), color: customColor));

      final WidgetsApp widgetsApp = tester.widget(find.byType(WidgetsApp));
      expect(widgetsApp.color, customColor);
    });

    testWidgets('provides working Overlay', (WidgetTester tester) async {
      late OverlayState overlayState;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  overlayState = Overlay.of(context);
                },
                child: const Text('Tap me'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(overlayState, isNotNull);
    });

    testWidgets('overlay entries can be inserted and displayed', (WidgetTester tester) async {
      late OverlayState overlayState;
      OverlayEntry? overlayEntry;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  overlayState = Overlay.of(context);
                  overlayEntry = OverlayEntry(
                    builder: (BuildContext context) {
                      return const Positioned(top: 100, left: 100, child: Text('Overlay Content'));
                    },
                  );
                  overlayState.insert(overlayEntry!);
                },
                child: const Text('Show Overlay'),
              );
            },
          ),
        ),
      );

      expect(find.text('Overlay Content'), findsNothing);

      await tester.tap(find.text('Show Overlay'));
      await tester.pump();

      expect(find.text('Overlay Content'), findsOneWidget);

      overlayEntry?.remove();
      overlayEntry?.dispose();
      await tester.pump();

      expect(find.text('Overlay Content'), findsNothing);
    });

    testWidgets('provides working Navigator', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return const Text('Second Page');
                          },
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Second Page'), findsNothing);

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page'), findsOneWidget);
    });

    testWidgets('Navigator can pop routes', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Second Page - Tap to go back'),
                            );
                          },
                    ),
                  );
                },
                child: const Text('First Page'),
              );
            },
          ),
        ),
      );

      expect(find.text('First Page'), findsOneWidget);

      await tester.tap(find.text('First Page'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page - Tap to go back'), findsOneWidget);
      expect(find.text('First Page'), findsNothing);

      await tester.tap(find.text('Second Page - Tap to go back'));
      await tester.pumpAndSettle();

      expect(find.text('First Page'), findsOneWidget);
      expect(find.text('Second Page - Tap to go back'), findsNothing);
    });

    testWidgets('provides MediaQuery', (WidgetTester tester) async {
      late MediaQueryData mediaQueryData;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              mediaQueryData = MediaQuery.of(context);
              return const Placeholder();
            },
          ),
        ),
      );

      expect(mediaQueryData, isNotNull);
      expect(mediaQueryData.size, isNotNull);
    });

    testWidgets('provides Directionality', (WidgetTester tester) async {
      late TextDirection textDirection;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              textDirection = Directionality.of(context);
              return const Placeholder();
            },
          ),
        ),
      );

      expect(textDirection, isNotNull);
    });

    testWidgets('routes can be navigated with pushNamed', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/details');
                },
                child: const Text('Home Page'),
              );
            },
          ),
          routes: <String, WidgetBuilder>{
            '/details': (BuildContext context) => const Text('Details Page'),
          },
        ),
      );

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Details Page'), findsNothing);

      await tester.tap(find.text('Home Page'));
      await tester.pumpAndSettle();

      expect(find.text('Details Page'), findsOneWidget);
    });

    testWidgets('routes support pop navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/details');
                },
                child: const Text('Home Page'),
              );
            },
          ),
          routes: <String, WidgetBuilder>{
            '/details': (BuildContext context) => GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Text('Details Page - Tap to go back'),
            ),
          },
        ),
      );

      expect(find.text('Home Page'), findsOneWidget);

      await tester.tap(find.text('Home Page'));
      await tester.pumpAndSettle();

      expect(find.text('Details Page - Tap to go back'), findsOneWidget);
      expect(find.text('Home Page'), findsNothing);

      await tester.tap(find.text('Details Page - Tap to go back'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Details Page - Tap to go back'), findsNothing);
    });

    testWidgets('uses no transition by default for simpler testing', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/details');
                },
                child: const Text('Home Page'),
              );
            },
          ),
          routes: <String, WidgetBuilder>{
            '/details': (BuildContext context) => const Text('Details Page'),
          },
        ),
      );

      await tester.tap(find.text('Home Page'));
      // Single pump is sufficient with zero-duration transitions.
      await tester.pump();

      // Route should be immediately visible without needing pumpAndSettle.
      expect(find.text('Details Page'), findsOneWidget);
    });

    testWidgets('custom pageRouteBuilder is used', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/details');
                },
                child: const Text('Home Page'),
              );
            },
          ),
          routes: <String, WidgetBuilder>{
            '/details': (BuildContext context) => const Text('Details Page'),
          },
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              settings: settings,
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) => builder(context),
              transitionsBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    Widget child,
                  ) {
                    return ScaleTransition(scale: animation, child: child);
                  },
            );
          },
        ),
      );

      await tester.tap(find.text('Home Page'));
      await tester.pump();

      // Custom pageRouteBuilder wraps the route with ScaleTransition.
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.text('Details Page'), findsOneWidget);
    });

    testWidgets('multiple routes can be defined', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/page1');
                    },
                    child: const Text('Go to Page 1'),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/page2');
                    },
                    child: const Text('Go to Page 2'),
                  ),
                ],
              );
            },
          ),
          routes: <String, WidgetBuilder>{
            '/page1': (BuildContext context) => const Text('Page 1 Content'),
            '/page2': (BuildContext context) => const Text('Page 2 Content'),
          },
        ),
      );

      // Navigate to page 1.
      await tester.tap(find.text('Go to Page 1'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1 Content'), findsOneWidget);

      // Go back.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      // Navigate to page 2.
      await tester.tap(find.text('Go to Page 2'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2 Content'), findsOneWidget);
    });

    testWidgets('navigatorKey provides access to NavigatorState', (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        TestWidgetsApp(
          navigatorKey: navigatorKey,
          home: const Text('Home Page'),
          routes: <String, WidgetBuilder>{
            '/details': (BuildContext context) => const Text('Details Page'),
          },
        ),
      );

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Details Page'), findsNothing);

      // Use navigatorKey to navigate directly.
      navigatorKey.currentState!.pushNamed('/details');
      await tester.pumpAndSettle();

      expect(find.text('Details Page'), findsOneWidget);

      // Use navigatorKey to pop.
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Details Page'), findsNothing);
    });
  });
}
