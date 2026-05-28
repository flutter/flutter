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
  Future<String?> goldenVariant,
) async {
  try {
    final String? goldenVariantValue = await goldenVariant;
    final Uint8List resultImageBytes = await _capturePng(testName, targetKey);

    if (performAppSideGoldenCompare) {
      final String? failureMessage = await _compareGoldenOnDevice(
        testName,
        resultImageBytes,
        goldenVariantValue,
      );
      completer.complete(<String, Object?>{
        "message": failureMessage ?? "Rendered $testName",
      });
    } else {
      completer.complete(<String, Object?>{
        "message": "Rendered $testName",
        "imageBytes": base64.encode(resultImageBytes),
      });
    }
  } catch (e, stackTrace) {
    // Guarantee that the completer completes even under unhandled exceptions
    completer.complete(<String, Object?>{
      "message":
          "Error occurred during golden request handling: $e\n$stackTrace",
    });
  }
}

Future<String?> _compareGoldenOnDevice(
  String testName,
  Uint8List resultImageBytes,
  String? goldenVariant,
) async {
  final io.Directory tempDir = await getTemporaryDirectory();
  final String variantSuffix =
      (goldenVariant != null && goldenVariant.isNotEmpty)
      ? ".$goldenVariant"
      : "";
  final String fileName = "$testName$variantSuffix.png";
  final String goldenAssetPath = path.join("test_driver/goldens", fileName);
  final String tempGoldenPath = path.join(tempDir.path, "goldens", fileName);
  final String tempResultPath = path.join(tempDir.path, "results", fileName);

  await _copyGoldenAssetToTemp(goldenAssetPath, tempGoldenPath);

  await _writeBytesToFile(tempResultPath, resultImageBytes);

  return matchesGoldenFile(tempGoldenPath).matchAsync(resultImageBytes);
}

Future<void> _writeBytesToFile(String filePath, Uint8List bytes) async {
  assert(filePath.isNotEmpty);
  assert(bytes.isNotEmpty);
  final io.File file = io.File(filePath);
  if (!file.existsSync()) {
    await file.create(recursive: true);
  }
  await file.writeAsBytes(bytes);
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
    await _writeBytesToFile(tempGoldenPath, bytes);
  } catch (e) {
    throw StateError(
      'Failed to load golden asset "$goldenAssetPath" from package assets. '
      'Ensure the golden image was generated and bundled correctly. Error: $e',
    );
  }
}

Future<Uint8List> _capturePng(String testName, GlobalKey targetKey) async {
  final BuildContext? context = targetKey.currentContext;
  if (context == null) {
    throw StateError(
      "Failed to capture screenshot for $testName: targetKey is not mounted in the widget tree.",
    );
  }

  final RenderObject? renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError(
      "Failed to capture screenshot for $testName: the associated RenderObject is not a RenderRepaintBoundary.",
    );
  }
  final RenderRepaintBoundary boundary = renderObject;
  final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) {
    throw StateError(
      "Failed to capture screenshot for $testName: ui.Image.toByteData returned null.",
    );
  }

  final Uint8List pngBytes = byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
  if (pngBytes.isEmpty) {
    throw StateError(
      "Failed to capture screenshot for $testName: pngBytes from RenderRepaintBoundary.toImage was empty.",
    );
  }
  return pngBytes;
}
