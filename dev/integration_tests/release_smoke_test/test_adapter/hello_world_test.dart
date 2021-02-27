// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:release_smoke_test/main.dart' as smoke;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hello world smoke test', (WidgetTester tester) async {
    smoke.main(); // builds the app and schedules a frame but doesn't trigger one

    await tester.pump(); // triggers a frame

    expect(find.text('Hello, world!'), findsOneWidget);
  });
}
