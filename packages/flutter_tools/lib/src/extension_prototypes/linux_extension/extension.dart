// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Linux prototype extension entry point.
///
/// This library defines the entry point for the Linux platform prototype
/// extension, registering all its services with the provider.
library linux_extension.extension;

import 'dart:isolate';

import 'package:file/local.dart';
import 'package:process/process.dart';

import '../../../flutter_tools_extension.dart';
import './build.dart';
import './configuration.dart';
import './device.dart';
import './diagnostics.dart';
import './template.dart';

/// The entry point for the Linux prototype extension.
///
/// This function is run in a separate isolate. It initializes the
/// [ToolExtensionProvider] and registers the various services implemented
/// by the Linux extension (device, diagnostics, configuration, build, artifact, template).
void linuxDeviceExtensionEntryPoint(SendPort hostSendPort) {
  final provider = ToolExtensionProvider(name: 'linux_device_extension', sendPort: hostSendPort);

  provider
    // Register the device service to handle device discovery and lifecycle.
    ..registerService(
      LinuxDeviceService(
        onNotification: (String method, Map<String, Object?> params) {
          provider.sendNotification(method, params);
        },
      ),
    )
    // Register the diagnostics service to handle flutter doctor checks.
    ..registerService(LinuxDiagnosticsService(processManager: const LocalProcessManager()))
    // Register the configuration service to handle custom config options.
    ..registerService(LinuxConfigurationService())
    // Register the build service to handle compilation of the application.
    ..registerService(
      LinuxBuildService(
        fileSystem: const LocalFileSystem(),
        processManager: const LocalProcessManager(),
      ),
    )
    // Register the artifact service to handle downloading of native binaries.
    ..registerService(LinuxArtifactService())
    // Register the template service to handle custom project templates.
    ..registerService(LinuxTemplateService())
    ..initialize();
}
