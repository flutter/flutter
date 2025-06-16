// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TestNavigatorObserver gets the transition duration of the current page', (
    WidgetTester tester,
  ) async {
    final TransitionDurationObserver observer = TransitionDurationObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (RouteSettings settings) {
          return switch (settings.name) {
            // A route that uses ZoomPageTransitionsBuilder.
            '/' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const ZoomPageTransitionsBuilder(),
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
            // A route that uses FadeForwardsPageTransitionsBuilder.
            '/2' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const FadeForwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 2'),
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

    // The zoom transition is 300ms long.
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(observer.transitionDuration, const Duration(milliseconds: 300));

    await tester.tap(find.text('Next'));

    await tester.pump();
    await tester.pump(observer.transitionDuration + const Duration(milliseconds: 1));

    // The fade forwards transition is 800ms long.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(observer.transitionDuration, const Duration(milliseconds: 800));
  });
}

class _TestTransitionRoute<T> extends MaterialPageRoute<T> {
  _TestTransitionRoute({required super.builder, required this.pageTransitionsBuilder});

  final PageTransitionsBuilder pageTransitionsBuilder;

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
  Duration get transitionDuration => pageTransitionsBuilder.transitionDuration;
  @override
  Duration get reverseTransitionDuration => pageTransitionsBuilder.reverseTransitionDuration;
}
