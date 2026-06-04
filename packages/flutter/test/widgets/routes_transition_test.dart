// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'button_tester.dart';
import 'widgets_app_tester.dart';

void main() {
  testWidgets('Navigating with transitions of different lengths', (WidgetTester tester) async {
    final observer = TransitionDurationObserver();

    await tester.pumpWidget(
      TestWidgetsApp(
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (RouteSettings settings) {
          return switch (settings.name) {
            // A route that uses the default page transition duration.
            '/' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const FadeUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 1'),
                      TestButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/2');
                        },
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                );
              },
            ),
            // A route that uses OpenUpwardsPageTransitionsBuilder.
            '/2' => _TestTransitionRoute<void>(
              transitionDurationOverride: const Duration(milliseconds: 456),
              reverseTransitionDurationOverride: const Duration(milliseconds: 567),
              pageTransitionsBuilder: const OpenUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 2'),
                      TestButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/3');
                        },
                        child: const Text('Next'),
                      ),
                      TestButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              },
            ),
            // A route that uses FadeUpwardsPageTransitionsBuilder.
            '/3' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const FadeUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Center(
                  child: Column(
                    children: <Widget>[
                      const Text('Page 3'),
                      TestButton(
                        onPressed: () {
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

    await tester.tap(find.text('Next'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Next'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);

    await tester.tap(find.text('Back'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Back'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);
  });
}

class _TestTransitionRoute<T> extends PageRoute<T> {
  _TestTransitionRoute({
    required this.builder,
    required this.pageTransitionsBuilder,
    this.transitionDurationOverride,
    this.reverseTransitionDurationOverride,
    super.settings,
  });

  final WidgetBuilder builder;
  final PageTransitionsBuilder pageTransitionsBuilder;
  final Duration? transitionDurationOverride;
  final Duration? reverseTransitionDurationOverride;

  @override
  Duration get transitionDuration =>
      transitionDurationOverride ?? pageTransitionsBuilder.transitionDuration;
  @override
  Duration get reverseTransitionDuration =>
      reverseTransitionDurationOverride ?? pageTransitionsBuilder.reverseTransitionDuration;

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
    return pageTransitionsBuilder.buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
