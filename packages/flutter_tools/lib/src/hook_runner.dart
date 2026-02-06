// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'asset.dart' show FlutterHookResult;
import 'base/context.dart' show context;
import 'base/logger.dart' show Logger;
import 'build_info.dart' show TargetPlatform;
import 'build_system/build_system.dart' show Environment;

/// To not need `isolated/` imports, we use this interface to be passed around
/// everywhere. It's implementation can run the build and link hooks during a
/// Flutter build/run/test/etc.
FlutterHookRunner? get hookRunner => context.get<FlutterHookRunner>();

abstract interface class FlutterHookRunner {
  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
    Logger? logger,
  });
}
