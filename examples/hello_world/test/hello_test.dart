// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/main.dart' as hello_world;

void main() {
  testWidgets('Hello world smoke test', (WidgetTester tester) async {
    hello_world.main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // triggers a frame

    expect(find.text('Hello, world!'), findsOneWidget);
  });
}
