// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Back during pushReplacement', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Material(child: Text('home')),
      routes: <String, WidgetBuilder> {
        '/a': (BuildContext context) => const Material(child: Text('a')),
        '/b': (BuildContext context) => const Material(child: Text('b')),
      },
    ));

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/a');
    await tester.pumpAndSettle();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    navigator.pushReplacementNamed('/b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    navigator.pop();

    await tester.pumpAndSettle();

    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('pushAndRemoveUntil', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Material(child: Text('home')),
      routes: <String, WidgetBuilder> {
        '/a': (BuildContext context) => const Material(child: Text('a')),
        '/b': (BuildContext context) => const Material(child: Text('b')),
      },
    ));

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/a');
    await tester.pumpAndSettle();

    expect(find.text('home', skipOffstage: false), findsOneWidget);
    expect(find.text('a', skipOffstage: false), findsOneWidget);
    expect(find.text('b', skipOffstage: false), findsNothing);

    navigator.pushNamedAndRemoveUntil('/b', (Route<dynamic> route) => false);
    await tester.pumpAndSettle();

    expect(find.text('home', skipOffstage: false), findsNothing);
    expect(find.text('a', skipOffstage: false), findsNothing);
    expect(find.text('b', skipOffstage: false), findsOneWidget);

    navigator.pushNamed('/');
    await tester.pumpAndSettle();

    expect(find.text('home', skipOffstage: false), findsOneWidget);
    expect(find.text('a', skipOffstage: false), findsNothing);
    expect(find.text('b', skipOffstage: false), findsOneWidget);

    navigator.pushNamedAndRemoveUntil('/a', ModalRoute.withName('/b'));
    await tester.pumpAndSettle();

    expect(find.text('home', skipOffstage: false), findsNothing);
    expect(find.text('a', skipOffstage: false), findsOneWidget);
    expect(find.text('b', skipOffstage: false), findsOneWidget);
  });
}
