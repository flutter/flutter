// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../features.dart';
import '../project.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages delegating project-specific `flutter clean` operations to tool extensions.
class ExtensionCleanManager {
  ExtensionCleanManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._logger,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final Logger _logger;

  /// Invokes [CleanService.clean] on all active tool extensions for [project].
  Future<void> cleanProject(FlutterProject project, {required Directory buildDirectory}) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return;
    }

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printWarning('Failed to initialize extension manager for clean: $e');
      return;
    }

    final cleanExtensions = <ExtensionConnection>[
      for (final connection in _extensionManager.connections)
        if (connection.capabilities.services.contains(CleanService.serviceNamespace)) connection,
    ];

    if (cleanExtensions.isEmpty) {
      return;
    }

    final environment = CleanEnvironment(
      buildDir: buildDirectory.absolute.uri,
      projectRoot: project.directory.absolute.uri,
    );

    final Status status = _logger.startProgress('Cleaning extension build artifacts...');
    try {
      for (final connection in cleanExtensions) {
        try {
          await connection.sendRequest(
            CleanService.cleanMethod,
            params: <String, Object?>{CleanService.environmentParam: environment.toMap()},
            // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
            // https://github.com/flutter/flutter/issues/193955.
            timeout: null,
          );
        } on Object catch (e) {
          _logger.printError('Failed to clean extension artifacts: $e');
        }
      }
    } finally {
      status.stop();
    }
  }
}
