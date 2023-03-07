// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/app_lifecycle_listener/app_lifecycle_listener.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppLifecycleListener example', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.AppLifecycleListenerExample(),
    );

    expect(find.text('No exit requested yet'), findsOneWidget);
    expect(find.text('Do Not Allow Exit'), findsOneWidget);
    expect(find.text('Allow Exit'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    await tester.tap(find.text('Quit'));
    await tester.pump();
    expect(find.text('App requesting cancelable exit'), findsOneWidget);
  });
}
