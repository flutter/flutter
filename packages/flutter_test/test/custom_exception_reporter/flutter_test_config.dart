// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main(FutureOr<void> testMain()) async {
  reportTestException = (FlutterErrorDetails details, String testDescription) {
    expect(details.exception, isA<StateError>());
    expect(details.exception.message, 'foo');
    expect(testDescription, 'custom exception reporter');
  };

  // The error that the test throws in [runTest] will be forwarded to our
  // reporter and should not cause the test to fail.
  await testMain();
}

void runTest() {
  testWidgets('custom exception reporter', (WidgetTester tester) {
    throw StateError('foo');
  });
}
