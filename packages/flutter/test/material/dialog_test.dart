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
}
