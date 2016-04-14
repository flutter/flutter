// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

import '../lib/main.dart' as hello_world;

void main() {
  test("Hello world smoke test", () {
    testWidgets((WidgetTester tester) {
      hello_world.main(); // builds the app and schedules a frame but doesn't trigger one
      tester.pump(); // triggers a frame

      expect(tester, hasWidget(find.text('Hello, world!')));
    });
  });
}
