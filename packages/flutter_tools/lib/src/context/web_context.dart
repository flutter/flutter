// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../resident_runner.dart';
library;

import '../web/chrome.dart';
import '../web/web_flutter_device.dart';
import '../web/workflow.dart';

/// Holds web-specific dependencies.
class WebContext {
  WebContext({
    required this._chromiumLauncherBuilder,
    required this._webWorkflowBuilder,
    this.webFlutterDeviceFactory,
  });

  /// Launches and manages Chromium browser instances for web workflows.
  late final ChromiumLauncher chromiumLauncher = _chromiumLauncherBuilder();

  /// Factory for creating web-backed [FlutterDevice] instances when supported by the embedder.
  final WebFlutterDeviceFactory? webFlutterDeviceFactory;

  /// Evaluates host readiness and toolchain requirements for web workflows.
  late final WebWorkflow webWorkflow = _webWorkflowBuilder();

  final ChromiumLauncher Function() _chromiumLauncherBuilder;
  final WebWorkflow Function() _webWorkflowBuilder;
}
