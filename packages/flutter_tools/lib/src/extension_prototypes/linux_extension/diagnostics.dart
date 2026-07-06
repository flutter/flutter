// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Linux prototype extension diagnostics service.
///
/// This library implements the diagnostics service for the Linux platform
/// prototype extension, checking for required build tools.
library linux_extension.diagnostics;

import 'dart:io';

import 'package:process/process.dart';
import '../../../flutter_tools_extension.dart';

/// Service that performs host diagnostics check on Linux platforms
/// for needed tools (clang++, cmake, ninja).
///
/// This service is registered by the Linux extension and runs diagnostics
/// to ensure the host has the necessary build tools installed for compilation.
final class LinuxDiagnosticsService extends DiagnosticsService {
  LinuxDiagnosticsService({required this.processManager});

  final ProcessManager processManager;

  static const String _clangBinary = 'clang++';
  static const String _cmakeBinary = 'cmake';
  static const String _ninjaBinary = 'ninja';
  static const String _versionFlag = '--version';
  static const String _statusInstalled = 'installed';
  static const String _statusMissing = 'missing';
  static const String _statusError = 'error';

  /// Runs diagnostics check for clang++, cmake, and ninja concurrently.
  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    return Future.wait<ValidationResult>(<Future<ValidationResult>>[
      _checkTool(_clangBinary, const <String>[_versionFlag]),
      _checkTool(_cmakeBinary, const <String>[_versionFlag]),
      _checkTool(_ninjaBinary, const <String>[_versionFlag]),
    ]);
  }

  /// Checks if a tool is installed by running it with the given arguments.
  ///
  /// Returns a [ValidationResult] indicating success if the tool exits with 0,
  /// or missing/error if it fails or is not found.
  Future<ValidationResult> _checkTool(String exe, List<String> args) async {
    try {
      final ProcessResult result = await processManager.run(<String>[exe, ...args]);
      if (result.exitCode == 0) {
        final String stdoutString = (result.stdout as String).trim();
        final String firstLine = stdoutString.split('\n').first.trim();
        return ValidationResult(ValidationType.success, <ValidationMessage>[
          ValidationMessage('$exe version: $firstLine'),
        ], statusInfo: _statusInstalled);
      } else {
        final String stderrString = (result.stderr as String).trim();
        return ValidationResult(ValidationType.missing, <ValidationMessage>[
          ValidationMessage.error('Failed to run $exe: $stderrString'),
        ], statusInfo: _statusError);
      }
    } on Object catch (e) {
      return ValidationResult(ValidationType.missing, <ValidationMessage>[
        ValidationMessage.error('Tool $exe not found or failed to execute: $e'),
      ], statusInfo: _statusMissing);
    }
  }
}
