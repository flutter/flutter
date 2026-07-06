// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// User-facing API for writing Flutter Tools extensions.
///
/// This library defines the [FlutterToolsExtension] base class that custom
/// platforms extend to integrate with the Flutter tool.
library flutter_tools_extension.extension;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../flutter_tools_core.dart';
import '../../generic_extension_protocol.dart';

/// An annotation used to identify an implementation of [FlutterToolsExtension]
/// as the extension's entrypoint.
const registerExtension = _RegisterExtension();

/// Internal helper class for the [registerExtension] annotation.
final class _RegisterExtension {
  const _RegisterExtension();
}

/// The representation of a Flutter Tools extension.
///
/// Extensions must extend this class and mark it with `@registerExtension`.
/// It provides access to system abstractions (file system, process manager, logger, platform)
/// and allows registering various services (build, device, diagnostics, template, etc.).
abstract base class FlutterToolsExtension {
  FlutterToolsExtension({
    required this.fileSystem,
    required this.logger,
    required this.name,
    required this.platform,
    required this.processManager,
    this.artifactService,
    this.buildService,
    this.configurationService,
    this.deviceService,
    this.diagnosticsService,
    this.templateService,
  });

  /// The name of the extension.
  final String name;

  /// Injected core system abstractions for hermetic testing and decoupled DI.
  final FileSystem fileSystem;
  final ProcessManager processManager;
  final Logger logger;
  final Platform platform;

  /// The service responsible for acquiring the necessary files to develop
  /// and deploy Flutter applications for a custom target platform.
  final ArtifactService? artifactService;

  /// The primary coordinator between the tool and extension compilation logic.
  final BuildService? buildService;

  /// The service responsible for managing custom configuration options for an extension.
  final ConfigurationService? configurationService;

  /// The service responsible for managing custom hardware and emulators.
  final DeviceService? deviceService;

  /// The service responsible for executing custom diagnostic checks that can be reported via `flutter doctor`.
  final DiagnosticsService? diagnosticsService;

  /// The service responsible for adding custom platform support to `flutter create`.
  final TemplateService? templateService;

  /// Initializes the extension and all registered services.
  ///
  /// Returns the capabilities of the extension based on the registered services.
  @mustCallSuper
  Future<FlutterToolExtensionCapabilities> initialize() async {
    await artifactService?.initialize();
    await buildService?.initialize();
    await configurationService?.initialize();
    await deviceService?.initialize();
    await diagnosticsService?.initialize();
    await templateService?.initialize();

    return FlutterToolExtensionCapabilities.fromExtension(this);
  }

  /// Shuts down the extension and all registered services, cleaning up resources.
  @mustCallSuper
  Future<void> shutdown() async {
    await artifactService?.shutdown();
    await buildService?.shutdown();
    await configurationService?.shutdown();
    await deviceService?.shutdown();
    await diagnosticsService?.shutdown();
    await templateService?.shutdown();
  }
}

/// Determines the set of capabilities provided by a [FlutterToolsExtension].
///
/// It scans the extension for non-null services and reports their namespaces
/// as supported capabilities.
final class FlutterToolExtensionCapabilities extends ToolExtensionCapabilities {
  factory FlutterToolExtensionCapabilities.fromExtension(FlutterToolsExtension ext) {
    final services = <String>[];
    if (ext.artifactService != null) {
      services.add(ext.artifactService!.namespace);
    }
    if (ext.buildService != null) {
      services.add(ext.buildService!.namespace);
    }
    if (ext.configurationService != null) {
      services.add(ext.configurationService!.namespace);
    }
    if (ext.deviceService != null) {
      services.add(ext.deviceService!.namespace);
    }
    if (ext.diagnosticsService != null) {
      services.add(ext.diagnosticsService!.namespace);
    }
    if (ext.templateService != null) {
      services.add(ext.templateService!.namespace);
    }
    return FlutterToolExtensionCapabilities._(services);
  }

  const FlutterToolExtensionCapabilities._(List<String> services) : super(services: services);
}
