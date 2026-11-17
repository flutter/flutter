// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../application_package.dart';
import '../asset.dart';
import '../base/net.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../hook_runner.dart';
import '../project.dart';
import '../resident_runner.dart';

// Hack to hide web imports for google3.
abstract class WebRunnerFactory {
  const WebRunnerFactory();

  /// Create a [ResidentRunner] for the web.
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    required Analytics analytics,
    required ApplicationPackageFactory applicationPackageFactory,
    required AssetBundleFactory assetBundleFactory,
    required BuildSystem buildSystem,
    required BuildTargets buildTargets,
    required DebuggingOptions debuggingOptions,
    required FlutterProject flutterProject,
    required bool stayResident,
    required ToolContext toolContext,
    FlutterHookRunner? flutterHookRunner,
    bool machine = false,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    String? target,
    UrlTunneller? urlTunneller,
    Map<String, String> webDefines,
  });
}
