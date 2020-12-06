// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manual_tests/color_testing_demo.dart' as color_testing_demo;

import 'mock_image_http.dart';

void main() {
  testWidgets('Color testing demo smoke test', (WidgetTester tester) async {
    HttpOverrides.runZoned<Future<void>>(() async {
      color_testing_demo.main(); // builds the app and schedules a frame but doesn't trigger one
      await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
      await tester.pump(); // triggers a frame

      await tester.dragFrom(const Offset(0.0, 500.0), const Offset(0.0, 0.0)); // scrolls down
      await tester.pump();

      await tester.dragFrom(const Offset(0.0, 500.0), const Offset(0.0, 0.0)); // scrolls down
      await tester.pump();
    }, createHttpClient: createMockImageHttpClient);
  });
}
