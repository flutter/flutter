// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:android_driver_extensions/native_driver.dart' as android_driver;
import 'package:android_hardware_smoke_test/constants.dart';
import 'package:android_hardware_smoke_test/goldens.dart';
import 'package:android_hardware_smoke_test/image_drawing_canvas.dart';
import 'package:android_hardware_smoke_test/main.dart';
import 'package:android_hardware_smoke_test/pixel_exact_local_file_comparator.dart';
import 'package:android_hardware_smoke_test/platform_view.dart';
import 'package:android_hardware_smoke_test/text_drawing_canvas.dart';
import 'package:android_hardware_smoke_test/vector_drawings_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Pre-compiled 1x1 transparent PNG bytes used for mock asset loads and golden comparisons.
///
/// This is used instead of [testImage] (which is a decoded [ui.Image] object) because:
/// 1. `compareGoldenOnDevice` and our comparator expect raw compressed [Uint8List] bytes.
/// 2. The mock `'flutter/assets'` binary messenger channel must return raw file bytes.
/// 3. Converting [testImage] to PNG bytes dynamically using `toByteData(format: png)`
///    is slow and deadlocks inside the test's `FakeAsync` zone.
final Uint8List transparentImageBytes = Uint8List.fromList(
  img.encodePng(img.Image(width: 1, height: 1)),
);

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

    // Mock path_provider plugins channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );

    // Mock the asset loader for the golden image
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final String assetKey = utf8.decode(Uint8List.sublistView(message!));
        if (assetKey == 'test_driver/goldens/imageTest.vulkan.png') {
          return ByteData.sublistView(transparentImageBytes);
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

  testWidgets(
    'compareGoldenOnDevice configures PixelExactLocalFileComparator and executes comparison',
    (WidgetTester tester) async {
      String? result;
      await tester.runAsync(() async {
        result = await compareGoldenOnDevice(kImageTest, transparentImageBytes, 'vulkan');
      });

      // Since mock assets decode to identical transparent black mock images, their pixels match,
      // and the comparison should return null (success).
      expect(result, isNull);

      // Assert that the global goldenFileComparator was configured to PixelExactLocalFileComparator
      expect(android_driver.goldenFileComparator, isA<PixelExactLocalFileComparator>());
    },
  );

  testWidgets('compareGoldenOnDevice throws StateError when golden file is not found', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      expect(
        () => compareGoldenOnDevice('nonExistentTest', transparentImageBytes, 'vulkan'),
        throwsStateError,
      );
    });
  });

  testWidgets('compareGoldenOnDevice returns failure message on dimension mismatch', (
    WidgetTester tester,
  ) async {
    final image2x2Bytes = Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));

    String? result;
    await tester.runAsync(() async {
      result = await compareGoldenOnDevice(kImageTest, image2x2Bytes, 'vulkan');
    });

    expect(result, isNotNull);
    expect(result, contains('does not match'));
  });

  testWidgets('compareGoldenOnDevice returns failure message on pixel mismatch', (
    WidgetTester tester,
  ) async {
    final redImage = img.Image(width: 1, height: 1);
    redImage.setPixelRgba(0, 0, 255, 0, 0, 255);
    final redPngBytes = Uint8List.fromList(img.encodePng(redImage));

    // Register the mock asset to return redPngBytes for pixelMismatchTest
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final String assetKey = utf8.decode(Uint8List.sublistView(message!));
        if (assetKey == 'test_driver/goldens/pixelMismatchTest.vulkan.png') {
          return ByteData.sublistView(redPngBytes);
        }
        if (assetKey == 'test_driver/goldens/imageTest.vulkan.png') {
          return ByteData.sublistView(transparentImageBytes);
        }
        return null;
      },
    );

    String? result;
    await tester.runAsync(() async {
      result = await compareGoldenOnDevice('pixelMismatchTest', transparentImageBytes, 'vulkan');
    });

    expect(result, isNotNull);
    expect(result, contains('does not match'));
  });

  testWidgets('PixelExactLocalFileComparator supports both asset: and asset:// URI schemes', (
    WidgetTester tester,
  ) async {
    const comparator = PixelExactLocalFileComparator();

    await tester.runAsync(() async {
      final bool match1 = await comparator.compare(
        transparentImageBytes,
        Uri(scheme: 'asset', path: 'test_driver/goldens/imageTest.vulkan.png'),
      );
      expect(match1, isTrue);

      final bool match2 = await comparator.compare(
        transparentImageBytes,
        Uri.parse('asset://test_driver/goldens/imageTest.vulkan.png'),
      );
      expect(match2, isTrue);
    });
  });
}
