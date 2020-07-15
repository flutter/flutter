// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package;

void main() {
  group(TestViewConfiguration, () {
    test('is initialized with top-level window if one is not provided', () {
      // The code below will throw without the default.
      TestViewConfiguration(size: const Size(1280.0, 800.0));
    });
  });

  group(AutomatedTestWidgetsFlutterBinding, () {
    test('allows setting defaultTestTimeout to 5 minutes', () {
      final AutomatedTestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();
      binding.defaultTestTimeout = const test_package.Timeout(Duration(minutes: 5));
      expect(binding.defaultTestTimeout.duration, const Duration(minutes: 5));
    });
  });

  test('Initializes httpOverrides and testTextInput', () async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
    expect(binding.testTextInput.isRegistered, true);
    expect(HttpOverrides.current, isNotNull);
  });
}
