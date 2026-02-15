// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// This test checks that we output something on test failure where the test
// creates an HttpClient.
// It should not be run as part of a normal test suite, as it is expected to
// fail. See dev/bots/test.dart, which runs this test, checks that it fails,
// and prints the expected warning about HttpClient usage.
// We don't run this for browser tests, since we don't override the behavior
// in browser tests.

void main() {
  test('Http Warning Message', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpClient();
    // Make sure we only add the message once.
    HttpClient();
    HttpClient();
    fail('Intentional');
  });
}
