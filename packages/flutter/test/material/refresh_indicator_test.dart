// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {

  bool refreshCalled = false;

  Future<Null> refresh() {
    refreshCalled = true;
    return new Future<Null>.value();
  }

  testWidgets('RefreshIndicator', (WidgetTester tester) {
    tester.pumpWidget(
      new RefreshIndicator(
        refresh: refresh,
        child: new Block(
          children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map((String item) {
            return new SizedBox(
              height: 200.0,
              child: new Text(item)
            );
          }).toList()
        )
      )
    );

    tester.fling(find.text('A'), const Offset(0.0, 200.0), -1000.0);
    tester.pump();
    tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
  });
}
