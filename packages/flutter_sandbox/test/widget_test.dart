// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_sandbox/src/main.dart' as app;

void main() {
  testWidgets('Application displays greeting message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    app.main();

    // Verify that our counter starts at 0.
    expect(find.text('Hot restart (R) to begin developing'), findsOneWidget);
  });
}
