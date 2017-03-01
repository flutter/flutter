// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BackButton control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(child: new Text('Home')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Material(
              child: new Center(
                child: const BackButton(),
              )
            );
          },
        }
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pumpUntilNoTransientCallbacks();

    await tester.tap(find.byType(BackButton));

    await tester.pump();
    await tester.pumpUntilNoTransientCallbacks();

    expect(find.text('Home'), findsOneWidget);
  });
}
