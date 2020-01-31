// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// This test checks that we output something on test failure.
// It should not be run as part of a normal test suite, as it is expected to
// fail.  See dev/bots/test.dart, which runs this test and checks that it fails
// and prints the expected warning about HttpClient usage in a failing test.

void main() {
  test('Http Warning Message', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpClient();
    // Make sure we only add the message once.
    HttpClient();
    HttpClient();
    fail('Intentional');
  }); // We don't override this in the browser.
}
