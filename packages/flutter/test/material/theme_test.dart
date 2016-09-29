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
          data: new ThemeData(brightness: Brightness.light),
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

  testWidgets('DropdownMenu inherits shadowed app theme', (WidgetTester tester) async {
    final Key dropdownMenuButtonKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            appBar: new AppBar(
              actions: <Widget>[
                new DropdownButton<String>(
                  key: dropdownMenuButtonKey,
                  onChanged: (String newValue) { },
                  value: 'menuItem',
                  items: <DropdownMenuItem<String>>[
                    new DropdownMenuItem<String>(
                      value: 'menuItem',
                      child: new Text('menuItem'),
                    ),
                  ],
                )
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.byKey(dropdownMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    for(Element item in tester.elementList(find.text('menuItem')))
      expect(Theme.of(item).brightness, equals(Brightness.light));
  });

  testWidgets('ModalBottomSheet inherits shadowed app theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            body: new Center(
              child: new Builder(
                builder: (BuildContext context) {
                  return new RaisedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) => new Text('bottomSheet'),
                      );
                    },
                    child: new Text('SHOW'),
                  );
                }
              )
            )
          )
        )
      )
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('bottomSheet'))).brightness, equals(Brightness.light));

    await tester.tap(find.text('bottomSheet')); // dismiss the bottom sheet
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Dialog inherits shadowed app theme', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            key: scaffoldKey,
            body: new Center(
              child: new Builder(
                builder: (BuildContext context) {
                  return new RaisedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        child: new Text('dialog'),
                      );
                    },
                    child: new Text('SHOW'),
                  );
                }
              )
            )
          )
        )
      )
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('dialog'))).brightness, equals(Brightness.light));
  });

}
