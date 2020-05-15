// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/profile_diagnostics_main.dart' as app;

import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;

  testWidgets('App build method exception should form valid FlutterErrorDetails',
          (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    final dynamic appError = tester.takeException();
    expect(appError, isA<TypeError>());
  });
}
