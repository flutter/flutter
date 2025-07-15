// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/tabs/tab_bar.onFocusChange.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tabs change in response to focus', (WidgetTester tester) async {
    await tester.pumpWidget(const example.TabBarApp());

    final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.tabs.length, 3);

    expect(tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).size, 25);

    // Focus on the first tab.
    Element tabElement = tester.element(find.byIcon(Icons.cloud_outlined));
    FocusNode node = Focus.of(tabElement);
    node.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).size, 35);
    expect(tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).size, 25);

    // Move focus to the second tab
    tabElement = tester.element(find.byIcon(Icons.beach_access_sharp));
    node = Focus.of(tabElement);
    node.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).size, 35);
    expect(tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).size, 25);

    // And the third
    tabElement = tester.element(find.byIcon(Icons.brightness_5_sharp));
    node = Focus.of(tabElement);
    node.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).size, 35);

    // Unfocus
    node.unfocus();
    await tester.pump();
    await tester.pump();

    expect(tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).size, 25);
    expect(tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).size, 25);
  });
}
