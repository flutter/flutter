// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/logger.dart';
import '../base/process.dart';

/// The uwptool command-line tool.
///
/// `uwptool` is a host utility command-line tool that supports a variety of
/// actions related to Universal Windows Platform (UWP) applications, including
/// installing and uninstalling apps, querying installed apps, and launching
/// apps.
class UwpTool {
  UwpTool({
    @required Artifacts artifacts,
    @required Logger logger,
    @required ProcessManager processManager,
  }) : _artifacts = artifacts,
       _logger = logger,
       _processUtils = ProcessUtils(processManager: processManager, logger: logger);

  final Artifacts _artifacts;
  final Logger _logger;
  final ProcessUtils _processUtils;

  String get _binaryPath  => _artifacts.getArtifactPath(Artifact.uwptool);

  Future<List<String>> listApps() async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      'listapps',
    ];
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to list installed UWP apps: ${result.stderr}');
      return <String>[];
    }
    final List<String> appIds = <String>[];
    for (final String line in result.stdout.toString().split('\n')) {
      final String appId = line.trim();
      if (appId.isNotEmpty) {
        appIds.add(appId);
      }
    }
    return appIds;
  }

  /// Returns the app ID for the specified package ID.
  ///
  /// If no installed application on the system matches the specified GUID,
  /// returns null.
  Future<String/*?*/> getAppIdFromPackageId(String packageId) async {
    for (final String appId in await listApps()) {
      if (appId.startsWith(packageId)) {
        return appId;
      }
    }
    return null;
  }

  /// Launches the app with the specified app ID.
  ///
  /// On success, returns the process ID of the launched app, otherwise null.
  Future<int/*?*/> launchApp(String appId, List<String> args) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      'launch',
      appId
    ] + args;
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to launch app $appId: ${result.stderr}');
      return null;
    }
    // Read the process ID from stdout.
    return int.tryParse(result.stdout.toString().trim());
  }
}
