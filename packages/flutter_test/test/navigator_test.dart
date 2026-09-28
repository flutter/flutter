// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TestNavigatorObserver gets the transition duration of the most recent transition', (
    WidgetTester tester,
  ) async {
    final observer = TransitionDurationObserver();

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (RouteSettings settings) {
          return switch (settings.name) {
            '/' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const _TestSlideUpPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 1'),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/2');
                        },
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                );
              },
            ),
            '/2' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const _TestSlightRightPageTransitionsBuilder(),
              transitionDurationOverride: const Duration(milliseconds: 456),
              reverseTransitionDurationOverride: const Duration(milliseconds: 567),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 2'),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/3');
                        },
                        child: const Text('Next'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              },
            ),
            '/3' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const _TestSlideUpPageTransitionsBuilder(),
              transitionDurationOverride: const Duration(milliseconds: 678),
              reverseTransitionDurationOverride: const Duration(milliseconds: 789),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 3'),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/4');
                        },
                        child: const Text('Next'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              },
            ),
            '/4' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const _TestSlightRightPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 4'),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _ => throw Exception('Invalid route.'),
          };
        },
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);
    expect(find.text('Page 4'), findsNothing);

    expect(
      observer.transitionDuration,
      const _TestSlideUpPageTransitionsBuilder().transitionDuration,
    );

    await tester.tap(find.text('Next'));
    expect(observer.transitionDuration, const Duration(milliseconds: 456));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);
    expect(find.text('Page 4'), findsNothing);

    await tester.tap(find.text('Next'));
    expect(observer.transitionDuration, const Duration(milliseconds: 678));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);
    expect(find.text('Page 4'), findsNothing);

    await tester.tap(find.text('Next'));
    expect(
      observer.transitionDuration,
      const _TestSlightRightPageTransitionsBuilder().transitionDuration,
    );

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);
    expect(find.text('Page 4'), findsOneWidget);

    await tester.tap(find.text('Back'));
    expect(
      observer.transitionDuration,
      const _TestSlightRightPageTransitionsBuilder().reverseTransitionDuration,
    );

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);
    expect(find.text('Page 4'), findsNothing);

    await tester.tap(find.text('Back'));
    expect(observer.transitionDuration, const Duration(milliseconds: 789));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);
    expect(find.text('Page 4'), findsNothing);

    await tester.tap(find.text('Back'));
    expect(observer.transitionDuration, const Duration(milliseconds: 567));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);
    expect(find.text('Page 4'), findsNothing);
  });

  testWidgets('TestNavigatorObserver throws when there has never been a transition', (
    WidgetTester tester,
  ) async {
    final observer = TransitionDurationObserver();

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (RouteSettings settings) {
          return switch (settings.name) {
            // A route with no transition.
            '/' => _TestOverlayRoute<void>(
              builder: (BuildContext context) {
                return const Center(child: Column(children: <Widget>[Text('Page 1')]));
              },
            ),
            _ => throw Exception('Invalid route.'),
          };
        },
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(() => observer.transitionDuration, throwsA(isFlutterError));
  });
}

class _TestSlightRightPageTransitionsBuilder extends PageTransitionsBuilder {
  const _TestSlightRightPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const Offset end = .zero;
    final Animatable<Offset> tween = Tween<Offset>(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: Curves.ease));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class _TestSlideUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const _TestSlideUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const Offset end = .zero;
    final Animatable<Offset> tween = Tween<Offset>(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: Curves.ease));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class _TestTransitionRoute<T> extends PageRoute<T> {
  _TestTransitionRoute({
    required this.builder,
    required this.pageTransitionsBuilder,
    this.transitionDurationOverride,
    this.reverseTransitionDurationOverride,
  });

  final WidgetBuilder builder;
  final PageTransitionsBuilder pageTransitionsBuilder;
  final Duration? transitionDurationOverride;
  final Duration? reverseTransitionDurationOverride;

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
    return pageTransitionsBuilder.buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      transitionDurationOverride ?? pageTransitionsBuilder.transitionDuration;
  @override
  Duration get reverseTransitionDuration =>
      reverseTransitionDurationOverride ?? pageTransitionsBuilder.reverseTransitionDuration;
}

class _TestOverlayRoute<T> extends OverlayRoute<T> {
  _TestOverlayRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[OverlayEntry(builder: builder)];
  }
}
