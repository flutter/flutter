// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Can nest apps', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new MaterialApp(
          home: new Text('Home sweet home')
        )
      )
    );

    expect(find.text('Home sweet home'), findsOneWidget);
  });

  testWidgets('Focus handling', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new Input(key: inputKey, autofocus: true)
        )
      )
    ));

    expect(Focus.at(inputKey.currentContext), isTrue);
  });
}
