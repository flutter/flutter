// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:android_hardware_smoke_test/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the native platform MethodChannel to prevent MissingPluginException during tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(
            "com.example.android_hardware_smoke_test/native_support",
          ),
          (MethodCall methodCall) async {
            if (methodCall.method == "impeller_backend") {
              return "vulkan";
            }
            return null;
          },
        );
  });

  testWidgets("MyWidget displays default layout and waiting message on boot", (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the default waiting message renders perfectly
    expect(find.text("Waiting for message..."), findsOneWidget);

    // Verify that the exact targetRepaintBoundary renders by checking the targetKey
    expect(find.byKey(targetKey), findsOneWidget);

    // Verify that our specific custom painter canvas is built and renders MyPainter
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is MyPainter,
      ),
      findsOneWidget,
    );

    // Verify that the basic structural elements SafeArea and Stack are present
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(Stack), findsOneWidget);
  });
}
