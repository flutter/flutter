// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Default PageTranstionsTheme platform', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    final PageTransitionsTheme theme = Theme.of(tester.element(find.text('home'))).pageTransitionsTheme;
    expect(theme.builders, isNotNull);
    expect(theme.builders[TargetPlatform.android], isNotNull);
    expect(theme.builders[TargetPlatform.iOS], isNotNull);
  });

  testWidgets('Default PageTranstionsTheme builds a CupertionPageTransition for iOS', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        routes: routes,
      ),
    );

    expect(Theme.of(tester.element(find.text('push'))).platform, TargetPlatform.iOS);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);
  });

  testWidgets('Default PageTranstionsTheme builds a _FadeUpwardsPageTransition for android', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        routes: routes,
      ),
    );

    Finder findFadeUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_FadeUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, TargetPlatform.android);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);
  });

  testWidgets('pageTranstionsTheme override builds a _OpenUpwardsPageTransition for android', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
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

    expect(Theme.of(tester.element(find.text('push'))).platform, TargetPlatform.android);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);
  });

}
