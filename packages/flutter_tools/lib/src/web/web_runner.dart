// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    final FlutterDevice device, {
    final String? target,
    required final bool stayResident,
    required final FlutterProject flutterProject,
    required final bool? ipv6,
    required final DebuggingOptions debuggingOptions,
    final UrlTunneller? urlTunneller,
    required final Logger logger,
    required final FileSystem fileSystem,
    required final SystemClock systemClock,
    required final Usage usage,
    final bool machine = false,
  });
}
