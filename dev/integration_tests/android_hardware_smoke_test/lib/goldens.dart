// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Captures the image bytes of the widget associated with [targetKey] and either compares it to a golden file or returns the bytes to the test driver for host-side comparison, depending on the value of [performAppSideGoldenCompare].
Future<void> handleGoldenRequest(
  String testName,
  Completer<Map<String, Object?>> completer,
  bool performAppSideGoldenCompare,
  GlobalKey targetKey,
) async {
  final Uint8List resultImageBytes = await _capturePng(testName, targetKey);

  if (performAppSideGoldenCompare) {
    return _compareGoldenOnDevice(testName, resultImageBytes, completer);
  } else {
    completer.complete(<String, Object?>{
      "message": "Rendered $testName",
      "imageBytes": base64.encode(resultImageBytes),
    });
  }
}

Future<void> _compareGoldenOnDevice(
  String testName,
  Uint8List resultImageBytes,
  Completer<Map<String, Object?>> completer,
) async {
  final io.Directory tempDir = await getTemporaryDirectory();
  final String testFileName = "$testName.png";
  final String goldenAssetPath = path.join("test_driver/goldens", testFileName);
  final String tempGoldenPath = path.join(
    tempDir.path,
    "goldens",
    testFileName,
  );
  final String tempResultPath = path.join(
    tempDir.path,
    "results",
    testFileName,
  );

  await _copyGoldenAssetToTemp(goldenAssetPath, tempGoldenPath);

  try {
    await _writeBytesToFile(tempResultPath, resultImageBytes, "compareGolden");
  } catch (e) {
    completer.complete(<String, Object?>{
      "message": "Failed to write result image: $e",
    });
    return;
  }

  final String? result = await matchesGoldenFile(
    tempGoldenPath,
  ).matchAsync(resultImageBytes);

  if (result == null) {
    completer.complete(<String, Object?>{"message": "Rendered $testName"});
  } else {
    completer.complete(<String, Object?>{
      "message": "Failed to render $testName, match result: $result",
    });
  }
}

Future<void> _writeBytesToFile(
  String filePath,
  Uint8List bytes,
  String logTag,
) async {
  assert(filePath.isNotEmpty);
  assert(bytes.isNotEmpty);
  assert(logTag.isNotEmpty);
  try {
    final io.File file = io.File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  } catch (e) {
    rethrow;
  }
}

Future<void> _copyGoldenAssetToTemp(
  String goldenAssetPath,
  String tempGoldenPath,
) async {
  try {
    final ByteData byteData = await rootBundle.load(goldenAssetPath);
    final Uint8List bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    await _writeBytesToFile(tempGoldenPath, bytes, "postFrameCallback");
  } catch (e) {
    // Maybe golden does not exist in asset path. Allow test to continue to either fail or write results.
  }
}

Future<Uint8List> _capturePng(String testName, GlobalKey targetKey) async {
  try {
    final RenderRepaintBoundary boundary =
        targetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    if (pngBytes.isEmpty) {
      throw Exception('pngBytes from RenderRepaintBoundary.toImage was empty');
    }
    return pngBytes;
  } catch (e) {
    rethrow;
  }
}
