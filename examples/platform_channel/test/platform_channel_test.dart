// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:platform_channel/main.dart' as platform_channel;

void main() {
  testWidgets('Platform channel smoke test', (WidgetTester tester) async {
    platform_channel.main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // triggers a frame

    expect(find.textContaining('Battery level: '), findsOneWidget);
  });
}
