// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlexibleSpaceBar centers title on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('X')
            )
          )
        )
      )
    );

    final Finder title = find.text('X');
    Offset center = tester.getCenter(title);
    Size size = tester.getSize(title);
    expect(center.dx, lessThan(400.0 - size.width / 2.0));

    // Clear the widget tree to avoid animating between Android and iOS.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('X')
            )
          )
        )
      )
    );

    center = tester.getCenter(title);
    size = tester.getSize(title);
    expect(center.dx, greaterThan(400.0 - size.width / 2.0));
    expect(center.dx, lessThan(400.0 + size.width / 2.0));
  });
}
