// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../ios/xcodeproj.dart';

const int kXcodeRequiredVersionMajor = 10;
const int kXcodeRequiredVersionMinor = 2;

enum SdkType {
  iPhone,
  iPhoneSimulator,
  macOS,
}

/// SDK name passed to `xcrun --sdk`. Corresponds to undocumented Xcode
/// SUPPORTED_PLATFORMS values.
///
/// Usage: xcrun [options] <tool name> ... arguments ...
/// ...
/// --sdk <sdk name>            find the tool for the given SDK name
String getNameForSdk(SdkType sdk) {
  switch (sdk) {
    case SdkType.iPhone:
      return 'iphoneos';
    case SdkType.iPhoneSimulator:
      return 'iphonesimulator';
    case SdkType.macOS:
      return 'macosx';
  }
  assert(false);
  return null;
}

/// A utility class for interacting with Xcode command line tools.
class Xcode {
  Xcode({
    @required Platform platform,
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required XcodeProjectInterpreter xcodeProjectInterpreter,
  }) : _platform = platform,
       _fileSystem = fileSystem,
       _xcodeProjectInterpreter = xcodeProjectInterpreter,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager);

  final Platform _platform;
  final ProcessUtils _processUtils;
  final FileSystem _fileSystem;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;

  bool get isInstalledAndMeetsVersionCheck => _platform.isMacOS && isInstalled && isVersionSatisfactory;

  String _xcodeSelectPath;
  String get xcodeSelectPath {
    if (_xcodeSelectPath == null) {
      try {
        _xcodeSelectPath = _processUtils.runSync(
          <String>['/usr/bin/xcode-select', '--print-path'],
        ).stdout.trim();
      } on ProcessException {
        // Ignored, return null below.
      } on ArgumentError {
        // Ignored, return null below.
      }
    }
    return _xcodeSelectPath;
  }

  bool get isInstalled {
    if (xcodeSelectPath == null || xcodeSelectPath.isEmpty) {
      return false;
    }
    return _xcodeProjectInterpreter.isInstalled;
  }

  int get majorVersion => _xcodeProjectInterpreter.majorVersion;

  int get minorVersion => _xcodeProjectInterpreter.minorVersion;

  String get versionText => _xcodeProjectInterpreter.versionText;

  bool _eulaSigned;
  /// Has the EULA been signed?
  bool get eulaSigned {
    if (_eulaSigned == null) {
      try {
        final RunResult result = _processUtils.runSync(
          <String>['/usr/bin/xcrun', 'clang'],
        );
        if (result.stdout != null && result.stdout.contains('license')) {
          _eulaSigned = false;
        } else if (result.stderr != null && result.stderr.contains('license')) {
          _eulaSigned = false;
        } else {
          _eulaSigned = true;
        }
      } on ProcessException {
        _eulaSigned = false;
      }
    }
    return _eulaSigned;
  }

  bool _isSimctlInstalled;

  /// Verifies that simctl is installed by trying to run it.
  bool get isSimctlInstalled {
    if (_isSimctlInstalled == null) {
      try {
        // This command will error if additional components need to be installed in
        // xcode 9.2 and above.
        final RunResult result = _processUtils.runSync(
          <String>['/usr/bin/xcrun', 'simctl', 'list'],
        );
        _isSimctlInstalled = result.stderr == null || result.stderr == '';
      } on ProcessException {
        _isSimctlInstalled = false;
      }
    }
    return _isSimctlInstalled;
  }

  bool get isVersionSatisfactory {
    if (!_xcodeProjectInterpreter.isInstalled) {
      return false;
    }
    if (majorVersion > kXcodeRequiredVersionMajor) {
      return true;
    }
    if (majorVersion == kXcodeRequiredVersionMajor) {
      return minorVersion >= kXcodeRequiredVersionMinor;
    }
    return false;
  }

  Future<RunResult> cc(List<String> args) {
    return _processUtils.run(
      <String>['xcrun', 'cc', ...args],
      throwOnError: true,
    );
  }

  Future<RunResult> clang(List<String> args) {
    return _processUtils.run(
      <String>['xcrun', 'clang', ...args],
      throwOnError: true,
    );
  }

  Future<String> sdkLocation(SdkType sdk) async {
    assert(sdk != null);
    final RunResult runResult = await _processUtils.run(
      <String>['xcrun', '--sdk', getNameForSdk(sdk), '--show-sdk-path'],
      throwOnError: true,
    );
    if (runResult.exitCode != 0) {
      throwToolExit('Could not find iPhone SDK location: ${runResult.stderr}');
    }
    return runResult.stdout.trim();
  }

  String getSimulatorPath() {
    if (xcodeSelectPath == null) {
      return null;
    }
    final List<String> searchPaths = <String>[
      _fileSystem.path.join(xcodeSelectPath, 'Applications', 'Simulator.app'),
    ];
    return searchPaths.where((String p) => p != null).firstWhere(
      (String p) => _fileSystem.directory(p).existsSync(),
      orElse: () => null,
    );
  }
}
