// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Default PageTranstionsTheme includes a builder with a null platform', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: const Text('home')));
    final PageTransitionsTheme theme = Theme.of(tester.element(find.text('home'))).pageTransitionsTheme;
    expect(theme.builders, isNotNull);
    expect(theme.builders.map((PageTransitionsBuilder builder) => builder.platform), contains(null));
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

  testWidgets('Default PageTranstionsTheme builds a _GenericPageTransition for android', (WidgetTester tester) async {
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

    Finder findGenericPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_GenericPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, TargetPlatform.android);
    expect(findGenericPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findGenericPageTransition(), findsOneWidget);
  });

  testWidgets('pageTranstionsTheme override builds a _MountainViewPageTransition for android', (WidgetTester tester) async {
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
            builders: <PageTransitionsBuilder>[
              GenericPageTransitionsBuilder(),
              MountainViewPageTransitionsBuilder(), // creates a _MoutainViewPageTransition
            ],
          ),
        ),
        routes: routes,
      ),
    );

    Finder findMountainViewPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MountainViewPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, TargetPlatform.android);
    expect(findMountainViewPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findMountainViewPageTransition(), findsOneWidget);
  });

}
