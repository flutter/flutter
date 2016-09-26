// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('TickerMode', (WidgetTester tester) async {
    await tester.pumpWidget(new TickerMode(
      enabled: false,
      child: new LinearProgressIndicator()
    ));

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(new TickerMode(
      enabled: true,
      child: new LinearProgressIndicator()
    ));

    expect(tester.binding.transientCallbackCount, 1);

    await tester.pumpWidget(new TickerMode(
      enabled: false,
      child: new LinearProgressIndicator()
    ));

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('Navigation with TickerMode', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new LinearProgressIndicator(),
      routes: <String, WidgetBuilder>{
        '/test': (BuildContext context) => new Text('hello'),
      },
    ));
    expect(tester.binding.transientCallbackCount, 1);
    tester.state/*<NavigatorState>*/(find.byType(Navigator)).pushNamed('/test');
    expect(tester.binding.transientCallbackCount, 2);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.transientCallbackCount, 0);
    tester.state/*<NavigatorState>*/(find.byType(Navigator)).pop();
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.transientCallbackCount, 1);
  });
}
