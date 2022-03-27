// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Default PageTransitionsTheme platform', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    final PageTransitionsTheme theme = Theme.of(tester.element(find.text('home'))).pageTransitionsTheme;
    expect(theme.builders, isNotNull);
    for (final TargetPlatform platform in TargetPlatform.values) {
      switch (platform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expect(
            theme.builders[platform],
            isNotNull,
            reason: 'theme builder for $platform is null',
          );
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(
            theme.builders[platform],
            isNull,
            reason: 'theme builder for $platform is not null',
          );
          break;
      }
    }
  });

  testWidgets('Default PageTransitionsTheme builds a CupertinoPageTransition', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Default PageTransitionsTheme builds a _ZoomPageTransition for android', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );

    Finder findZoomPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ZoomPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findZoomPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findZoomPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('PageTransitionsTheme override builds a _OpenUpwardsPageTransition', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(), // creates a _OpenUpwardsPageTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    Finder findOpenUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_OpenUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('PageTransitionsTheme override builds a _FadeUpwardsTransition', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(), // creates a _FadeUpwardsTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    Finder findFadeUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_FadeUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('_ZoomPageTransition only cause child widget built once', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/58345

    int builtCount = 0;

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          builtCount++; // Increase [builtCount] each time the widget build
          return TextButton(
            child: const Text('pop'),
            onPressed: () { Navigator.pop(context); },
          );
        },
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: ZoomPageTransitionsBuilder(), // creates a _ZoomPageTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    // No matter push or pop was called, the child widget should built only once.
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(builtCount, 1);

    await tester.tap(find.text('pop'));
    await tester.pumpAndSettle();
    expect(builtCount, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
