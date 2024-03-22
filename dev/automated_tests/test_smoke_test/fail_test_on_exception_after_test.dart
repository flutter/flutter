// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// This is a test to make sure that an asynchronous exception thrown after a
// test ended actually causes a test failure.
// See //flutter/dev/bots/test.dart

void main() {
  final Completer<void> complete = Completer<void>();

  testWidgets('test smoke test -- this test SHOULD FAIL', (WidgetTester tester) async {
    tester.runAsync(() async {
      Timer.run(() {
        complete.complete();
        throw StateError('Exception thrown after test completed.');
      });
    });
  });

  tearDown(() async {
    print('Waiting for asynchronous exception...');
    await complete.future;
  });
}
