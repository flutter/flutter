// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
    required Artifacts artifacts,
    required Logger logger,
    required ProcessManager processManager,
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
    final List<String> packageFamilies = <String>[];
    for (final String line in result.stdout.split('\n')) {
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
  Future<String?> getPackageFamilyName(String packageName) async {
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
  Future<int?> launchApp(String packageFamily, List<String> args) async {
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
    final int? processId = int.tryParse(result.stdout.trim());
    _logger.printTrace('Launched application $packageFamily with process ID $processId');
    return processId;
  }

  /// Returns `true` if the specified package signature is valid.
  Future<bool> isSignatureValid(String packagePath) async {
    final List<String> launchCommand = <String>[
      'powershell.exe',
      '-command',
      'if ((Get-AuthenticodeSignature "$packagePath").Status -eq "Valid") { exit 0 } else { exit 1 }'
    ];
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printTrace('Invalid signature found for $packagePath');
      return false;
    }
    _logger.printTrace('Valid signature found for $packagePath');
    return true;
  }

  /// Installs a developer signing certificate.
  ///
  /// Returns `true` on success.
  Future<bool> installCertificate(String certificatePath) async {
    final List<String> launchCommand = <String>[
      'powershell.exe',
      'start',
      'certutil',
      '-argumentlist',
      '\'-addstore TrustedPeople "$certificatePath"\'',
      '-verb',
      'runas'
    ];
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to install certificate $certificatePath');
      return false;
    }
    _logger.printTrace('Waiting for certificate store update');
    // TODO(cbracken): Determine how we can query for success until some timeout.
    // https://github.com/flutter/flutter/issues/82665
    await Future<void>.delayed(const Duration(seconds: 1));
    _logger.printTrace('Installed certificate $certificatePath');
    return true;
  }

  /// Installs the app with the specified build directory.
  ///
  /// Returns `true` on success.
  Future<bool> installApp(String packageUri, List<String> dependencyUris) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      'install',
      packageUri,
    ] + dependencyUris;
    final RunResult result = await _processUtils.run(launchCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to install $packageUri');
      return false;
    }
    _logger.printTrace('Installed application $packageUri');
    return true;
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
    _logger.printTrace('Uninstalled application $packageFamily');
    return true;
  }
}
