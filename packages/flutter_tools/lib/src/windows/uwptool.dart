// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
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
    @required FileSystem fileSystem,
    @required Logger logger,
    @required ProcessManager processManager,
  }) : _artifacts = artifacts,
       _fileSystem = fileSystem,
       _logger = logger,
       _processUtils = ProcessUtils(processManager: processManager, logger: logger);

  final Artifacts _artifacts;
  final FileSystem _fileSystem;
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
    final List<String> packageFamilies = <String>[];
    for (final String line in result.stdout.toString().split('\n')) {
      final String packageFamily = line.trim();
      if (packageFamily.isNotEmpty) {
        packageFamilies.add(packageFamily);
      }
    }
    return packageFamilies;
  }

  /// Returns the package family name for the specified package name.
  ///
  /// If no installed application on the system matches the specified package
  /// name, returns null.
  Future<String/*?*/> getPackageFamilyName(String packageName) async {
    for (final String packageFamily in await listApps()) {
      if (packageFamily.startsWith(packageName)) {
        return packageFamily;
      }
    }
    return null;
  }

  /// Launches the app with the specified package family name.
  ///
  /// On success, returns the process ID of the launched app, otherwise null.
  Future<int/*?*/> launchApp(String packageFamily, List<String> args) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      'launch',
      packageFamily
    ] + args;
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to launch app $packageFamily: ${result.stderr}');
      return null;
    }
    // Read the process ID from stdout.
    return int.tryParse(result.stdout.toString().trim());
  }

  /// Installs the app with the specified build directory.
  ///
  /// Returns `true` on success.
  Future<bool> installApp(String buildDirectory) async {
    final List<String> launchCommand = <String>[
      'powershell.exe',
      _fileSystem.path.join(buildDirectory, 'install.ps1'),
    ];
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError(result.stdout.toString());
      _logger.printError(result.stderr.toString());
    }
    return result.exitCode == 0;
  }

  Future<bool> uninstallApp(String packageFamily) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      'uninstall',
      packageFamily
    ];
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to uninstall $packageFamily');
      return false;
    }
    return true;
  }
}
