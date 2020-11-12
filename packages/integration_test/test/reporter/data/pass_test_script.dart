// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized() as IntegrationTestWidgetsFlutterBinding;

  testWidgets('Passing test 1', (WidgetTester tester) async {
    expect(true, true);
  });

  testWidgets('Passing test 2', (WidgetTester tester) async {
    expect(true, true);
  });

  tearDownAll(() {
    print(
        'IntegrationTestWidgetsFlutterBinding test results: ${testResultsToJson(binding.results)}');
  });
}
