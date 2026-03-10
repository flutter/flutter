// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PageTransitionsBuilder buildTransitions method is called correctly', (
    WidgetTester tester,
  ) async {
    var buildTransitionsCalled = false;
    PageRoute<dynamic>? capturedRoute;
    BuildContext? capturedContext;
    Animation<double>? capturedAnimation;
    Animation<double>? capturedSecondaryAnimation;
    Widget? capturedChild;

    final builderWithCapture = _TestPageTransitionsBuilder(
      onBuildTransitions:
          <T>(
            PageRoute<T> route,
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            buildTransitionsCalled = true;
            capturedRoute = route;
            capturedContext = context;
            capturedAnimation = animation;
            capturedSecondaryAnimation = secondaryAnimation;
            capturedChild = child;

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
    );

    final routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () {
            Navigator.of(context).pushNamed('/test');
          },
        ),
      ),
      '/test': (BuildContext context) => const Material(child: Text('test page')),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: builderWithCapture,
            },
          ),
        ),
        routes: routes,
      ),
    );

    // Trigger navigation
    await tester.tap(find.text('push'));
    await tester.pump();

    // Verify buildTransitions was called with correct parameters
    expect(buildTransitionsCalled, isTrue);
    expect(capturedRoute, isNotNull);
    expect(capturedContext, isNotNull);
    expect(capturedAnimation, isNotNull);
    expect(capturedSecondaryAnimation, isNotNull);
    expect(capturedChild, isNotNull);
    expect(capturedRoute!.settings.name, '/');
  });

  testWidgets('PageTransitionsBuilder works with custom Navigator and PageRoute', (
    WidgetTester tester,
  ) async {
    final customTransitionsBuilder = _TestPageTransitionsBuilder(
      onBuildTransitions:
          <T>(
            PageRoute<T> route,
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              ),
            );
          },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return _CustomPageRoute<void>(
              settings: settings,
              transitionsBuilder: customTransitionsBuilder,
              builder: (BuildContext context) {
                if (settings.name == '/') {
                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/second');
                      },
                      child: Container(
                        width: 200,
                        height: 50,
                        color: const Color(0xFF2196F3),
                        child: const Center(
                          child: Text('Navigate', style: TextStyle(color: Color(0xFFFFFFFF))),
                        ),
                      ),
                    ),
                  );
                }
                return const ColoredBox(
                  color: Color(0xFF4CAF50),
                  child: Center(
                    child: Text(
                      'Second Page',
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Second Page'), findsNothing);

    await tester.tap(find.text('Navigate'));
    await tester.pump();

    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Second Page'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));

    final FadeTransition fadeTransition = tester.widget<FadeTransition>(
      find.byType(FadeTransition).first,
    );
    expect(fadeTransition.opacity.value, greaterThan(0.0));
    expect(fadeTransition.opacity.value, lessThanOrEqualTo(1.0));

    final ScaleTransition scaleTransition = tester.widget<ScaleTransition>(
      find.byType(ScaleTransition).first,
    );
    expect(scaleTransition.scale.value, greaterThanOrEqualTo(0.5));
    expect(scaleTransition.scale.value, lessThanOrEqualTo(1.0));

    await tester.pumpAndSettle();

    expect(find.text('Navigate'), findsNothing);
    expect(find.text('Second Page'), findsOneWidget);
  });

  testWidgets('FadeUpwardsPageTransitionsBuilder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return _CustomPageRoute<void>(
              settings: settings,
              transitionsBuilder: const FadeUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                if (settings.name == '/') {
                  return ColoredBox(
                    color: const Color(0xFF2196F3),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/second');
                        },
                        child: const Text(
                          'Page 1',
                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }
                return const ColoredBox(
                  color: Color(0xFF4CAF50),
                  child: Center(
                    child: Text('Page 2', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    await tester.tap(find.text('Page 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    FadeTransition widget2Opacity = tester
        .element(find.text('Page 2'))
        .findAncestorWidgetOfExactType<FadeTransition>()!;
    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.dx == widget2TopLeft.dx, true);
    expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
    expect(widget2Opacity.opacity.value < 0.01, true);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    widget2Opacity = tester
        .element(find.text('Page 2'))
        .findAncestorWidgetOfExactType<FadeTransition>()!;
    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
    expect(widget2Opacity.opacity.value < 1.0, true);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets(
    'FadeUpwardsPageTransitionsBuilder test with Material PageTransitionTheme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Material(child: Text('Page 1')),
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),
          routes: <String, WidgetBuilder>{
            '/next': (BuildContext context) {
              return const Material(child: Text('Page 2'));
            },
          },
        ),
      );

      final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      FadeTransition widget2Opacity = tester
          .element(find.text('Page 2'))
          .findAncestorWidgetOfExactType<FadeTransition>()!;
      Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));
      final Size widget2Size = tester.getSize(find.text('Page 2'));

      // Android transition is vertical only.
      expect(widget1TopLeft.dx == widget2TopLeft.dx, true);
      // Page 1 is above page 2 mid-transition.
      expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
      // Animation begins 3/4 of the way up the page.
      expect(widget2TopLeft.dy < widget2Size.height / 4.0, true);
      // Animation starts with page 2 being near transparent.
      expect(widget2Opacity.opacity.value < 0.01, true);

      await tester.pump(const Duration(milliseconds: 300));

      // Page 2 covers page 1.
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), isOnstage);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      widget2Opacity = tester
          .element(find.text('Page 2'))
          .findAncestorWidgetOfExactType<FadeTransition>()!;
      widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

      // Page 2 starts to move down.
      expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
      // Page 2 starts to lose opacity.
      expect(widget2Opacity.opacity.value < 1.0, true);

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Page 1'), isOnstage);
      expect(find.text('Page 2'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'PageTransitionsTheme override builds a _OpenUpwardsPageTransition',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android:
                    OpenUpwardsPageTransitionsBuilder(), // creates a _OpenUpwardsPageTransition
              },
            ),
          ),
          routes: routes,
        ),
      );

      Finder findOpenUpwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_OpenUpwardsPageTransition',
          ),
        );
      }

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(findOpenUpwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(findOpenUpwardsPageTransition(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('OpenUpwardsPageTransitionsBuilder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return _CustomPageRoute<void>(
              settings: settings,
              transitionsBuilder: const OpenUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                if (settings.name == '/') {
                  return ColoredBox(
                    color: const Color(0xFF2196F3),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/second');
                        },
                        child: const Text(
                          'Page 1',
                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }
                return const ColoredBox(
                  color: Color(0xFF4CAF50),
                  child: Center(
                    child: Text('Page 2', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    await tester.tap(find.text('Page 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    final Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.dx, widget2TopLeft.dx);
    expect(widget1TopLeft.dy <= widget2TopLeft.dy, true);

    await tester.pump(const Duration(milliseconds: 300));

    // After animation, only Page 2 should be visible.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));

    // After reverse animation, only Page 1 should be visible.
    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets(
    'OpenUpwardsPageTransitionsBuilder test with Material PageTransitionTheme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Material(child: Text('Page 1')),
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
              },
            ),
          ),
          routes: <String, WidgetBuilder>{
            '/next': (BuildContext context) {
              return const Material(child: Text('Page 2'));
            },
          },
        ),
      );

      final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);

      final Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

      expect(widget1TopLeft.dx, widget2TopLeft.dx);
      expect(widget1TopLeft.dy < widget2TopLeft.dy, true);

      await tester.pump(const Duration(milliseconds: 300));

      // Page 2 covers page 1.
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), isOnstage);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));

      // Back to page 1.
      expect(find.text('Page 1'), isOnstage);
      expect(find.text('Page 2'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

class _CustomPageRoute<T> extends PageRoute<T> {
  _CustomPageRoute({required this.builder, required this.transitionsBuilder, super.settings});

  final WidgetBuilder builder;
  final PageTransitionsBuilder transitionsBuilder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class _TestPageTransitionsBuilder extends PageTransitionsBuilder {
  const _TestPageTransitionsBuilder({required this.onBuildTransitions});

  final Widget Function<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  onBuildTransitions;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return onBuildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
