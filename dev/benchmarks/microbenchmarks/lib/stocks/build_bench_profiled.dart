// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';
import 'build_bench.dart';

Future<void> execute() async {
  debugProfileBuildsEnabledUserWidgets = true;
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResultStatistics(
    description: 'Stock build User Widgets Profiled',
    values: await runBuildBenchmark(),
    unit: 'µs per iteration',
    name: 'stock_build_iteration_user_widgets_profiled',
  );
  printer.printToStdout();
}
