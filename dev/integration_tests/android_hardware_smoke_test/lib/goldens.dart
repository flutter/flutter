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

import 'constants.dart';
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
    if (testName.startsWith(platformViewPrefix)) {
      await _handlePlatformViewRequest(
        testName,
        completer,
        targetKey,
        settleFuture: settleFuture,
      );
    } else {
      final String? goldenVariantValue = await goldenVariant;
      await _handleStandardViewRequest(
        testName,
        completer,
        performAppSideGoldenCompare,
        targetKey,
        goldenVariantValue,
      );
    }
  } catch (e, stackTrace) {
    // Guarantee that the completer completes even under unhandled exceptions
    completer.complete(<String, Object?>{
      keyMessage:
          'Error occurred during golden request handling: $e\n$stackTrace',
    });
  }
}

Future<void> _handlePlatformViewRequest(
  String testName,
  Completer<Map<String, Object?>> completer,
  GlobalKey targetKey, {
  Future<void>? settleFuture,
}) async {
  // Platform views cannot be captured using RepaintBoundary.toImage() since they reside in separate
  // native surface layers. Instead, we wait for layout to settle, calculate the widget's physical
  // coordinates on screen, and return them so the runner can perform a compositor-level capture.
  if (settleFuture != null) {
    await settleFuture;
  }
  // Wait 1 frame to ensure the platform view composite is fully submitted.
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
  // We can assume one window for these tests since they are android-only.
  final double devicePixelRatio =
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  final int x = (position.dx * devicePixelRatio).round();
  final int y = (position.dy * devicePixelRatio).round();
  final int w = (size.width * devicePixelRatio).round();
  final int h = (size.height * devicePixelRatio).round();

  completer.complete(<String, Object?>{
    keyMessage: 'Rendered $testName',
    keyX: x,
    keyY: y,
    keyWidth: w,
    keyHeight: h,
  });
}

Future<void> _handleStandardViewRequest(
  String testName,
  Completer<Map<String, Object?>> completer,
  bool performAppSideGoldenCompare,
  GlobalKey targetKey,
  String? goldenVariantValue,
) async {
  final Uint8List resultImageBytes = await _capturePng(testName, targetKey);

  if (performAppSideGoldenCompare) {
    final String? failureMessage = await compareGoldenOnDevice(
      testName,
      resultImageBytes,
      goldenVariantValue,
    );
    completer.complete(<String, Object?>{
      keyMessage: failureMessage ?? 'Rendered $testName',
    });
  } else {
    completer.complete(<String, Object?>{
      keyMessage: 'Rendered $testName',
      keyImageBytes: base64.encode(resultImageBytes),
    });
  }
}

/// Compares [resultImageBytes] against the golden asset associated with
/// [testName] and an optional [goldenVariant] on the device.
///
/// Returns an error message string if the comparison fails, or `null` if the
/// image matches the golden perfectly.
Future<String?> compareGoldenOnDevice(
  String testName,
  Uint8List resultImageBytes,
  String? goldenVariant,
) async {
  // We use PixelExactLocalFileComparator which decodes and compares images at a raw pixel level.
  // This is specific to **Instrumented Mode** (on-device comparison), where native screenshot
  // encoders and Dart encoders produce encoding differences for the same pixel grid.
  // It also supports reading reference goldens directly from the package's bundled assets using the
  // `asset://` URI scheme, completely eliminating the need to copy asset goldens to temporary files.
  goldenFileComparator = const PixelExactLocalFileComparator();

  final io.Directory tempDir = await getTemporaryDirectory();
  final variantSuffix = (goldenVariant != null && goldenVariant.isNotEmpty)
      ? '.$goldenVariant'
      : '';
  final fileName = '$testName$variantSuffix.png';
  final goldenAssetPath = 'test_driver/goldens/$fileName';
  final String tempResultPath = path.join(tempDir.path, 'results', fileName);

  // Write the result bytes to a temp file so they can be pulled off the device for debugging when a comparison fails.
  await _writeBytesToFile(tempResultPath, resultImageBytes);

  final dynamic comparisonResult = await matchesGoldenFile(
    Uri(scheme: 'asset', path: goldenAssetPath),
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
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
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
