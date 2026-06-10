// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backdrop_filter_blur.dart';
import 'goldens.dart';
import 'image_drawing_canvas.dart';
import 'platform_view.dart';
import 'text_drawing_canvas.dart';
import 'vector_drawings_canvas.dart';

/// The global key identifying the target [RepaintBoundary] for golden screenshot capturing.
final GlobalKey targetKey = GlobalKey();
final Completer<void> platformViewCreatedCompleter = Completer<void>();

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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
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
  static const MethodChannel _nativeChannel = MethodChannel(
    'com.example.android_hardware_smoke_test/native_support',
  );

  static const _testChannel = BasicMessageChannel<Object?>(
    'com.example.android_hardware_smoke_test/test_channel',
    JSONMessageCodec(),
  );

  String _message = 'Waiting for message...';
  late Future<String?> _goldenVariantFuture;
  ui.Image? _loadedImage;

  Future<ui.Image> _loadImage() async {
    return widget.imageLoader();
  }

  Future<Map<String, Object?>?> _handler(Object? message) async {
    final Map<String, Object?>? messageMap = (message as Map<Object?, Object?>?)
        ?.cast<String, Object?>();

    if (messageMap?['command'] == 'compare_golden') {
      // Handle the out-of-band comparison request. This is triggered by the on-device test runner
      // once it has captured and cropped the platform view screenshot using UiAutomation.
      final String testName = (messageMap!['testName'] as String?)!;
      final String imageBase64 = (messageMap['imageBytes'] as String?)!;
      final Uint8List imageBytes = base64.decode(imageBase64);
      final String? goldenVariantValue = await _goldenVariantFuture;

      final String? failureMessage = await compareGoldenOnDevice(
        testName,
        imageBytes,
        goldenVariantValue,
      );

      return <String, Object?>{'message': failureMessage ?? 'Comparison Success'};
    }

    final testName = messageMap?['testName'] as String?;
    final bool performAppSideGoldenCompare =
        messageMap?['performAppSideGoldenCompare'] as bool? ?? true;

    // Widget tests pass captureScreenshot: false.
    // Image.toByteData runs async on a native thread, which results in an unresolvable deadlock in the widget test's FakeAsync zone.
    // Comparing pixels is not a responsibility of widget tests anyway, that should be reserved for the integration tests.
    final bool captureScreenshot = messageMap?['captureScreenshot'] as bool? ?? true;

    // Lazily load the image asset only when requested. This avoids loading it
    // unnecessarily, blocks rendering until fully loaded, and catches load
    // failures to explicitly fail the host-side driver test.
    if (testName == 'imageTest' && _loadedImage == null) {
      try {
        final ui.Image img = await _loadImage();
        // When handler starts, mounted is guaranteed to be true because handler is registered in initState.
        // However, the widget could unmount during the async gap of await _loadImage(), so we need to check mounted again before calling setState.
        if (!mounted) {
          img.dispose();
          return <String, Object?>{
            'message': 'Widget unmounted during image load',
            'imageBytes': null,
          };
        }
        setState(() {
          _loadedImage = img;
        });
      } catch (e, stackTrace) {
        return <String, Object?>{'message': 'Failed to load image asset: $e\n$stackTrace'};
      }
    }

    final completer = Completer<Map<String, Object?>>();

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
        );
      } else {
        completer.complete(<String, Object?>{'message': 'Rendered $testName', 'imageBytes': null});
      }
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    _goldenVariantFuture = _nativeChannel.invokeMethod<String>('impeller_backend');
    _testChannel.setMessageHandler(_handler);
  }

  @override
  void dispose() {
    _loadedImage?.dispose();
    _testChannel.setMessageHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget testContent;
    if (_message == 'backdropFilterBlurTest') {
      testContent = const BackdropFilterBlur();
    } else if (_message == 'platformViewTest') {
      testContent = AndroidPlatformView(
        onCreated: () {
          if (!platformViewCreatedCompleter.isCompleted) {
            platformViewCreatedCompleter.complete();
          }
        },
      );
    } else if (_message == 'textTest') {
      testContent = const TextDrawingCanvas();
    } else if (_message == 'imageTest') {
      testContent = ImageDrawingCanvas(image: _loadedImage);
    } else {
      testContent = VectorDrawingsCanvas(message: _message);
    }

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
