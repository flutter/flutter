// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:android_hardware_smoke_test/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image testImage;

  setUp(() async {
    testImage = await createTestImage(width: 10, height: 10);

    // Mock the native platform MethodChannel to prevent MissingPluginException during tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(
            'com.example.android_hardware_smoke_test/native_support',
          ),
          (MethodCall methodCall) async {
            if (methodCall.method == 'impeller_backend') {
              return 'vulkan';
            }
            return null;
          },
        );
  });

  testWidgets('MyWidget displays default layout and waiting message on boot', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the default waiting message renders perfectly
    expect(find.text('Waiting for message...'), findsOneWidget);

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

  testWidgets('imageTest message channel handler - success behavior', (
    WidgetTester tester,
  ) async {
    // Inject a mock imageLoader returning our pre-created testImage
    await tester.pumpWidget(MyApp(imageLoader: () async => testImage));

    final ByteData encodedMessage = const JSONMessageCodec()
        .encodeMessage(<String, Object?>{
          'testName': 'imageTest',
          'performAppSideGoldenCompare': false,
          'captureScreenshot': false,
        })!;

    // Send the message to invoke the app's channel handler
    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(
          'com.example.android_hardware_smoke_test/test_channel',
          encodedMessage,
          null,
        );

    // Pump frames to resolve the image load and post-frame callback in fake time
    await tester.pump(); // Triggers build with loaded image
    await tester.pump(); // Triggers post-frame callback

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>)
        .cast<String, Object?>();
    expect(replyMap['message'], equals('Rendered imageTest'));
    expect(replyMap['imageBytes'], isNull);

    final CustomPaint customPaint = tester.widget(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is MyPainter,
      ),
    );
    final MyPainter painter = customPaint.painter! as MyPainter;
    expect(painter.loadedImage, isNotNull);
  });

  testWidgets('imageTest message channel handler - failure behavior', (
    WidgetTester tester,
  ) async {
    // Inject a mock imageLoader that immediately throws an exception
    await tester.pumpWidget(
      MyApp(
        imageLoader: () async {
          throw Exception('Mock image load failure');
        },
      ),
    );

    final ByteData encodedMessage = const JSONMessageCodec()
        .encodeMessage(<String, Object?>{
          'testName': 'imageTest',
          'performAppSideGoldenCompare': false,
          'captureScreenshot': false,
        })!;

    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(
          'com.example.android_hardware_smoke_test/test_channel',
          encodedMessage,
          null,
        );

    // Pump a frame to let the handler complete
    await tester.pump();

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>)
        .cast<String, Object?>();
    expect(replyMap['message'], contains('Failed to load image asset'));
    expect(replyMap['imageBytes'], isNull);
  });

  testWidgets('advancedBlendTest message channel handler - success behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final ByteData encodedMessage = const JSONMessageCodec()
        .encodeMessage(<String, Object?>{
          'testName': 'advancedBlendTest',
          'performAppSideGoldenCompare': false,
          'captureScreenshot': false,
        })!;

    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(
          'com.example.android_hardware_smoke_test/test_channel',
          encodedMessage,
          null,
        );

    await tester.pump();
    await tester.pump();

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>)
        .cast<String, Object?>();
    expect(replyMap['message'], equals('Rendered advancedBlendTest'));

    final CustomPaint customPaint = tester.widget(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is MyPainter,
      ),
    );
    final MyPainter painter = customPaint.painter! as MyPainter;
    expect(painter.message, equals('advancedBlendTest'));
  });

  testWidgets(
    'backdropFilterBlurTest message channel handler - success behavior',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final ByteData encodedMessage = const JSONMessageCodec()
          .encodeMessage(<String, Object?>{
            'testName': 'backdropFilterBlurTest',
            'performAppSideGoldenCompare': false,
            'captureScreenshot': false,
          })!;

      final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            'com.example.android_hardware_smoke_test/test_channel',
            encodedMessage,
            null,
          );

      await tester.pump();
      await tester.pump();

      final ByteData? responseBytes = await responseFuture;
      expect(responseBytes, isNotNull);
      final dynamic reply = const JSONMessageCodec().decodeMessage(
        responseBytes,
      );
      final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(replyMap['message'], equals('Rendered backdropFilterBlurTest'));

      // Verify BackdropFilter widget is present in the tree
      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );
}
