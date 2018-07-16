// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('TickerMode', (WidgetTester tester) async {
    const Widget widget = const TickerMode(
      enabled: false,
      child: const CircularProgressIndicator()
    );
    expect(widget.toString, isNot(throwsException));

    await tester.pumpWidget(widget);

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(const TickerMode(
      enabled: true,
      child: const CircularProgressIndicator()
    ));

    expect(tester.binding.transientCallbackCount, 1);

    await tester.pumpWidget(const TickerMode(
      enabled: false,
      child: const CircularProgressIndicator()
    ));

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('Navigation with TickerMode', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: const LinearProgressIndicator(),
      routes: <String, WidgetBuilder>{
        '/test': (BuildContext context) => const Text('hello'),
      },
    ));
    expect(tester.binding.transientCallbackCount, 1);
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/test');
    expect(tester.binding.transientCallbackCount, 2);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.transientCallbackCount, 0);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('SingleTickerProviderStateMixin can handle not being used', (WidgetTester tester) async {
    final Widget widget = new BoringTickerTest();
    expect(widget.toString, isNot(throwsException));

    await tester.pumpWidget(widget);
    await tester.pumpWidget(new Container());
    // the test is that this doesn't crash, like it used to...
  });
}

class BoringTickerTest extends StatefulWidget {
  @override
  _BoringTickerTestState createState() => new _BoringTickerTestState();
}

class _BoringTickerTestState extends State<BoringTickerTest> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => new Container();
}
