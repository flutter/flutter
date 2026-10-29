// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Prototype Linux platform extension package for Flutter tools extensibility.
library flutter_tools_extension_linux_prototype;

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import 'src/build.dart';
import 'src/clean.dart';
import 'src/config.dart';
import 'src/device.dart';
import 'src/diagnostics.dart';
import 'src/template.dart';

/// Isolate entrypoint for the prototype Linux Flutter Tool Extension.
Future<void> linuxExtensionEntryPoint(Object? sendPort) {
  return ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[
      LinuxExtensionDiagnostics(),
      LinuxConfigurationExtension(),
      LinuxTemplateService(),
      LinuxDeviceService(),
      LinuxBuildService(),
      LinuxCleanService(),
    ],
    extensionName: 'flutter_tools_extension_linux_prototype',
    supportedPlatforms: const <String>{'linux'},
    logger: (String message) {
      // ignore: avoid_print
      print('[LinuxExtension] $message');
    },
  );
}
