// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Drawer control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        drawer: new Drawer(
          child: new Block(
            children: <Widget>[
              new DrawerHeader(
                content: new Text('header')
              ),
              new DrawerItem(
                icon: new Icon(Icons.archive),
                child: new Text('Archive')
              )
            ]
          )
        )
      )
    );

    expect(find.text('Archive'), findsNothing);
    ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Archive'), findsOneWidget);
  });
}
