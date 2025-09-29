// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PageTransitionsBuilder buildTransitions method is called correctly', (
    WidgetTester tester,
  ) async {
    bool buildTransitionsCalled = false;
    PageRoute<dynamic>? capturedRoute;
    BuildContext? capturedContext;
    Animation<double>? capturedAnimation;
    Animation<double>? capturedSecondaryAnimation;
    Widget? capturedChild;

    final _TestPageTransitionsBuilder builderWithCapture = _TestPageTransitionsBuilder(
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

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
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
    final _TestPageTransitionsBuilder customTransitionsBuilder = _TestPageTransitionsBuilder(
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
