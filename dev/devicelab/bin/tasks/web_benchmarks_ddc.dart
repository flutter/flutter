// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/web_benchmarks.dart';

/// Runs all Web benchmarks using DDC.
Future<void> main(List<String> args) async {
  await task(() async {
    return runWebBenchmarkFromArgs((
      useWasm: false,
      forceSingleThreadedSkwasm: false,
      useDdc: true,
      withHotReload: true,
      buildMode: 'debug',
    ), args);
  });
}
