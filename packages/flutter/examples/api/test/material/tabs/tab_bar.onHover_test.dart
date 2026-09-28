// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/tabs/tab_bar.onHover.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tabs change in response to hover', (WidgetTester tester) async {
    await tester.pumpWidget(const example.TabBarApp());

    final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.tabs.length, 3);

    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).color,
      Colors.purple,
    );

    // Hover over the first tab.
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.cloud_outlined)));
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
      Colors.pink,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).color,
      Colors.purple,
    );

    // Hover over the second tab
    await gesture.moveTo(
      tester.getCenter(find.byIcon(Icons.beach_access_sharp)),
    );
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).color,
      Colors.pink,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).color,
      Colors.purple,
    );

    // And the third
    await gesture.moveTo(
      tester.getCenter(find.byIcon(Icons.brightness_5_sharp)),
    );
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).color,
      Colors.pink,
    );

    // Remove hover
    await gesture.removePointer();
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.beach_access_sharp)).color,
      Colors.purple,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.brightness_5_sharp)).color,
      Colors.purple,
    );
  });
}
