// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:android_hardware_smoke_test/constants.dart';
import 'package:android_hardware_smoke_test/image_drawing_canvas.dart';
import 'package:android_hardware_smoke_test/main.dart';
import 'package:android_hardware_smoke_test/platform_view.dart';
import 'package:android_hardware_smoke_test/text_drawing_canvas.dart';
import 'package:android_hardware_smoke_test/vector_drawings_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image testImage;
  late bool mockHcppSupported;

  setUp(() async {
    testImage = await createTestImage(width: 10, height: 10);
    mockHcppSupported = true;

    // Mock the native platform MethodChannel to prevent MissingPluginException during tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(nativeSupportChannelName),
      (MethodCall methodCall) async {
        if (methodCall.method == methodImpellerBackend) {
          return 'vulkan';
        }
        return null;
      },
    );

    // Mock the built-in system platform views channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      // Note: `platform_views_2` not `platform_views` because that's where `isSurfaceControlEnabled` is supported.
      const MethodChannel('flutter/platform_views_2'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'isSurfaceControlEnabled') {
          return mockHcppSupported;
        }
        return null;
      },
    );
  });

  tearDown(() {
    testImage.dispose();
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

    // Verify that our specific VectorDrawingsCanvas is built
    expect(find.byType(VectorDrawingsCanvas), findsOneWidget);

    // Verify that the basic structural elements SafeArea and Stack are present
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(Stack), findsOneWidget);
  });

  testWidgets('imageTest message channel handler - success behavior', (WidgetTester tester) async {
    // Inject a mock imageLoader returning a clone of our pre-created testImage
    await tester.pumpWidget(MyApp(imageLoader: () async => testImage.clone()));

    final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
      keyTestName: kImageTest,
      keyPerformAppSideGoldenCompare: false,
      keyCaptureScreenshot: false,
    })!;

    // Send the message to invoke the app's channel handler
    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(testChannelName, encodedMessage, null);

    // Pump frames to resolve the image load and post-frame callback in fake time
    await tester.pump(); // Triggers build with loaded image
    await tester.pump(); // Triggers post-frame callback

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>).cast<String, Object?>();
    expect(replyMap[keyMessage], equals('Rendered $kImageTest'));
    expect(replyMap[keyImageBytes], isNull);

    final ImageDrawingCanvas canvasWidget = tester.widget<ImageDrawingCanvas>(
      find.byType(ImageDrawingCanvas),
    );
    expect(canvasWidget.image, isNotNull);
  });

  testWidgets('textTest message channel handler - success behavior', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
      keyTestName: kTextTest,
      keyPerformAppSideGoldenCompare: false,
      keyCaptureScreenshot: false,
    })!;

    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(testChannelName, encodedMessage, null);

    await tester.pump();
    await tester.pump();

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>).cast<String, Object?>();
    expect(replyMap[keyMessage], equals('Rendered $kTextTest'));

    expect(find.byType(TextDrawingCanvas), findsOneWidget);
  });

  testWidgets('imageTest message channel handler - failure behavior', (WidgetTester tester) async {
    // Inject a mock imageLoader that immediately throws an exception
    await tester.pumpWidget(
      MyApp(
        imageLoader: () async {
          throw Exception('Mock image load failure');
        },
      ),
    );

    final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
      keyTestName: kImageTest,
      keyPerformAppSideGoldenCompare: false,
      keyCaptureScreenshot: false,
    })!;

    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(testChannelName, encodedMessage, null);

    // Pump a frame to let the handler complete
    await tester.pump();

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>).cast<String, Object?>();
    expect(replyMap[keyMessage], contains('Failed to load image asset'));
    expect(replyMap[keyImageBytes], isNull);
  });

  testWidgets('advancedBlendTest message channel handler - success behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
      keyTestName: kAdvancedBlendTest,
      keyPerformAppSideGoldenCompare: false,
      keyCaptureScreenshot: false,
    })!;

    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(testChannelName, encodedMessage, null);

    await tester.pump();
    await tester.pump();

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>).cast<String, Object?>();
    expect(replyMap[keyMessage], equals('Rendered $kAdvancedBlendTest'));

    final VectorDrawingsCanvas canvasWidget = tester.widget<VectorDrawingsCanvas>(
      find.byType(VectorDrawingsCanvas),
    );
    expect(canvasWidget.message, equals(kAdvancedBlendTest));
  });

  testWidgets('backdropFilterBlurTest message channel handler - success behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
      keyTestName: kBackdropFilterBlurTest,
      keyPerformAppSideGoldenCompare: false,
      keyCaptureScreenshot: false,
    })!;

    final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(testChannelName, encodedMessage, null);

    await tester.pump();
    await tester.pump();

    final ByteData? responseBytes = await responseFuture;
    expect(responseBytes, isNotNull);
    final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
    final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>).cast<String, Object?>();
    expect(replyMap[keyMessage], equals('Rendered $kBackdropFilterBlurTest'));

    // Verify BackdropFilter widget is present in the tree
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  for (final testName in <String>[
    kPlatformViewTextureLayerTest,
    kPlatformViewHybridCompositionTest,
    kPlatformViewHybridCompositionPlusPlusTest,
  ]) {
    testWidgets('$testName message channel handler - success behavior', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
        keyTestName: testName,
        keyPerformAppSideGoldenCompare: false,
        keyCaptureScreenshot: false,
      })!;

      final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(testChannelName, encodedMessage, null);

      await tester.pump();
      await tester.pump();

      final ByteData? responseBytes = await responseFuture;
      expect(responseBytes, isNotNull);
      final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
      final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(replyMap[keyMessage], equals('Rendered $testName'));

      // Verify AndroidPlatformView widget is present in the tree
      expect(find.byType(AndroidPlatformView), findsOneWidget);

      final AndroidPlatformView view = tester.widget<AndroidPlatformView>(
        find.byType(AndroidPlatformView),
      );
      final PlatformViewMode expectedMode = switch (testName) {
        kPlatformViewTextureLayerTest => PlatformViewMode.textureLayer,
        kPlatformViewHybridCompositionTest => PlatformViewMode.hybridComposition,
        kPlatformViewHybridCompositionPlusPlusTest => PlatformViewMode.hybridCompositionPlusPlus,
        _ => fail('Unexpected testName: $testName'),
      };
      expect(view.mode, equals(expectedMode));
    });
  }

  testWidgets(
    'platformViewHybridCompositionPlusPlusTest message channel handler - HCPP unsupported skip behavior',
    (WidgetTester tester) async {
      mockHcppSupported = false; // set HCPP to unsupported!

      await tester.pumpWidget(const MyApp());

      final ByteData encodedMessage = const JSONMessageCodec().encodeMessage(<String, Object?>{
        keyTestName: kPlatformViewHybridCompositionPlusPlusTest,
        keyPerformAppSideGoldenCompare: false,
        keyCaptureScreenshot: false,
      })!;

      final Future<ByteData?> responseFuture = TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(testChannelName, encodedMessage, null);

      await tester.pump();
      await tester.pump();

      final ByteData? responseBytes = await responseFuture;
      expect(responseBytes, isNotNull);
      final dynamic reply = const JSONMessageCodec().decodeMessage(responseBytes);
      final Map<String, Object?> replyMap = (reply as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(replyMap[keyMessage], equals('Skipped'));
      expect(replyMap[keyReason], contains('HCPP is not supported on this device/configuration'));

      // Verify AndroidPlatformView widget is NOT present in the tree
      expect(find.byType(AndroidPlatformView), findsNothing);
    },
  );
}
