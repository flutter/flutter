// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/binding.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';

class TestBindings extends Object with BindingBase {
  TestBindings({
    this.verbose = false,
    Platform platform,
    Logger logger,
    OutputPreferences outputPreferences,
    Stopwatch stopwatch,
  })  : _platform = platform,
        logger = logger ?? BufferLogger(),
        outputPreferences = outputPreferences ?? OutputPreferences.test(),
        _stopwatch = stopwatch;

  @override
  final OutputPreferences outputPreferences;

  @override
  final bool verbose;

  @override
  Platform get platform => _platform ?? super.platform;
  final Platform _platform;

  @override
  final Logger logger;

  @override
  Stopwatch createStopwatch() {
    return _stopwatch ?? super.createStopwatch();
  }
  final Stopwatch _stopwatch;
}
