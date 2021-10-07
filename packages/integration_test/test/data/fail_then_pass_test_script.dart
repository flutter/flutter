// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> main() async {
  final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized() as IntegrationTestWidgetsFlutterBinding;
  binding.allTestsPassed.future.then((_) {
    print('IntegrationTestWidgetsFlutterBinding test results: ${jsonEncode(binding.results)}');
  });

  testWidgets('failing test', (WidgetTester tester) async {
    expect(true, false);
  });

  testWidgets('passing test', (WidgetTester tester) async {
    expect(true, true);
  });
}
