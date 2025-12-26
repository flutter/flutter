// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigating with transitions of different lengths', (WidgetTester tester) async {
    final TransitionDurationObserver observer = TransitionDurationObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (RouteSettings settings) {
          return switch (settings.name) {
            // A route that uses the default page transition.
            '/' => MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 1'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/2');
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // A route that uses ZoomPageTransitionsBuilder.
            '/2' => _TestTransitionRoute<void>(
              transitionDurationOverride: const Duration(milliseconds: 456),
              reverseTransitionDurationOverride: const Duration(milliseconds: 567),
              pageTransitionsBuilder: const ZoomPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 2'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/3');
                          },
                          child: const Text('Next'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // A route that uses FadeForwardsPageTransitionsBuilder.
            '/3' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const FadeForwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 3'),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    ),
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

class _TestTransitionRoute<T> extends MaterialPageRoute<T> {
  _TestTransitionRoute({
    required super.builder,
    required this.pageTransitionsBuilder,
    this.transitionDurationOverride,
    this.reverseTransitionDurationOverride,
  });

  final PageTransitionsBuilder pageTransitionsBuilder;
  final Duration? transitionDurationOverride;
  final Duration? reverseTransitionDurationOverride;

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
  Duration get transitionDuration =>
      transitionDurationOverride ?? pageTransitionsBuilder.transitionDuration;
  @override
  Duration get reverseTransitionDuration =>
      reverseTransitionDurationOverride ?? pageTransitionsBuilder.reverseTransitionDuration;
}
