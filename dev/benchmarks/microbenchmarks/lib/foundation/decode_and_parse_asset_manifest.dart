// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformAssetBundle, StandardMessageCodec;
import 'package:flutter/widgets.dart';

import '../common.dart';

const int _kNumIterations = 1000;

void main() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  WidgetsFlutterBinding.ensureInitialized();
  final Stopwatch watch = Stopwatch();

  final ByteData assetManifest = await loadAssetManifest();

  watch.start();
  for (int i = 0; i < _kNumIterations; i++) {
    // This is effectively a test.
    // ignore: invalid_use_of_visible_for_testing_member
    AssetImage.parseAssetManifest(assetManifest);
  }
  watch.stop();

  printer.addResult(
    description: 'Load and Parse Large Asset Manifest',
    value: watch.elapsedMilliseconds.toDouble(),
    unit: 'ms',
    name: 'load_and_parse_large_asset_manifest',
  );

  printer.printToStdout();
}

final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

Future<ByteData> loadAssetManifest() async {
  double parseScale(String key) {
    final Uri assetUri = Uri.parse(key);
    String directoryPath = '';
    if (assetUri.pathSegments.length > 1) {
      directoryPath = assetUri.pathSegments[assetUri.pathSegments.length - 2];
    }
    final Match? match = _extractRatioRegExp.firstMatch(directoryPath);
    if (match != null && match.groupCount > 0) {
      return double.parse(match.group(1)!);
    }
    return 1.0;
  }

  final Map<String, dynamic> result = <String, dynamic>{};
  final PlatformAssetBundle bundle = PlatformAssetBundle();

  // For the benchmark, we use the older JSON format and then convert it to the modern binary format.
  final ByteData jsonAssetManifestBytes = await bundle.load('money_asset_manifest.json');
  final String jsonAssetManifest = utf8.decode(jsonAssetManifestBytes.buffer.asUint8List());

  final Map<String, dynamic> assetManifest = json.decode(jsonAssetManifest) as Map<String, dynamic>;

  for (final MapEntry<String, dynamic> manifestEntry in assetManifest.entries) {
    final List<dynamic> resultVariants = <dynamic>[];
    final List<String> entries = (manifestEntry.value as List<dynamic>).cast<String>();
    for (final String variant in entries) {
      if (variant == manifestEntry.key) {
        // With the newer binary format, don't include the main asset in it's
        // list of variants. This reduces parsing time at runtime.
        continue;
      }
      final Map<String, dynamic> resultVariant = <String, dynamic>{};
      final double variantDevicePixelRatio = parseScale(variant);
      resultVariant['asset'] = variant;
      resultVariant['dpr'] = variantDevicePixelRatio;
      resultVariants.add(resultVariant);
    }
    result[manifestEntry.key] = resultVariants;
  }

  return const StandardMessageCodec().encodeMessage(result)!;
}
