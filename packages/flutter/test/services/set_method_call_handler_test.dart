// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // We need a separate test file for this test case (instead of including it
  // in platform_channel_test.dart) since we rely on the WidgetsFlutterBinding
  // not being initialized and we call ensureInitialized() in the other test
  // file.
  test('throws assertion error iff WidgetsFlutterBinding is not yet initialized', () {
    const methodChannel = MethodChannel('mock');

    // Verify an assertion error is thrown before the binary messenger is
    // accessed (which would result in a _CastError due to the non-null
    // assertion). This way we can hint the caller towards how to fix the error.
    expect(() => methodChannel.setMethodCallHandler(null), throwsAssertionError);

    // Verify the assertion is not thrown once the binding has been initialized.
    // This cannot be a separate test case since the execution order is random.
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(() => methodChannel.setMethodCallHandler(null), returnsNormally);
  });
}
