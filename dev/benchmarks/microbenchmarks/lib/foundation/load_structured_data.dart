// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformAssetBundle;
import 'package:flutter/widgets.dart';

import '../common.dart';

const int _kNumIterations = 10;

void main() async {
  // assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  WidgetsFlutterBinding.ensureInitialized();
  final Stopwatch watch = Stopwatch();
  final PlatformAssetBundle bundle = PlatformAssetBundle();

  watch.start();
  for (int i = 0; i < _kNumIterations; i++) {
    bundle.clear();
    await bundle.loadStructuredData('gpay_asset_manifest.json', _manifestParser);
  }
  watch.stop();

  printer.addResult(
    description: 'Load and Parse GPay Asset Manifest',
    value: watch.elapsedMilliseconds.toDouble(),
    unit: 'ms',
    name: 'load_and_parse_gpay_asset_manifest',
  );

  printer.printToStdout();
}

// TODO(andrewkolos): Figure out something more clever and robust 
// than copy-pasting the parser implementation from image_resolution.dart.
Future<Map<String, List<String>>?> _manifestParser(String? jsonData) {
    if (jsonData == null) {
      return SynchronousFuture<Map<String, List<String>>?>(null);
    }
    final Map<String, dynamic> parsedJson = json.decode(jsonData) as Map<String, dynamic>;
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest = <String, List<String>> {
      for (final String key in keys) key: List<String>.from(parsedJson[key] as List<dynamic>),
    };
    return SynchronousFuture<Map<String, List<String>>?>(parsedManifest);
  }
