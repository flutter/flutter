// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_devicelab/tasks/web_benchmarks.dart';

export 'package:flutter_devicelab/tasks/web_benchmarks.dart'
    show BenchmarkRunner, buildBenchmarkArgParser, runBenchmarkCli;

Future<void> main(List<String> args) async {
  final int exitCode = await runBenchmarkCli(args);
  io.exit(exitCode);
}
