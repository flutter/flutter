import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

GlobalKey targetKey = GlobalKey();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter android hardware smoke test',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyState();
}

class _MyState extends State<MyWidget> {
  final channel = BasicMessageChannel<String>(
    'com.example.android_hardware_smoke_test/test_channel',
    StringCodec(),
  );

  String _message = "Waiting for message...";

  Future<String> handler(testName) {
    Completer<String> completer = Completer<String>();
    setState(() {
      _message = testName ?? "Empty message";
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete("Rendered $testName");
    }, debugLabel: 'Rendered $testName');

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
              size: const Size(200, 200),
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
  String message;
  MyPainter({required String this.message});

  void renderFooTest(Canvas canvas, Size size) {
    print("📕🐺 renderFooTest");
    final _paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(40, 40), 20, _paint);
  }

  void renderBarTest(Canvas canvas, Size size) {
    print("📕🐺 renderBarTest");
    final _paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(80, 70), 30, _paint);
  }

  void renderDefault(Canvas canvas, Size size) {
    print("🐺 renderDefault");
    final _paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(80, 80), 40, _paint);
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
