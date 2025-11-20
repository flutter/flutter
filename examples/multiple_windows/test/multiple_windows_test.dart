// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_windows/main.dart' as multiple_windows;

void main() {
  testWidgets('Multiple windows smoke test', (WidgetTester tester) async {
    multiple_windows
        .main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // triggers a frame

    expect(find.text('Multi Window Reference App'), findsOneWidget);
  });
}
