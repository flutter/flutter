// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/context.dart';
import '../base/net.dart';
import '../device.dart';
import '../project.dart';
import '../resident_runner.dart';

WebRunnerFactory get webRunnerFactory => context.get<WebRunnerFactory>();

// Hack to hide web imports for google3.
abstract class WebRunnerFactory {
  const WebRunnerFactory();

  /// Create a [ResidentRunner] for the web.
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String target,
    @required bool stayResident,
    @required FlutterProject flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    @required UrlTunneller urlTunneller,
    bool machine = false,
  });
}
