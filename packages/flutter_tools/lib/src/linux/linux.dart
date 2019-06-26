// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tool_api/doctor.dart';
import 'package:flutter_tool_api/extension.dart';

import '../base/io.dart';
import '../base/version.dart';

class LinuxExtension extends ToolExtension {
  @override
  String get name => 'Linux Desktop';

  @override
  final LinuxDoctorDomain doctorDomain = LinuxDoctorDomain();
}

class LinuxDoctorDomain extends DoctorDomain {
  /// The minimum version of clang supported.
  final Version minimumClangVersion = Version(3, 4, 0);
  static const String kValidatiorName = 'Linux toolchain - develop for Linux desktop';

  @override
  Future<ValidationResult> diagnose(Map<String, Object> arguments) async {
    ValidationType validationType = ValidationType.installed;
    final List<ValidationMessage> messages = <ValidationMessage>[];

    /// Check for a minimum version of Clang.
    ProcessResult clangResult;
    try {
      clangResult = await processManager.run(const <String>[
        'clang++',
        '--version',
      ]);
    } on ArgumentError {
      // ignore error.
    }
    if (clangResult == null || clangResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(const ValidationMessage(
        'clang++ is not installed',
        type: ValidationMessageType.error,
      ));
    } else {
      final String firstLine = clangResult.stdout.split('\n').first.trim();
      final String versionString = RegExp(r'[0-9]+\.[0-9]+\.[0-9]+').firstMatch(firstLine).group(0);
      final Version version = Version.parse(versionString);
      if (version >= minimumClangVersion) {
        messages.add(ValidationMessage('clang++ $version'));
      } else {
        validationType = ValidationType.partial;
        messages.add(ValidationMessage(
          'clang++ $version is below minimum version of $minimumClangVersion',
          type: ValidationMessageType.error,
        ));
      }
    }

    /// Check for make.
    // TODO(jonahwilliams): tighten this check to include a version when we have
    // a better idea about what is supported.
    ProcessResult makeResult;
    try {
      makeResult = await processManager.run(const <String>[
        'make',
        '--version',
      ]);
    } on ArgumentError {
      // ignore error.
    }
    if (makeResult == null || makeResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(const ValidationMessage(
        'make is not installed',
        type: ValidationMessageType.error,
      ));
    } else {
      final String firstLine = makeResult.stdout.split('\n').first.trim();
      messages.add(ValidationMessage(firstLine));
    }

    return ValidationResult(
      type: validationType,
      messages: messages,
      name: kValidatiorName,
    );
  }
}