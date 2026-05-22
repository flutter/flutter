// ignore_for_file: avoid_print, use_key_in_widget_constructors, type_init_formals, no_leading_underscores_for_local_identifiers
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:android_driver_extensions/native_driver.dart';

GlobalKey targetKey = GlobalKey();

void main() async {
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
    Completer<Map<String, dynamic>> completer =
        Completer<Map<String, dynamic>>();
    setState(() {
      _message = testName ?? "Empty message";
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // autoUpdateGoldenFiles = true;
      _postFrameCallback(
        testName ?? "unknown",
        completer,
        performAppSideGoldenCompare,
      );
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  Future _postFrameCallback(
    String testName,
    Completer<Map<String, dynamic>> completer,
    bool performAppSideGoldenCompare,
  ) async {
    final Uint8List resultImageBytes = await _capturePng(testName);

    if (performAppSideGoldenCompare) {
      return _compareGolden(testName, resultImageBytes, completer);
    } else {
      completer.complete(<String, dynamic>{
        'message': "Rendered $testName",
        'imageBytes': base64.encode(resultImageBytes),
      });
    }
  }

  Future _compareGolden(
    String testName,
    Uint8List resultImageBytes,
    Completer<Map<String, dynamic>> completer,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final testFileName = '$testName.png';
    var goldenAssetPath = path.join("test_driver/goldens", testFileName);
    var tempGoldenPath = path.join(tempDir.path, 'goldens', testFileName);
    var tempResultPath = path.join(tempDir.path, 'results', testFileName);

    await _copyGoldenAssetToTemp(goldenAssetPath, tempGoldenPath);

    try {
      await _writeBytesToFile(
        tempResultPath,
        resultImageBytes,
        "compareGolden",
      );
    } catch (e) {
      completer.complete(<String, dynamic>{
        'message': "Failed to write result image: $e",
      });
      return;
    }

    print("App postFrameCallback, comparing golden at $tempGoldenPath");
    print(
      'App postFrameCallback: type of goldenFileComparator: ${goldenFileComparator.runtimeType}',
    );
    String? result = await matchesGoldenFile(
      tempGoldenPath,
    ).matchAsync(resultImageBytes);

    if (result == null) {
      completer.complete(<String, dynamic>{'message': "Rendered $testName"});
    } else {
      completer.complete(<String, dynamic>{
        'message': "Failed to render $testName, match result: $result",
      });
    }
  }

  Future<void> _writeBytesToFile(
    String filePath,
    Uint8List bytes,
    String logTag,
  ) async {
    try {
      final io.File file = io.File(filePath);
      if (!file.existsSync()) {
        print("App $logTag, $filePath did not exist, creating it");
        await file.create(recursive: true);
      }
      await file.writeAsBytes(bytes);
      print("App $logTag, wrote $filePath");
    } catch (e) {
      print(
        "App $logTag, exception thrown while writing $filePath, exception: $e",
      );
      rethrow;
    }
  }

  Future<void> _copyGoldenAssetToTemp(
    String goldenAssetPath,
    String tempGoldenPath,
  ) async {
    try {
      print(
        "App postFrameCallback, copying $goldenAssetPath to $tempGoldenPath",
      );
      final ByteData byteData = await rootBundle.load(goldenAssetPath);
      final Uint8List bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      await _writeBytesToFile(tempGoldenPath, bytes, "postFrameCallback");
    } catch (e) {
      // Maybe golden does not exist in asset path
      print(
        "App postFramecallback, exception thrown while copying $goldenAssetPath to $tempGoldenPath, exception: $e",
      );
      // Instead of rethrowing here, allow the test to continue.
      // When matchesGolden is called later, it will either fail on missing golden or write the test result.
    }
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
      if (pngBytes.isEmpty) {
        throw Exception(
          'pngBytes from RenderRepaintBoundary.toImage was empty',
        );
      }
      return pngBytes;
    } catch (e) {
      print('_capturePng for $testName caught exception: $e');
      rethrow;
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
