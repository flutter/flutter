// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a Flutter widget test can take a screenshot.
//
// NOTE: Screenshots are only supported on Web for now. For Web, this needs to
// be executed with the `test_driver/integration_test_extended_driver.dart`.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:integration_test/integration_test.dart';

import '_extended_test_io.dart' if (dart.library.html) '_extended_test_web.dart'
    as tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tests.main();
}
