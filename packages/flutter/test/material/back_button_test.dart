// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BackButton control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(child: const Text('Home')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Material(
              child: const Center(
                child: const BackButton(),
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
}
