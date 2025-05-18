// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/time.dart';
import '../device.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';

WebRunnerFactory? get webRunnerFactory => context.get<WebRunnerFactory>();

// Hack to hide web imports for google3.
abstract class WebRunnerFactory {
  const WebRunnerFactory();

  /// Create a [ResidentRunner] for the web.
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String? target,
    required bool stayResident,
    required FlutterProject flutterProject,
    required DebuggingOptions debuggingOptions,
    UrlTunneller? urlTunneller,
    required Logger logger,
    required FileSystem fileSystem,
    required SystemClock systemClock,
    required Usage usage,
    required Analytics analytics,
    bool machine = false,
  });
}
