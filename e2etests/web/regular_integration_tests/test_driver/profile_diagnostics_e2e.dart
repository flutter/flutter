// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/profile_diagnostics_main.dart' as app;

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App build method exception should form valid FlutterErrorDetails',
          (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    final dynamic appError = tester.takeException();
    expect(appError, isA<TypeError>());
  });
}
