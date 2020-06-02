// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import 'code_signing.dart';
import 'devices.dart';

// Error message patterns from ios-deploy output
const String noProvisioningProfileErrorOne = 'Error 0xe8008015';
const String noProvisioningProfileErrorTwo = 'Error 0xe8000067';
const String deviceLockedError = 'e80000e2';
const String unknownAppLaunchError = 'Error 0xe8000022';

class IOSDeploy {
  IOSDeploy({
    @required Artifacts artifacts,
    @required Cache cache,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
  }) : _platform = platform,
       _cache = cache,
       _processUtils = ProcessUtils(processManager: processManager, logger: logger),
       _logger = logger,
       _binaryPath = artifacts.getArtifactPath(Artifact.iosDeploy, platform: TargetPlatform.ios);

  final Cache _cache;
  final String _binaryPath;
  final Logger _logger;
  final Platform _platform;
  final ProcessUtils _processUtils;

  Map<String, String> get iosDeployEnv {
    // Push /usr/bin to the front of PATH to pick up default system python, package 'six'.
    //
    // ios-deploy transitively depends on LLDB.framework, which invokes a
    // Python script that uses package 'six'. LLDB.framework relies on the
    // python at the front of the path, which may not include package 'six'.
    // Ensure that we pick up the system install of python, which includes it.
    final Map<String, String> environment = Map<String, String>.of(_platform.environment);
    environment['PATH'] = '/usr/bin:${environment['PATH']}';
    environment.addEntries(<MapEntry<String, String>>[_cache.dyLdLibEntry]);
    return environment;
  }

  /// Uninstalls the specified app bundle.
  ///
  /// Uses ios-deploy and returns the exit code.
  Future<int> uninstallApp({
    @required String deviceId,
    @required String bundleId,
  }) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      '--id',
      deviceId,
      '--uninstall_only',
      '--bundle_id',
      bundleId,
    ];

    return _processUtils.stream(
      launchCommand,
      mapFunction: _monitorFailure,
      trace: true,
      environment: iosDeployEnv,
    );
  }

  /// Installs the specified app bundle.
  ///
  /// Uses ios-deploy and returns the exit code.
  Future<int> installApp({
    @required String deviceId,
    @required String bundlePath,
    @required List<String>launchArguments,
    @required IOSDeviceInterface interfaceType,
  }) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      '--id',
      deviceId,
      '--bundle',
      bundlePath,
      if (interfaceType != IOSDeviceInterface.network)
        '--no-wifi',
      if (launchArguments.isNotEmpty) ...<String>[
        '--args',
        launchArguments.join(' '),
      ],
    ];

    return _processUtils.stream(
      launchCommand,
      mapFunction: _monitorFailure,
      trace: true,
      environment: iosDeployEnv,
    );
  }

  /// Installs and then runs the specified app bundle.
  ///
  /// Uses ios-deploy and returns the exit code.
  Future<int> runApp({
    @required String deviceId,
    @required String bundlePath,
    @required List<String> launchArguments,
    @required IOSDeviceInterface interfaceType,
  }) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      '--id',
      deviceId,
      '--bundle',
      bundlePath,
      if (interfaceType != IOSDeviceInterface.network)
        '--no-wifi',
      '--justlaunch',
      if (launchArguments.isNotEmpty) ...<String>[
        '--args',
        launchArguments.join(' '),
      ],
    ];

    return _processUtils.stream(
      launchCommand,
      mapFunction: _monitorFailure,
      trace: true,
      environment: iosDeployEnv,
    );
  }

  Future<bool> isAppInstalled({
    @required String bundleId,
    @required String deviceId,
  }) async {
    final List<String> launchCommand = <String>[
      _binaryPath,
      '--id',
      deviceId,
      '--exists',
      '--timeout', // If the device is not connected, ios-deploy will wait forever.
      '10',
      '--bundle_id',
      bundleId,
    ];
    final RunResult result = await _processUtils.run(
      launchCommand,
      environment: iosDeployEnv,
    );
    // Device successfully connected, but app not installed.
    if (result.exitCode == 255) {
      _logger.printTrace('$bundleId not installed on $deviceId');
      return false;
    }
    if (result.exitCode != 0) {
      _logger.printTrace('App install check failed: ${result.stderr}');
      return false;
    }
    return true;
  }

  // Maps stdout line stream. Must return original line.
  String _monitorFailure(String stdout) {
    // Installation issues.
    if (stdout.contains(noProvisioningProfileErrorOne) || stdout.contains(noProvisioningProfileErrorTwo)) {
      _logger.printError(noProvisioningProfileInstruction, emphasis: true);

    // Launch issues.
    } else if (stdout.contains(deviceLockedError)) {
      _logger.printError('''
═══════════════════════════════════════════════════════════════════════════════════
Your device is locked. Unlock your device first before running.
═══════════════════════════════════════════════════════════════════════════════════''',
      emphasis: true);
    } else if (stdout.contains(unknownAppLaunchError)) {
      _logger.printError('''
═══════════════════════════════════════════════════════════════════════════════════
Error launching app. Try launching from within Xcode via:
    open ios/Runner.xcworkspace

Your Xcode version may be too old for your iOS version.
═══════════════════════════════════════════════════════════════════════════════════''',
      emphasis: true);
    }

    return stdout;
  }
}
