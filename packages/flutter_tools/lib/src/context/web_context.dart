// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/net.dart';
import '../build_info.dart';
import '../build_system/tools/shader_compiler.dart';
import '../compile.dart';
import '../device.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../web/chrome.dart';
import '../web/web_debug_config.dart';
import '../web/workflow.dart';
import 'tool_context.dart';

/// Creates a web-backed [FlutterDevice] for [device].
typedef WebFlutterDeviceBuilder = FlutterDevice Function(
  Device device, {
  required BuildInfo buildInfo,
  required DevelopmentShaderCompiler developmentShaderCompiler,
  required FlutterProject flutterProject,
  required ResidentCompiler? generator,
  required TargetPlatform targetPlatform,
  required ToolContext toolContext,
  Map<String, Object?> platformArgs,
  UrlTunneller? urlTunneller,
  String? userIdentifier,
  WebDebugConfig webConfig,
});

/// Holds web-specific dependencies.
class WebContext {
  WebContext({
    required this._chromiumLauncherBuilder,
    required this._webWorkflowBuilder,
    this.webFlutterDeviceBuilder,
  });

  /// Launches and manages Chromium browser instances for web workflows.
  late final ChromiumLauncher chromiumLauncher = _chromiumLauncherBuilder();

  /// Builder for creating web-backed [FlutterDevice] instances when supported by the embedder.
  final WebFlutterDeviceBuilder? webFlutterDeviceBuilder;

  /// Evaluates host readiness and toolchain requirements for web workflows.
  late final WebWorkflow webWorkflow = _webWorkflowBuilder();

  final ChromiumLauncher Function() _chromiumLauncherBuilder;
  final WebWorkflow Function() _webWorkflowBuilder;
}
