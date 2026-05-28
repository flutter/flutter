import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'goldens.dart';

final GlobalKey targetKey = GlobalKey();

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter android hardware smoke test",
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyState();
}

class _MyState extends State<MyWidget> {
  static const MethodChannel nativeChannel = MethodChannel(
    "com.example.android_hardware_smoke_test/native_support",
  );

  final testChannel = BasicMessageChannel<Object?>(
    "com.example.android_hardware_smoke_test/test_channel",
    const JSONMessageCodec(),
  );

  String _message = "Waiting for message...";
  late Future<String?> _goldenVariantFuture;

  Future<Map<String, Object?>?> handler(Object? message) {
    final Map<String, Object?>? messageMap = (message as Map<Object?, Object?>?)
        ?.cast<String, Object?>();
    final String? testName = messageMap?["testName"] as String?;
    final bool performAppSideGoldenCompare =
        messageMap?["performAppSideGoldenCompare"] as bool? ?? true;
    final Completer<Map<String, Object?>> completer =
        Completer<Map<String, Object?>>();

    setState(() {
      _message = testName ?? "Empty message";
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleGoldenRequest(
        testName ?? "unknown",
        completer,
        performAppSideGoldenCompare,
        targetKey,
        _goldenVariantFuture,
      );
    }, debugLabel: "Rendered $testName");

    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    // Request the golden variant from the native side, but don't await it yet.
    // We only need it to be resolved by the time of the postFrameCallback in the handler.
    _goldenVariantFuture = nativeChannel.invokeMethod<String>(
      "impeller_backend",
    );
    testChannel.setMessageHandler(handler);
  }

  @override
  void dispose() {
    super.dispose();
    testChannel.setMessageHandler(null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            key: targetKey,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: MyPainter(message: _message),
            ),
          ),
          Align(alignment: Alignment.center, child: Text(_message)),
        ],
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final String message;
  MyPainter({required this.message}) : assert(message.isNotEmpty);

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

  void renderDefault(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(80, 80), 40, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (message) {
      case "blueRectangleTest":
        renderBlueRectangleTest(canvas, size);
        return;
      case "trianglePathTest":
        renderTrianglePathTest(canvas, size);
        return;
      default:
        renderDefault(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return message != oldDelegate.message;
  }
}
