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
  test('throws assertion error if WidgetsFlutterBinding is not yet initialized', () {
    const MethodChannel methodChannel = MethodChannel('mock');

    // This used to throw _CastError:<Null check operator used on a null value>
    // before the assertion was added, which we want to avoid in order to hint
    // callers towards how to fix the error.
    expect(() => methodChannel.setMethodCallHandler(null), throwsAssertionError);
  });

  test('does not throw when WidgetsFlutterBinding is already initialized', () {
    const MethodChannel methodChannel = MethodChannel('mock');

    TestWidgetsFlutterBinding.ensureInitialized();
    expect(() => methodChannel.setMethodCallHandler(null), returnsNormally);
  });
}
