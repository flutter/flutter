// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScrollableState> scrollableKey = new GlobalKey<ScrollableState>();

void main() {
  bool refreshCalled = false;

  Future<Null> refresh() {
    refreshCalled = true;
    return new Future<Null>.value();
  }

  testWidgets('RefreshIndicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      new RefreshIndicator(
        scrollableKey: scrollableKey,
        refresh: refresh,
        child: new Block(
          scrollableKey: scrollableKey,
          children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map((String item) {
            return new SizedBox(
              height: 200.0,
              child: new Text(item)
            );
          }).toList()
        )
      )
    );

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), -1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
  });
}
