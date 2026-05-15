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
              widget is Text &&
              widget.data!.startsWith('Waiting for message...'),
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
              widget is Text &&
              widget.data!.startsWith('Waiting for message...'),
        ),
        findsOneWidget,
      );

      // Simulate a message from the java side
      print("example_test: simulating message 'fooTest' on channel");
      const channelName =
          'com.example.android_hardware_smoke_test/test_channel';
      final message = const StringCodec().encodeMessage("fooTest");
      final replyFuture = tester.binding.defaultBinaryMessenger
          .handlePlatformMessage(channelName, message, null);

      //const channel = BasicMessageChannel<String>(channelName, StringCodec());
      // print("example_test sending 'fooTest' on message channel");
      // final responseFuture = channel.send("fooTest");

      // Pump so the app can handle the message and return a reply.
      print("example_test: pump");
      await tester.pump();
      print("example_test: pump completed, awaiting channel reply");
      final ByteData? replyData = await replyFuture;
      expect(replyData, isNotNull);
      final reply = const StringCodec().decodeMessage(replyData);
      print("example_test: received channel reply, decoded to: $reply");
      expect(reply, equals("Rendered fooTest"));

      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Text && widget.data!.startsWith('fooTest'),
        ),
        findsOneWidget,
      );

      await expectLater(find.byKey(app.targetKey), matchesGoldenFile('goldens/fooTest.png'));

      // final response = await responseFuture;
      // print("example_test received channel reply $response");
      // expect(response, 'Rendered fooTest');
      // expect(
      //   find.byWidgetPredicate(
      //     (Widget widget) =>
      //         widget is Text && widget.data!.startsWith('fooTest'),
      //   ),
      //   findsOneWidget,
      // );
      //expect(response, 'Mocked fooTest');
      //await Future.delayed(Duration(seconds: 3));
    });
  });
}
