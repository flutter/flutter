// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for https://github.com/flutter/flutter/issues/111285
void main() {
  testWidgets('Can load asset from same package without error', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final imageError = Completer<void>();
      final FlutterExceptionHandler? originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        originalOnError?.call(details);
        imageError.complete();
      };
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Image.asset('assets/foo.png', package: 'integration_ui')),
          ),
        );
        await imageError.future;
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    // If this asset couldn't be loaded, the exception message would be
    // "asset failed to load"
    expect(tester.takeException().toString(), contains('Invalid image data'));
  });
}
