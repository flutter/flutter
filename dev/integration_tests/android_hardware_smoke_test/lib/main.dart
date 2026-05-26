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
  final channel = BasicMessageChannel<Object?>(
    "com.example.android_hardware_smoke_test/test_channel",
    const JSONMessageCodec(),
  );

  String _message = "Waiting for message...";

  Future<Map<String, Object?>?> handler(Object? message) {
    final Map<String, Object?>? messageMap = (message as Map<Object?, Object?>?)
        ?.cast<String, Object?>();
    final String? testName = messageMap?['testName'] as String?;
    final bool performAppSideGoldenCompare =
        messageMap?['performAppSideGoldenCompare'] as bool? ?? true;
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
      );
    }, debugLabel: "Rendered $testName");

    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    channel.setMessageHandler(handler);
  }

  @override
  void dispose() {
    super.dispose();
    channel.setMessageHandler(null);
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

  void renderFooTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(40, 40), 20, paint);
  }

  void renderBarTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(80, 70), 30, paint);
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
      case "fooTest":
        renderFooTest(canvas, size);
        return;
      case "barTest":
        renderBarTest(canvas, size);
        return;
      default:
        renderDefault(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is MyPainter && message != oldDelegate.message;
  }
}
