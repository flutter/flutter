// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../ios/xcodeproj.dart';

const int kXcodeRequiredVersionMajor = 9;
const int kXcodeRequiredVersionMinor = 0;

Xcode get xcode => context.get<Xcode>();

class Xcode {
  bool get isInstalledAndMeetsVersionCheck => platform.isMacOS && isInstalled && isVersionSatisfactory;

  String _xcodeSelectPath;
  String get xcodeSelectPath {
    if (_xcodeSelectPath == null) {
      try {
        _xcodeSelectPath = processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']).stdout.trim();
      } on ProcessException {
        // Ignored, return null below.
      } on ArgumentError {
        // Ignored, return null below.
      }
    }
    return _xcodeSelectPath;
  }

  bool get isInstalled {
    if (xcodeSelectPath == null || xcodeSelectPath.isEmpty)
      return false;
    return xcodeProjectInterpreter.isInstalled;
  }

  int get majorVersion => xcodeProjectInterpreter.majorVersion;

  int get minorVersion => xcodeProjectInterpreter.minorVersion;

  String get versionText => xcodeProjectInterpreter.versionText;

  bool _eulaSigned;
  /// Has the EULA been signed?
  bool get eulaSigned {
    if (_eulaSigned == null) {
      try {
        final ProcessResult result = processManager.runSync(<String>['/usr/bin/xcrun', 'clang']);
        if (result.stdout != null && result.stdout.contains('license'))
          _eulaSigned = false;
        else if (result.stderr != null && result.stderr.contains('license'))
          _eulaSigned = false;
        else
          _eulaSigned = true;
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
        final ProcessResult result = processManager.runSync(<String>['/usr/bin/xcrun', 'simctl', 'list']);
        _isSimctlInstalled = result.stderr == null || result.stderr == '';
      } on ProcessException {
        _isSimctlInstalled = false;
      }
    }
    return _isSimctlInstalled;
  }

  bool get isVersionSatisfactory {
    if (!xcodeProjectInterpreter.isInstalled)
      return false;
    if (majorVersion > kXcodeRequiredVersionMajor)
      return true;
    if (majorVersion == kXcodeRequiredVersionMajor)
      return minorVersion >= kXcodeRequiredVersionMinor;
    return false;
  }

  Future<RunResult> cc(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'cc', ...args]);
  }

  Future<RunResult> clang(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'clang', ...args]);
  }

  Future<RunResult> dsymutil(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'dsymutil', ...args]);
  }

  Future<RunResult> strip(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'strip', ...args]);
  }

  Future<RunResult> otool(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'otool', ...args]);
  }

  String getSimulatorPath() {
    if (xcodeSelectPath == null)
      return null;
    final List<String> searchPaths = <String>[
      fs.path.join(xcodeSelectPath, 'Applications', 'Simulator.app'),
    ];
    return searchPaths.where((String p) => p != null).firstWhere(
      (String p) => fs.directory(p).existsSync(),
      orElse: () => null,
    );
  }
}
