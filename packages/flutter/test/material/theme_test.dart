// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PopupMenu inherits app theme', (WidgetTester tester) async {
    final Key popupMenuButtonKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Scaffold(
          appBar: new AppBar(
            actions: <Widget>[
              new PopupMenuButton<String>(
                key: popupMenuButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuItem<String>>[
                    new PopupMenuItem<String>(child: new Text('menuItem'))
                  ];
                }
              ),
            ]
          )
        )
      )
    );

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(find.text('menuItem'))).brightness, equals(Brightness.dark));
  });

  testWidgets('PopupMenu inherits shadowed app theme', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5572
    final Key popupMenuButtonKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light), // the shadow theme
          child: new Scaffold(
            appBar: new AppBar(
              actions: <Widget>[
                new PopupMenuButton<String>(
                  key: popupMenuButtonKey,
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuItem<String>>[
                      new PopupMenuItem<String>(child: new Text('menuItem'))
                    ];
                  }
                ),
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(find.text('menuItem'))).brightness, equals(Brightness.light));
  });
}
