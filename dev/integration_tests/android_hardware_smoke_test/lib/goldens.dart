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

import 'pixel_exact_local_file_comparator.dart';

/// Captures the image bytes of the widget associated with [targetKey] and either compares it to a golden file or returns the bytes to the test driver for host-side comparison, depending on the value of [performAppSideGoldenCompare].
///
/// The optional [settleFuture] parameter allows injecting an asynchronous
/// initialization or layout completion signal (such as a platform view creation
/// event). If provided, execution will await [settleFuture] before capturing
/// physical screen coordinates.
Future<void> handleGoldenRequest(
  String testName,
  Completer<Map<String, Object?>> completer,
  bool performAppSideGoldenCompare,
  GlobalKey targetKey,
  Future<String?> goldenVariant, {
  Future<void>? settleFuture,
}) async {
  try {
    final String? goldenVariantValue = await goldenVariant;

    if (testName == 'platformViewTest') {
      // Platform views cannot be captured using RepaintBoundary.toImage() since they reside in separate
      // native surface layers. Instead, we wait for layout to settle, calculate the widget's physical
      // coordinates on screen, and return them so the runner can perform a compositor-level capture.
      if (settleFuture != null) {
        await settleFuture;
      }
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final BuildContext? context = targetKey.currentContext;
      if (context == null || !context.mounted) {
        throw StateError(
          'Failed to capture coordinates for $testName: targetKey is not mounted in the widget tree.',
        );
      }
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) {
        throw StateError(
          'Failed to capture coordinates for $testName: the associated RenderObject is not a RenderBox.',
        );
      }

      final Offset position = renderObject.localToGlobal(Offset.zero);
      final Size size = renderObject.size;
      final double devicePixelRatio = ui.PlatformDispatcher.instance.implicitView!.devicePixelRatio;

      final int x = (position.dx * devicePixelRatio).round();
      final int y = (position.dy * devicePixelRatio).round();
      final int w = (size.width * devicePixelRatio).round();
      final int h = (size.height * devicePixelRatio).round();

      completer.complete(<String, Object?>{
        'message': 'Rendered $testName',
        'x': x,
        'y': y,
        'width': w,
        'height': h,
      });
      return;
    }

    final Uint8List resultImageBytes = await _capturePng(testName, targetKey);

    if (performAppSideGoldenCompare) {
      final String? failureMessage = await compareGoldenOnDevice(
        testName,
        resultImageBytes,
        goldenVariantValue,
      );
      completer.complete(<String, Object?>{'message': failureMessage ?? 'Rendered $testName'});
    } else {
      completer.complete(<String, Object?>{
        'message': 'Rendered $testName',
        'imageBytes': base64.encode(resultImageBytes),
      });
    }
  } catch (e, stackTrace) {
    // Guarantee that the completer completes even under unhandled exceptions
    completer.complete(<String, Object?>{
      'message': 'Error occurred during golden request handling: $e\n$stackTrace',
    });
  }
}

Future<String?> compareGoldenOnDevice(
  String testName,
  Uint8List resultImageBytes,
  String? goldenVariant,
) async {
  goldenFileComparator = const PixelExactLocalFileComparator();

  final io.Directory tempDir = await getTemporaryDirectory();
  final variantSuffix = (goldenVariant != null && goldenVariant.isNotEmpty)
      ? '.$goldenVariant'
      : '';
  final fileName = '$testName$variantSuffix.png';
  final goldenAssetPath = 'test_driver/goldens/$fileName';
  final String tempGoldenPath = path.join(tempDir.path, 'goldens', fileName);
  final String tempResultPath = path.join(tempDir.path, 'results', fileName);

  // In this context, `matchesGoldenFile` uses a NaiveLocalFileComparator.
  // That comparator does not support reading bundled assets, so we need to create a temp file.
  // To avoid the risk that the temp copy was modified somehow, we copy every time we execute a comparison.
  await _copyGoldenAssetToTemp(goldenAssetPath, tempGoldenPath);
  // Write the result bytes to a temp file so they can be pulled off the device for debugging when a comparison fails.
  await _writeBytesToFile(tempResultPath, resultImageBytes);
  final dynamic comparisonResult = await matchesGoldenFile(
    tempGoldenPath,
  ).matchAsync(resultImageBytes);
  return comparisonResult as String?;
}

Future<void> _writeBytesToFile(String filePath, Uint8List bytes) async {
  assert(filePath.isNotEmpty);
  assert(bytes.isNotEmpty);
  final file = io.File(filePath);
  if (!file.existsSync()) {
    await file.create(recursive: true);
  }
  await file.writeAsBytes(bytes);
}

Future<void> _copyGoldenAssetToTemp(String goldenAssetPath, String tempGoldenPath) async {
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
      'Failed to capture screenshot for $testName: targetKey is not mounted in the widget tree.',
    );
  }

  final RenderObject? renderObject = context.findRenderObject();
  if (renderObject == null) {
    throw StateError(
      'Failed to capture screenshot for $testName: the associated RenderObject is null.',
    );
  }

  if (renderObject is! RenderRepaintBoundary) {
    throw StateError(
      'Failed to capture screenshot for $testName: the associated RenderObject is not a RenderRepaintBoundary.',
    );
  }
  final RenderRepaintBoundary boundary = renderObject;
  final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  try {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError(
        'Failed to capture screenshot for $testName: ui.Image.toByteData returned null.',
      );
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    if (pngBytes.isEmpty) {
      throw StateError(
        'Failed to capture screenshot for $testName: pngBytes from RenderRepaintBoundary.toImage was empty.',
      );
    }
    return pngBytes;
  } finally {
    image.dispose();
  }
}
