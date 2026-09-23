// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:web_e2e_tests/deferred_loading_lib.dart' deferred as deferred_lib;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deferred library loading works on web', (WidgetTester tester) async {
    runApp(const MaterialApp(home: Scaffold(body: Text('Initial State'))));
    await tester.pumpAndSettle();

    // Load the deferred library and call code within it.
    await deferred_lib.loadLibrary();

    final int value = deferred_lib.getDeferredValue();
    expect(value, equals(42));
    await tester.pumpAndSettle();
  });
}
