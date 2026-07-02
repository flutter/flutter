// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:file/local.dart';
import 'package:process/process.dart';

import '../../../flutter_tools_extension.dart';
import './build.dart';
import './configuration.dart';
import './device.dart';
import './diagnostics.dart';

void linuxDeviceExtensionEntryPoint(SendPort hostSendPort) {
  final provider = ToolExtensionProvider(name: 'linux_device_extension', sendPort: hostSendPort);

  provider.registerService(
    LinuxDeviceService(
      onNotification: (String method, Map<String, Object?> params) {
        provider.sendNotification(method, params);
      },
    ),
  );

  provider.registerService(LinuxDiagnosticsService(processManager: const LocalProcessManager()));

  provider.registerService(LinuxConfigurationService());

  provider.registerService(
    LinuxBuildService(
      fileSystem: const LocalFileSystem(),
      processManager: const LocalProcessManager(),
    ),
  );

  provider.registerService(LinuxArtifactService());

  provider.initialize();
}
