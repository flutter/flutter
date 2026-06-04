// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'button_tester.dart';
import 'widgets_app_tester.dart';

void main() {
  testWidgets('PageTransitionsBuilder buildTransitions method is called correctly', (
    WidgetTester tester,
  ) async {
    final capturedRoutes = <PageRoute<dynamic>>[];
    final capturedContexts = <BuildContext>[];
    final capturedAnimations = <Animation<double>>[];
    final capturedSecondaryAnimations = <Animation<double>>[];
    final capturedChildren = <Widget>[];

    final builderWithCapture = _TestPageTransitionsBuilder(
      onBuildTransitions:
          <T>(
            PageRoute<T> route,
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            capturedRoutes.add(route);
            capturedContexts.add(context);
            capturedAnimations.add(animation);
            capturedSecondaryAnimations.add(secondaryAnimation);
            capturedChildren.add(child);

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
      '/': (BuildContext context) => TestButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/test');
        },
        child: const Text('push'),
      ),
      '/test': (BuildContext context) => const Text('test page'),
    };

    await tester.pumpWidget(
      TestWidgetsApp(
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return _CustomPageRoute<T>(
            settings: settings,
            transitionsBuilder: builderWithCapture,
            builder: builder,
          );
        },
        routes: routes,
      ),
    );

    capturedRoutes.clear();
    capturedContexts.clear();
    capturedAnimations.clear();
    capturedSecondaryAnimations.clear();
    capturedChildren.clear();

    // Trigger navigation.
    await tester.tap(find.text('push'));
    await tester.pump();

    // Verify buildTransitions was called for the pushed route with matching captured arguments.
    expect(capturedRoutes, isNotEmpty);
    expect(capturedContexts, hasLength(capturedRoutes.length));
    expect(capturedAnimations, hasLength(capturedRoutes.length));
    expect(capturedSecondaryAnimations, hasLength(capturedRoutes.length));
    expect(capturedChildren, hasLength(capturedRoutes.length));
    final int pushedRouteIndex = capturedRoutes.indexWhere((PageRoute<dynamic> route) {
      return route.settings.name == '/test';
    });
    expect(pushedRouteIndex, isNot(-1));
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
