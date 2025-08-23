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
