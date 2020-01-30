// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
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

  test('Http Warning Message',  () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final DebugPrintCallback oldDebugPrint = debugPrint;
    String printedMessage;
    debugPrint = (String message, {int wrapWidth}) {
      printedMessage = message;
    };
    HttpClient();
    debugPrint = oldDebugPrint;
    expect(
      printedMessage,
      'Warning: At least one test in this suite creates an HttpClient. When '
      'running a test suite that uses TestWidgetsFlutterBinding, all HTTP '
      'requests will return status code 400, and no network request will '
      'actually be made. Any test expecting an real network connection and '
      'status code will fail.\n'
      'To test code that needs an HttpClient, provide your own HttpClient '
      'implementation to the code under test, so that your test can '
      'consistently provide a testable response to the code under test.',
    );
  }, skip: isBrowser); // We don't override this in the browser.
}
