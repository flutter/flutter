// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TODO(justinmc): Remove all hardcoded uses of FadeForwardsPageTransitionsBuilder and replace with this approach.
  testWidgets('navigating with transitions of different lengths', (WidgetTester tester) async {
    late TransitionRoute<void> currentRoute;
    final _TestNavigatorObserver testNavigatorObserver =
        _TestNavigatorObserver()
          ..onPopped = (Route<void> route, Route<void>? previousRoute) {
            currentRoute = route as TransitionRoute<void>;
          }
          ..onPushed = (Route<void> route, Route<void>? previousRoute) {
            currentRoute = route as TransitionRoute<void>;
          };

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[testNavigatorObserver],
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

    await tester.pump();
    await tester.pump(currentRoute.transitionDuration + const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Next'));

    await tester.pump();
    await tester.pump(currentRoute.transitionDuration + const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);

    await tester.tap(find.text('Back'));

    await tester.pump();
    await tester.pump(currentRoute.transitionDuration + const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Back'));

    await tester.pump();
    await tester.pump(currentRoute.transitionDuration + const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);
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

class _TestNavigatorObserver extends NavigatorObserver {
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPushed;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPopped;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onRemoved;
  void Function(Route<dynamic>? route, Route<dynamic>? previousRoute)? onReplaced;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onStartUserGesture;
  void Function()? onStopUserGesture;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPushed?.call(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPopped?.call(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRemoved?.call(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? oldRoute, Route<dynamic>? newRoute}) {
    onReplaced?.call(newRoute, oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onStartUserGesture?.call(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    onStopUserGesture?.call();
  }
}
