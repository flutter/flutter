// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Alert dialog control test', (WidgetTester tester) async {
    bool didDelete = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new Builder(
            builder: (BuildContext context) {
              return new RaisedButton(
                onPressed: () {
                  showDialog<Null>(
                    context: context,
                    child: new CupertinoAlertDialog(
                      title: new Text('The title'),
                      content: new Text('The content'),
                      actions: <Widget>[
                        new CupertinoDialogAction(
                          child: new Text('Cancel'),
                        ),
                        new CupertinoDialogAction(
                          isDestructive: true,
                          onPressed: () {
                            didDelete = true;
                            Navigator.pop(context);
                          },
                          child: new Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: new Text('Go'),
              );
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(didDelete, isFalse);

    await tester.tap(find.text('Delete'));

    expect(didDelete, isTrue);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('Dialog action styles', (WidgetTester tester) async {
    await tester.pumpWidget(new CupertinoDialogAction(
      isDestructive: true,
      child: new Text('Ok'),
    ));

    DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color.red, greaterThan(widget.style.color.blue));
    expect(widget.style.color.alpha, lessThan(255));
  });
}
