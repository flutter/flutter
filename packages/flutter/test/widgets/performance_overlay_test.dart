// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Performance overlay smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PerformanceOverlay());
    await tester.pumpWidget(PerformanceOverlay.allEnabled());
  });

  testWidgets('Performance overlay golden test', (WidgetTester tester) async {
    final List<int> mockData = <int>[
      17, 1,  4,  24, 4,  25, 30, 4,  13, 34,
      14, 0,  18, 9,  32, 36, 26, 23, 5,  8,
      32, 18, 29, 16, 29, 18, 0,  36, 33, 10];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const CircularProgressIndicator(),
              RepaintBoundary(
                child: PerformanceOverlay.allEnabled(mockData: mockData),
              )
            ],
          )
        ),
      )
    );

    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('performance_overlay.golden.1.png'),
      skip: !Platform.isLinux, // golden test should only run on Linux
    );
  });
}
