// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dialog is scrollable', (WidgetTester tester) async {
    bool didPressOk = false;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: new Text('X'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      child: new AlertDialog(
                        content: new Container(
                          height: 5000.0,
                          width: 300.0,
                          decoration: new BoxDecoration(
                            backgroundColor: Colors.green[500]
                          )
                        ),
                        actions: <Widget>[
                          new FlatButton(
                            onPressed: () {
                              didPressOk = true;
                            },
                            child: new Text('OK')
                          )
                        ]
                      )
                    );
                  }
                )
              );
            }
          )
        )
      )
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    expect(didPressOk, false);
    await tester.tap(find.text('OK'));
    expect(didPressOk, true);
  });
  
  testWidgets('Dialog background color', (WidgetTester tester) async {

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: new Text('X'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      child: new AlertDialog(
                        content: new Text('Y'),
                        actions: <Widget>[
                        ]
                      )
                    );
                  }
                )
              );
            }
          )
        )
      )
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    StatefulElement widget = tester.element(find.byType(Material).last);
    Material materialconfig = widget.state.config;
    //first and second expect check that the material is the dialog's one
    expect(materialconfig.type, MaterialType.card);
    expect(materialconfig.elevation, 24);
    expect(materialconfig.color, Colors.grey[800]);
  });
}
