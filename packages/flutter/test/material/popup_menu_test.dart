// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Navigator.push works within a PopupMenuButton', (WidgetTester tester) async {
    final Key targetKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        routes: <String, WidgetBuilder> {
          '/next': (BuildContext context) {
            return const Text('Next');
          },
        },
        home: new Material(
          child: new Center(
            child: new Builder(
              key: targetKey,
              builder: (BuildContext context) {
                return new PopupMenuButton<int>(
                  onSelected: (int value) {
                    Navigator.pushNamed(context, '/next');
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuItem<int>>[
                      const PopupMenuItem<int>(
                        value: 1,
                        child: const Text('One')
                      ),
                    ];
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(targetKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('One'));
    await tester.pump(); // return the future
    await tester.pump(); // start the navigation
    await tester.pump(const Duration(seconds: 1)); // end the navigation

    expect(find.text('One'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('PopupMenuButton is horizontal on iOS', (WidgetTester tester) async {
    Widget build(TargetPlatform platform) {
      return new MaterialApp(
        theme: new ThemeData(platform: platform),
        home: new Scaffold(
          appBar: new AppBar(
            actions: <Widget>[
              new PopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <PopupMenuItem<int>>[
                    const PopupMenuItem<int>(
                      value: 1,
                      child: const Text('One')
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(TargetPlatform.android));

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    await tester.pumpWidget(build(TargetPlatform.iOS));
    await tester.pumpAndSettle(); // Run theme change animation.

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });
}
