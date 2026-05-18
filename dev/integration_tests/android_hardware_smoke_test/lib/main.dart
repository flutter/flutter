import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:ui' as ui;
//import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:android_driver_extensions/native_driver.dart';

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
      autoUpdateGoldenFiles = true;
      // kick off an attempt to match the golden file.
      getApplicationSupportDirectory().then((directory) {
        var goldenPath = path.join(directory.path, '$testName.png');
        print("App postFrameCallback, comparing golden at $goldenPath");
        matchesGoldenFile(goldenPath).matchAsync(_capturePng(testName)).then((
          String? result,
        ) {
          if (result == null) {
            completer.complete("Rendered $testName");
          } else {
            completer.complete(
              "Failed to render $testName, match result: $result",
            );
            return;
          }
        });
      });
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  Future<Uint8List> _capturePng(String testName) async {
    try {
      print('_capturePng for $testName');
      RenderRepaintBoundary boundary =
          targetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      var pngBytes = byteData!.buffer.asUint8List();
      if (pngBytes.isEmpty) throw Exception('pngBytes should not be null');
      return pngBytes;
    } catch (e) {
      print(e);
      return Uint8List(0);
    }
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
          SizedBox(
            child: RepaintBoundary(
              key: targetKey,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: MyPainter(message: _message),
              ),
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
