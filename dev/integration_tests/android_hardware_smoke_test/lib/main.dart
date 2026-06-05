// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backdrop_filter_blur.dart';
import 'goldens.dart';

final GlobalKey targetKey = GlobalKey();

// ImageLoader supports injecting mock assets in headless widget tests.
typedef ImageLoader = Future<ui.Image> Function();

Future<ui.Image> defaultImageLoader() async {
  final ByteData data = await rootBundle.load('assets/test_image.png');
  final ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
  );
  final ui.FrameInfo fi = await codec.getNextFrame();
  codec.dispose();
  return fi.image;
}

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.imageLoader = defaultImageLoader});

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

class MyWidget extends StatefulWidget {
  const MyWidget({super.key, required this.imageLoader});

  final ImageLoader imageLoader;

  @override
  State<MyWidget> createState() => _MyState();
}

class _MyState extends State<MyWidget> {
  static const MethodChannel nativeChannel = MethodChannel(
    'com.example.android_hardware_smoke_test/native_support',
  );

  static const testChannel = BasicMessageChannel<Object?>(
    'com.example.android_hardware_smoke_test/test_channel',
    JSONMessageCodec(),
  );

  String _message = 'Waiting for message...';
  late Future<String?> _goldenVariantFuture;
  ui.Image? _loadedImage;

  Future<ui.Image> _loadImage() async {
    return widget.imageLoader();
  }

  Future<Map<String, Object?>?> handler(Object? message) async {
    final Map<String, Object?>? messageMap = (message as Map<Object?, Object?>?)
        ?.cast<String, Object?>();
    final testName = messageMap?['testName'] as String?;
    final bool performAppSideGoldenCompare =
        messageMap?['performAppSideGoldenCompare'] as bool? ?? true;

    // Widget tests pass captureScreenshot: false.
    // Image.toByteData runs async on a native thread, which results in an unresolvable deadlock in the widget test's FakeAsync zone.
    // Comparing pixels is not a responsibility of widget tests anyway, that should be reserved for the integration tests.
    final bool captureScreenshot =
        messageMap?['captureScreenshot'] as bool? ?? true;

    // Lazily load the image asset only when requested. This avoids loading it
    // unnecessarily, blocks rendering until fully loaded, and catches load
    // failures to explicitly fail the host-side driver test.
    if (testName == 'imageTest' && _loadedImage == null) {
      try {
        final ui.Image img = await _loadImage();
        setState(() {
          _loadedImage = img;
        });
      } catch (e, stackTrace) {
        return <String, Object?>{
          'message': 'Failed to load image asset: $e\n$stackTrace',
        };
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
        completer.complete(<String, Object?>{
          'message': 'Rendered $testName',
          'imageBytes': null,
        });
      }
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    _goldenVariantFuture = nativeChannel.invokeMethod<String>(
      'impeller_backend',
    );
    testChannel.setMessageHandler(handler);
  }

  @override
  void dispose() {
    _loadedImage?.dispose();
    testChannel.setMessageHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget testContent;
    if (_message == 'backdropFilterBlurTest') {
      testContent = const BackdropFilterBlur();
    } else {
      testContent = CustomPaint(
        painter: MyPainter(message: _message, loadedImage: _loadedImage),
      );
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

class MyPainter extends CustomPainter {
  MyPainter({required this.message, this.loadedImage})
    : assert(message.isNotEmpty);
  final String message;
  final ui.Image? loadedImage;

  void renderBlueRectangleTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void renderTrianglePathTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 10);
    path.lineTo(size.width - 10, size.height - 10);
    path.lineTo(10, size.height - 10);
    path.close();
    canvas.drawPath(path, paint);
  }

  void renderTextTest(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Flutter Text Rendering Test',
        style: TextStyle(
          color: Colors.red,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10.0, 50.0));
  }

  void renderImageTest(Canvas canvas, Size size) {
    assert(loadedImage != null);
    canvas.drawImage(loadedImage!, Offset.zero, Paint());
  }

  void renderAdvancedBlendTest(Canvas canvas, Size size) {
    final Paint paintBackground = Paint()..color = Colors.blue;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paintBackground,
    );

    final Paint paintCircle = Paint()..color = Colors.red;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      50.0,
      paintCircle,
    );

    final Paint paintBlend = Paint()
      ..color = Colors.green
      ..blendMode = BlendMode.difference;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 30, size.height / 2 - 30, 80, 80),
      paintBlend,
    );
  }

  void renderDefault(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(80, 80), 40, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (message) {
      case 'blueRectangleTest':
        renderBlueRectangleTest(canvas, size);
        return;
      case 'trianglePathTest':
        renderTrianglePathTest(canvas, size);
        return;
      case 'textTest':
        renderTextTest(canvas, size);
        return;
      case 'imageTest':
        renderImageTest(canvas, size);
        return;
      case 'advancedBlendTest':
        renderAdvancedBlendTest(canvas, size);
        return;
      default:
        renderDefault(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return message != oldDelegate.message ||
        loadedImage != oldDelegate.loadedImage;
  }
}
