// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_api_samples/cupertino/switch/cupertino_switch.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Toggling cupertino switch updates icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CupertinoSwitchApp(),
    );

    final Finder switchFinder = find.byType(CupertinoSwitch);
    CupertinoSwitch cupertinoSwitch = tester.widget<CupertinoSwitch>(switchFinder);
    final Finder wifiOnIcon = find.byIcon(CupertinoIcons.wifi);
    final Finder wifiOffIcon = find.byIcon(CupertinoIcons.wifi_slash);
    expect(cupertinoSwitch.value, true);
    // When the switch is on, wifi icon should be visible.
    expect(wifiOnIcon, findsOneWidget);
    expect(wifiOffIcon, findsNothing);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    cupertinoSwitch = tester.widget<CupertinoSwitch>(switchFinder);
    expect(cupertinoSwitch.value, false);
    // When the switch is off, wifi slash icon should be visible.
    expect(wifiOnIcon, findsNothing);
    expect(wifiOffIcon, findsOneWidget);
  });
}
