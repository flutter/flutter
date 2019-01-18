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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const CircularProgressIndicator(),
              RepaintBoundary(
                child: PerformanceOverlay.mock(),
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
