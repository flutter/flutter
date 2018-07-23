// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BackButton control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(child: Text('Home')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const Material(
              child: Center(
                child: BackButton(),
              )
            );
          },
        }
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('BackButton icon', (WidgetTester tester) async {
    final Key iOSKey = new UniqueKey();
    final Key androidKey = new UniqueKey();


    await tester.pumpWidget(
      new MaterialApp(
        home: new Column(
          children: <Widget>[
            new Theme(
              data: new ThemeData(platform: TargetPlatform.iOS),
              child: new BackButtonIcon(key: iOSKey),
            ),
            new Theme(
              data: new ThemeData(platform: TargetPlatform.android),
              child: new BackButtonIcon(key: androidKey),
            ),
          ],
        ),
      ),
    );

    final Icon iOSIcon = tester.widget(find.descendant(of: find.byKey(iOSKey), matching: find.byType(Icon)));
    final Icon androidIcon = tester.widget(find.descendant(of: find.byKey(androidKey), matching: find.byType(Icon)));
    expect(iOSIcon == androidIcon, false);
  });

  testWidgets('BackButton semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(child: Text('Home')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const Material(
              child: Center(
                child: BackButton(),
              ),
            );
          },
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pumpAndSettle();

    expect(tester.getSemanticsData(find.byType(BackButton)), matchesSemanticsData(
      label: 'Back',
      isButton: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
    ));
    handle.dispose();
  });
}
