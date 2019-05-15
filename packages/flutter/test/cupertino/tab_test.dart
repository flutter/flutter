// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Use home', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          builder: (BuildContext context) => const Text('home'),
        ),
      ),
    );

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Use routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const Text('first route'),
          },
        ),
      ),
    );

    expect(find.text('first route'), findsOneWidget);
  });

  testWidgets('Use home and named routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('go to second page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/2');
              },
            );
          },
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second named route'),
          },
        ),
      ),
    );

    expect(find.text('go to second page'), findsOneWidget);
    await tester.tap(find.text('go to second page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second named route'), findsOneWidget);
  });

  testWidgets('Use onGenerateRoute', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == Navigator.defaultRouteName) {
              return CupertinoPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) {
                  return const Text('generated home');
                },
              );
            }
            return null;
          },
        ),
      ),
    );

    expect(find.text('generated home'), findsOneWidget);
  });

  testWidgets('Use onUnknownRoute', (WidgetTester tester) async {
    String unknownForRouteCalled;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          onUnknownRoute: (RouteSettings settings) {
            unknownForRouteCalled = settings.name;
            return null;
          },
        ),
      ),
    );

    expect(tester.takeException(), isFlutterError);
    expect(unknownForRouteCalled, '/');
  });

  testWidgets('Can use navigatorKey to navigate', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          navigatorKey: key,
          builder: (BuildContext context) => const Text('first route'),
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second route'),
          },
        ),
      ),
    );

    key.currentState.pushNamed('/2');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second route'), findsOneWidget);
  });

  testWidgets('Changing the key resets the navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('go to second page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/2');
              },
            );
          },
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second route'),
          },
        ),
      ),
    );

    expect(find.text('go to second page'), findsOneWidget);
    await tester.tap(find.text('go to second page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second route'), findsOneWidget);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabView(
          key: key,
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('go to second page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/2');
              },
            );
          },
          routes: <String, WidgetBuilder>{
            '/2': (BuildContext context) => const Text('second route'),
          },
        ),
      ),
    );

    // The stack is gone and we're back to a re-built page 1.
    expect(find.text('go to second page'), findsOneWidget);
    expect(find.text('second route'), findsNothing);
  });
}
