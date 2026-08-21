// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Prototype Linux platform extension package for Flutter tools extensibility.
library flutter_tools_extension_linux_prototype;

import 'dart:isolate';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import 'src/diagnostics.dart';

/// Isolate entrypoint for the prototype Linux Flutter Tool Extension.
void linuxExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[LinuxExtensionDiagnostics()],
    supportedPlatforms: const <String>{'linux'},
    logger: (String message) {
      // ignore: avoid_print
      print('[LinuxExtension] $message');
    },
  );
}
