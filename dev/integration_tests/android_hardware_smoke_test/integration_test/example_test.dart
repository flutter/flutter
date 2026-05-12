// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/services.dart';
// import 'dart:convert';
// import 'dart:typed_data';

import 'package:android_hardware_smoke_test/main.dart' as app;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('verify default text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    app.main();

    // Trace the timeline of the following operation. The timeline result will
    // be written to `build/integration_response_data.json` with the key
    // `timeline`.
    await binding.traceAction(() async {
      // Trigger a frame.
      await tester.pumpAndSettle();

      // Verify that platform version is retrieved.
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Text && widget.data!.startsWith('Waiting for message...'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('verify method channel', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    app.main();

    // Trace the timeline of the following operation. The timeline result will
    // be written to `build/integration_response_data.json` with the key
    // `timeline`.
    await binding.traceAction(() async {
      // Trigger a frame.
      await tester.pumpAndSettle();

      // Verify that platform version is retrieved.
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Text && widget.data!.startsWith('Waiting for message...'),
        ),
        findsOneWidget,
      );

      const channelName = 'com.example.android_hardware_smoke_test/test_channel';

      // Set mock handler to intercept messages
      // tester.binding.defaultBinaryMessenger.setMockMessageHandler(channelName,
      // (ByteData? data) {
      //   final String message = utf8.decode(data!.buffer.asUint8List());
      //   print("mock message handler received message: $message");
      //   //expect(value, equals("Rendered foo"));
      //   final Uint8List responseBytes = utf8.encode('Mocked $message');
      //   return Future.value(responseBytes.buffer.asByteData());
      // });

      const channel = BasicMessageChannel<String>(channelName, StringCodec());
      final responseFuture = channel.send("fooTest");
      await tester.pumpAndSettle();
      final response = await responseFuture;
      expect(response, 'Rendered fooTest');
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Text && widget.data!.startsWith('fooTest'),
        ),
        findsOneWidget,
      );
      //expect(response, 'Mocked fooTest');
      //await Future.delayed(Duration(seconds: 3));

      // clean up
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(channelName, null);
    });
  });
}
