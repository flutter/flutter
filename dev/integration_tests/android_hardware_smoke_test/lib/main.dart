// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backdrop_filter_blur.dart';
import 'constants.dart';
import 'goldens.dart';
import 'image_drawing_canvas.dart';
import 'platform_view.dart';
import 'text_drawing_canvas.dart';
import 'vector_drawings_canvas.dart';

/// The global key identifying the target [RepaintBoundary] for golden screenshot capturing.
final GlobalKey targetKey = GlobalKey();

void main() async {
  runApp(const MyApp());
}

/// The root application widget for the Android hardware smoke test.
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.imageLoader = defaultImageLoader});

  /// The callback used to lazily fetch image texture assets during test runs.
  final ImageLoader imageLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter android hardware smoke test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyWidget(imageLoader: imageLoader),
    );
  }
}

/// A stateful widget rendering vector drawings, blur effects, or platform views based on test driver requests.
class MyWidget extends StatefulWidget {
  const MyWidget({super.key, required this.imageLoader});

  /// The callback used to lazily fetch image texture assets during test runs.
  final ImageLoader imageLoader;

  @override
  State<MyWidget> createState() => _MyState();
}

class _MyState extends State<MyWidget> {
  static const _nativeChannel = MethodChannel(nativeSupportChannelName);
  static const _testChannel = BasicMessageChannel<Object?>(
    testChannelName,
    JSONMessageCodec(),
  );

  String _message = 'Waiting for message...';
  late Future<String?> _goldenVariantFuture;
  ui.Image? _loadedImage;

  // Completes when the native platform view has been drawn.
  Completer<void>? _platformViewDrawnCompleter;

  Future<ui.Image> _loadImage() async {
    return widget.imageLoader();
  }

  Future<Map<String, Object?>?> _handler(Object? message) async {
    final Map<String, Object?>? messageMap = (message as Map<Object?, Object?>?)
        ?.cast<String, Object?>();

    if (messageMap?[keyCommand] == commandCompareGolden) {
      // Handle the out-of-band comparison request. This is triggered by the on-device test runner
      // once it has captured and cropped the platform view screenshot using UiAutomation.
      final testName = messageMap![keyTestName]! as String;
      final imageBase64 = messageMap[keyImageBytes]! as String;
      final Uint8List imageBytes = base64.decode(imageBase64);
      final String? goldenVariantValue = await _goldenVariantFuture;

      final String? failureMessage = await compareGoldenOnDevice(
        testName,
        imageBytes,
        goldenVariantValue,
      );

      return <String, Object?>{
        keyMessage: failureMessage ?? 'Comparison Success',
      };
    }

    final testName = messageMap?[keyTestName] as String?;
    final bool performAppSideGoldenCompare =
        messageMap?[keyPerformAppSideGoldenCompare] as bool? ?? true;

    // Widget tests pass captureScreenshot: false.
    // Image.toByteData runs async on a native thread, which results in an unresolvable deadlock in the widget test's FakeAsync zone.
    // Comparing pixels is not a responsibility of widget tests anyway, that should be reserved for the integration tests.
    final bool captureScreenshot =
        messageMap?[keyCaptureScreenshot] as bool? ?? true;

    if (testName == kPlatformViewHybridCompositionPlusPlusTest) {
      final bool isHcpp = await HybridAndroidViewController.checkIfSupported();
      if (!isHcpp) {
        return <String, Object?>{
          keyMessage: 'Skipped',
          keyReason:
              'HCPP is not supported on this device/configuration (requires Vulkan and Android 14+)',
        };
      }
    }

    // Lazily load the image asset only when requested. This avoids loading it
    // unnecessarily, blocks rendering until fully loaded, and catches load
    // failures to explicitly fail the host-side driver test.
    if (testName == kImageTest && _loadedImage == null) {
      try {
        final ui.Image img = await _loadImage();
        // When handler starts, mounted is guaranteed to be true because handler is registered in initState.
        // However, the widget could unmount during the async gap of await _loadImage(), so we need to check mounted again before calling setState.
        if (!mounted) {
          img.dispose();
          return <String, Object?>{
            keyMessage: 'Widget unmounted during image load',
            keyImageBytes: null,
          };
        }
        setState(() {
          _loadedImage = img;
        });
      } catch (e, stackTrace) {
        return <String, Object?>{
          keyMessage: 'Failed to load image asset: $e\n$stackTrace',
        };
      }
    }

    final completer = Completer<Map<String, Object?>>();

    final bool isPlatformView =
        testName?.startsWith(platformViewPrefix) ?? false;
    if (isPlatformView) {
      _platformViewDrawnCompleter = Completer<void>();
    } else {
      _platformViewDrawnCompleter = null;
    }

    setState(() {
      _message = testName ?? 'Empty message';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (captureScreenshot) {
        handleGoldenRequest(
          testName ?? 'unknown',
          completer,
          performAppSideGoldenCompare,
          targetKey,
          _goldenVariantFuture,
          settleFuture: _platformViewDrawnCompleter?.future,
        );
      } else {
        completer.complete(<String, Object?>{
          keyMessage: 'Rendered $testName',
          keyImageBytes: null,
        });
      }
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    _goldenVariantFuture = _nativeChannel.invokeMethod<String>(
      methodImpellerBackend,
    );
    _nativeChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onDraw') {
        if (_platformViewDrawnCompleter?.isCompleted == false) {
          _platformViewDrawnCompleter?.complete();
        }
      }
    });
    _testChannel.setMessageHandler(_handler);
  }

  @override
  void dispose() {
    _loadedImage?.dispose();
    _nativeChannel.setMethodCallHandler(null);
    _testChannel.setMessageHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget testContent = switch (_message) {
      kBackdropFilterBlurTest => const BackdropFilterBlur(),
      kPlatformViewTextureLayerTest => const AndroidPlatformView(
        mode: PlatformViewMode.textureLayer,
      ),
      kPlatformViewHybridCompositionTest => const AndroidPlatformView(
        mode: PlatformViewMode.hybridComposition,
      ),
      kPlatformViewHybridCompositionPlusPlusTest => const AndroidPlatformView(
        mode: PlatformViewMode.hybridCompositionPlusPlus,
      ),
      kTextTest => const TextDrawingCanvas(),
      kImageTest => ImageDrawingCanvas(image: _loadedImage),
      _ => VectorDrawingsCanvas(message: _message),
    };

    return SafeArea(
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            key: targetKey,
            child: SizedBox(width: 150, height: 150, child: testContent),
          ),
          Align(child: Text(_message)),
        ],
      ),
    );
  }
}
