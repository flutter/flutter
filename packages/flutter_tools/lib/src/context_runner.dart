// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'disabled_usage.dart';
import 'usage.dart';

typedef Future<Null> Runner(List<String> args);

Future<Null> runInContext(List<String> args, Runner runner) {
  final AppContext executableContext = new AppContext();
  executableContext.setVariable(Logger, new StdoutLogger());
  return executableContext.runInZone(() {
    // Initialize the context with some defaults.
    // This list must be kept in sync with lib/executable.dart.
    context.putIfAbsent(BotDetector, () => const BotDetector());
    context.putIfAbsent(Stdio, () => const Stdio());
    context.putIfAbsent(Platform, () => const LocalPlatform());
    context.putIfAbsent(FileSystem, () => const LocalFileSystem());
    context.putIfAbsent(ProcessManager, () => const LocalProcessManager());
    context.putIfAbsent(Logger, () => new StdoutLogger());
    context.putIfAbsent(Cache, () => new Cache());
    context.putIfAbsent(Config, () => new Config());
    context.putIfAbsent(OperatingSystemUtils, () => new OperatingSystemUtils());
    context.putIfAbsent(Usage, () => new DisabledUsage());
    return runner(args);
  });
}
