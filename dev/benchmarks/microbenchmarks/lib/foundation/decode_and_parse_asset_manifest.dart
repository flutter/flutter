// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show AssetManifest, PlatformAssetBundle, rootBundle;
import 'package:flutter/widgets.dart';

import '../common.dart';

const int _kNumIterations = 1000;

Future<void> execute() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final printer = BenchmarkResultPrinter();
  WidgetsFlutterBinding.ensureInitialized();
  final watch = Stopwatch();
  final bundle = rootBundle as PlatformAssetBundle;

  watch.start();
  for (var i = 0; i < _kNumIterations; i++) {
    await AssetManifest.loadFromAssetBundle(bundle);
    bundle.clear();
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
