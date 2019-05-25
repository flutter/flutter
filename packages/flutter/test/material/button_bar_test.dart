// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ButtonBar default control smoketest', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ButtonBar(),
      ),
    );
  });

  testWidgets('ButtonBar has a min height of 52 when using ButtonBarLayoutBehavior.constrained', (WidgetTester tester) async {
    await tester.pumpWidget(
      SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            ButtonTheme.bar(
              layoutBehavior: ButtonBarLayoutBehavior.constrained,
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: ButtonBar(
                  children: <Widget>[
                    SizedBox(width: 10.0, height: 10.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Finder buttonBar = find.byType(ButtonBar);
    expect(tester.getBottomRight(buttonBar).dy - tester.getTopRight(buttonBar).dy, 52.0);
  });

  testWidgets('ButtonBar has padding applied when using ButtonBarLayoutBehavior.padded', (WidgetTester tester) async {
    await tester.pumpWidget(
      SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            ButtonTheme.bar(
              layoutBehavior: ButtonBarLayoutBehavior.padded,
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: ButtonBar(
                  children: <Widget>[
                    SizedBox(width: 10.0, height: 10.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Finder buttonBar = find.byType(ButtonBar);
    expect(tester.getBottomRight(buttonBar).dy - tester.getTopRight(buttonBar).dy, 26.0);
  });

  testWidgets('ButtonBar FlatButton inherits Theme accentColor', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/22789

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(accentColor: const Color(1)),
        home: Builder(
          builder: (BuildContext context) {
            return Center(
              child: ButtonTheme.bar(
                child: ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: const Text('button'),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog( // puts its actions in a ButtonBar
                              actions: <Widget>[
                                FlatButton(
                                  onPressed: () { },
                                  child: const Text('enabled'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(tester.widget<RawMaterialButton>(find.byType(RawMaterialButton)).textStyle.color, const Color(1));

    // Show the dialog
    await tester.tap(find.text('button'));
    await tester.pumpAndSettle();

    final Finder dialogButton = find.ancestor(
      of: find.text('enabled'),
      matching: find.byType(RawMaterialButton),
    );
    expect(tester.widget<RawMaterialButton>(dialogButton).textStyle.color, const Color(1));
  });
}
