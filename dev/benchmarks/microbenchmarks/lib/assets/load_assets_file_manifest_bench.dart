// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import '../common.dart';
import './apps/asset_load_app.dart' as app;


Future<void> main() async {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  final Stopwatch watch = Stopwatch()..start();
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  await app.obtainKey();

  printer.addResult(
    description: 'AssetManfiest',
    value:watch.elapsedMilliseconds.toDouble(),
    unit: 'ms',
    name: 'load_assets_file_manifest_bench.dart',
  );
  printer.printToStdout();
}
