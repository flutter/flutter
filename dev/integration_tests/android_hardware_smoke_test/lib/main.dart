// ignore_for_file: avoid_print, use_key_in_widget_constructors, type_init_formals, no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io' show File;
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
  final channel = BasicMessageChannel<dynamic>(
    'com.example.android_hardware_smoke_test/test_channel',
    const JSONMessageCodec(),
  );

  String _message = "Waiting for message...";

  Future<dynamic> handler(dynamic message) {
    final Map<dynamic, dynamic>? messageMap = message as Map<dynamic, dynamic>?;
    final String? testName = messageMap?['testName'] as String?;
    final bool performAppSideGoldenCompare =
        messageMap?['performAppSideGoldenCompare'] as bool? ?? true;
    Completer<String> completer = Completer<String>();
    setState(() {
      _message = testName ?? "Empty message";
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // autoUpdateGoldenFiles = true;
      if (performAppSideGoldenCompare) {
        _compareGolden(testName ?? "unknown", completer);
      } else {
        print("App handler: skipping app-side golden comparison for $testName");
        completer.complete("Rendered $testName");
      }
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  Future _compareGolden(String testName, Completer completer) async {
    final tempDir = await getTemporaryDirectory();
    final testFileName = '$testName.png';
    var goldenAssetPath = path.join("integration_test/goldens", testFileName);
    var tempGoldenPath = path.join(tempDir.path, 'goldens', testFileName);
    var tempResultPath = path.join(tempDir.path, 'results', testFileName);

    await _copyGoldenAssetToTemp(goldenAssetPath, tempGoldenPath);
    final resultImageBytes = _capturePngAndWriteResult(
      testName,
      tempResultPath,
    );

    print("App postFrameCallback, comparing golden at $tempGoldenPath");
    print(
      'App postFrameCallback: type of goldenFileComparator: ${goldenFileComparator.runtimeType}',
    );
    String? result = await matchesGoldenFile(
      tempGoldenPath,
    ).matchAsync(resultImageBytes);

    if (result == null) {
      completer.complete("Rendered $testName");
    } else {
      completer.complete("Failed to render $testName, match result: $result");
      return;
    }
  }

  Future _copyGoldenAssetToTemp(
    String goldenAssetPath,
    String tempGoldenPath,
  ) async {
    // Copy golden from asset to temp dir.
    // Do this every time the test executes because we always want to match against the golden.
    try {
      print(
        "App postFrameCallback, copying $goldenAssetPath to $tempGoldenPath",
      );
      var file = File(tempGoldenPath);
      var byteData = await rootBundle.load(goldenAssetPath);
      var buffer = byteData.buffer;
      if (!file.existsSync()) {
        print(
          "App postFrameCallback, $tempGoldenPath did not exist, creating it",
        );
        await file.create(recursive: true);
      }
      await file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
      print("App postFrameCallback, wrote $tempGoldenPath");
    } catch (e) {
      // Maybe golden does not exist in asset path
      print(
        "App postFramecallback, exception thrown while copying $goldenAssetPath to $tempGoldenPath, exception: $e",
      );
      // Instead of rethrowing here, allow the test to continue.
      // When matchesGolden is called later, it will either fail on missing golden or write the test result.
    }
  }

  Future<Uint8List> _capturePngAndWriteResult(
    String testName,
    String tempResultPath,
  ) async {
    try {
      print('_capturePngAndWriteResults for $testName');
      RenderRepaintBoundary boundary =
          targetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      var pngBytes = byteData!.buffer.asUint8List();
      if (pngBytes.isEmpty) {
        throw Exception(
          'pngBytes from RenderRepaintBoundary.toImage was empty',
        );
      }

      try {
        print("App _capturePngAndWriteResults, writing to $tempResultPath");
        var file = File(tempResultPath);
        var buffer = byteData.buffer;
        if (!file.existsSync()) {
          print(
            "App _capturePngAndWriteResults, $tempResultPath did not exist, creating it",
          );
          await file.create(recursive: true);
        }
        await file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
        print("App _capturePngAndWriteResults, wrote $tempResultPath");
      } catch (e) {
        print(
          "App _capturePngAndWriteResults, exception thrown while writing $tempResultPath, exception: $e",
        );
        rethrow;
      }

      return pngBytes;
    } catch (e) {
      print('_capturePngAndWriteResults for $testName caught exception: $e');
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
