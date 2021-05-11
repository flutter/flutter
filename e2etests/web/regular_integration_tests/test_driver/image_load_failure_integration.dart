// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/image_load_failure_main.dart' as app;

import 'package:integration_test/integration_test.dart';

/// Tests
void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized()
          as IntegrationTestWidgetsFlutterBinding;
  testWidgets('Image load fails on incorrect asset',
          (WidgetTester tester) async {
    final StringBuffer buffer = StringBuffer();
    await runZoned(() async {
      app.main();
      await tester.pumpAndSettle();
    }, zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          buffer.writeln(line);
    }));
    final dynamic exception1 = tester.takeException();
    expect(exception1, isNotNull);
  });
}
