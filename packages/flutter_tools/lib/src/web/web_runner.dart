// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/context.dart';
import '../base/net.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../project.dart';
import '../resident_runner.dart';

WebRunnerFactory? get webRunnerFactory => context.get<WebRunnerFactory>();

// Hack to hide web imports for google3.
abstract class WebRunnerFactory {
  const WebRunnerFactory();

  /// Create a [ResidentRunner] for the web.
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    required Analytics analytics,
    required BuildSystem buildSystem,
    required BuildTargets buildTargets,
    required DebuggingOptions debuggingOptions,
    required FlutterProject flutterProject,
    required bool stayResident,
    required ToolContext toolContext,
    bool machine = false,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    String? target,
    UrlTunneller? urlTunneller,
    Map<String, String> webDefines,
  });
}
