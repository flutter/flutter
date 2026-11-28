// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_view/main.dart' as flutter_view;

void main() {
  testWidgets('FlutterView smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const flutter_view.FlutterView());

    // The counter starts at zero.
    expect(find.text('Platform button tapped 0 times.'), findsOneWidget);

    // The Flutter logo asset and label are rendered.
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.byType(flutter_view.FlutterView), findsOneWidget);
  });

  testWidgets('incrementing via the platform channel updates the counter text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const flutter_view.FlutterView());

    expect(find.text('Platform button tapped 0 times.'), findsOneWidget);

    // Simulate the host platform sending an increment message.
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'increment',
      const StringCodec().encodeMessage('increment'),
      (ByteData? data) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Platform button tapped 1 time.'), findsOneWidget);
  });

  testWidgets('tapping the FAB sends a pong message to the platform', (WidgetTester tester) async {
    String? lastSentMessage;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'increment',
      (ByteData? message) async {
        lastSentMessage = const StringCodec().decodeMessage(message);
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'increment',
        null,
      );
    });

    await tester.pumpWidget(const flutter_view.FlutterView());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(lastSentMessage, 'pong');
  });
}
