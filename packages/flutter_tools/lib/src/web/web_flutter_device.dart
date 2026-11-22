// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../build_info.dart';
import '../build_system/tools/shader_compiler.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../project.dart';
import '../resident_runner.dart';
import 'web_debug_config.dart';

/// Factory for creating web-backed [FlutterDevice] instances when supported by
/// the embedder.
abstract interface class WebFlutterDeviceFactory {
  /// Creates a [FlutterDevice] configured for running a Flutter web application.
  FlutterDevice createWebFlutterDevice(
    Device device, {
    required BuildInfo buildInfo,
    required DevelopmentShaderCompiler developmentShaderCompiler,
    required FlutterProject flutterProject,
    required ResidentCompiler? generator,
    required TargetPlatform targetPlatform,
    required ToolContext toolContext,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    String? userIdentifier,
    WebDebugConfig webConfig = const WebDebugConfig(),
  });
}
