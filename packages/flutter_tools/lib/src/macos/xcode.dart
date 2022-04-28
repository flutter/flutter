// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../ios/xcodeproj.dart';

Version get xcodeRequiredVersion => Version(13, null, null);

/// Diverging this number from the minimum required version will provide a doctor
/// warning, not error, that users should upgrade Xcode.
Version get xcodeRecommendedVersion => xcodeRequiredVersion;

/// SDK name passed to `xcrun --sdk`. Corresponds to undocumented Xcode
/// SUPPORTED_PLATFORMS values.
///
/// Usage: xcrun [options] <tool name> ... arguments ...
/// ...
/// --sdk <sdk name>            find the tool for the given SDK name.
String getSDKNameForIOSEnvironmentType(EnvironmentType environmentType) {
  return (environmentType == EnvironmentType.simulator)
      ? 'iphonesimulator'
      : 'iphoneos';
}

/// A utility class for interacting with Xcode command line tools.
class Xcode {
  Xcode({
    required Platform platform,
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required XcodeProjectInterpreter xcodeProjectInterpreter,
  })  : _platform = platform,
        _fileSystem = fileSystem,
        _xcodeProjectInterpreter = xcodeProjectInterpreter,
        _processUtils =
            ProcessUtils(logger: logger, processManager: processManager);

  /// Create an [Xcode] for testing.
  ///
  /// Defaults to a memory file system, fake platform,
  /// buffer logger, and test [XcodeProjectInterpreter].
  @visibleForTesting
  factory Xcode.test({
    required ProcessManager processManager,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
    Platform? platform,
    FileSystem? fileSystem,
  }) {
    platform ??= FakePlatform(
      operatingSystem: 'macos',
      environment: <String, String>{},
    );
    return Xcode(
      platform: platform,
      processManager: processManager,
      fileSystem: fileSystem ?? MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      xcodeProjectInterpreter: xcodeProjectInterpreter ?? XcodeProjectInterpreter.test(processManager: processManager),
    );
  }

  final Platform _platform;
  final ProcessUtils _processUtils;
  final FileSystem _fileSystem;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;

  bool get isInstalledAndMeetsVersionCheck => _platform.isMacOS && isInstalled && isRequiredVersionSatisfactory;

  String? _xcodeSelectPath;
  String? get xcodeSelectPath {
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

  bool get isInstalled => _xcodeProjectInterpreter.isInstalled;

  Version? get currentVersion => _xcodeProjectInterpreter.version;

  String? get versionText => _xcodeProjectInterpreter.versionText;

  bool? _eulaSigned;
  /// Has the EULA been signed?
  bool get eulaSigned {
    if (_eulaSigned == null) {
      try {
        final RunResult result = _processUtils.runSync(
          <String>[...xcrunCommand(), 'clang'],
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
    return _eulaSigned ?? false;
  }

  bool? _isSimctlInstalled;

  /// Verifies that simctl is installed by trying to run it.
  bool get isSimctlInstalled {
    if (_isSimctlInstalled == null) {
      try {
        // This command will error if additional components need to be installed in
        // xcode 9.2 and above.
        final RunResult result = _processUtils.runSync(
          <String>[...xcrunCommand(), 'simctl', 'list'],
        );
        _isSimctlInstalled = result.exitCode == 0;
      } on ProcessException {
        _isSimctlInstalled = false;
      }
    }
    return _isSimctlInstalled ?? false;
  }

  bool get isRequiredVersionSatisfactory {
    final Version? version = currentVersion;
    if (version == null) {
      return false;
    }
    return version >= xcodeRequiredVersion;
  }

  bool get isRecommendedVersionSatisfactory {
    final Version? version = currentVersion;
    if (version == null) {
      return false;
    }
    return version >= xcodeRecommendedVersion;
  }

  /// See [XcodeProjectInterpreter.xcrunCommand].
  List<String> xcrunCommand() => _xcodeProjectInterpreter.xcrunCommand();

  Future<RunResult> cc(List<String> args) {
    return _processUtils.run(
      <String>[...xcrunCommand(), 'cc', ...args],
      throwOnError: true,
    );
  }

  Future<RunResult> clang(List<String> args) {
    return _processUtils.run(
      <String>[...xcrunCommand(), 'clang', ...args],
      throwOnError: true,
    );
  }

  Future<String> sdkLocation(EnvironmentType environmentType) async {
    assert(environmentType != null);
    final RunResult runResult = await _processUtils.run(
      <String>[...xcrunCommand(), '--sdk', getSDKNameForIOSEnvironmentType(environmentType), '--show-sdk-path'],
    );
    if (runResult.exitCode != 0) {
      throwToolExit('Could not find SDK location: ${runResult.stderr}');
    }
    return runResult.stdout.trim();
  }

  String? getSimulatorPath() {
    final String? selectPath = xcodeSelectPath;
    if (selectPath == null) {
      return null;
    }
    final String appPath = _fileSystem.path.join(selectPath, 'Applications', 'Simulator.app');
    return _fileSystem.directory(appPath).existsSync() ? appPath : null;
  }
}

EnvironmentType? environmentTypeFromSdkroot(String sdkroot, FileSystem fileSystem) {
  assert(sdkroot != null);
  // iPhoneSimulator.sdk or iPhoneOS.sdk
  final String sdkName = fileSystem.path.basename(sdkroot).toLowerCase();
  if (sdkName.contains('iphone')) {
    return sdkName.contains('simulator') ? EnvironmentType.simulator : EnvironmentType.physical;
  }
  assert(false);
  return null;
}
