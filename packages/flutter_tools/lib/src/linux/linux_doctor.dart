// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/io.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../doctor.dart';

/// A validator that checks for Clang and Make build dependencies
class LinuxDoctorValidator extends DoctorValidator {
  LinuxDoctorValidator() : super('Linux toolchain - develop for Linux desktop');

  /// The minimum version of clang supported.
  final Version minimumClangVersion = Version(3, 4, 0);

  @override
  Future<ValidationResult> validate() async {
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
      messages.add(ValidationMessage.error('clang++ is not installed'));
    } else {
      final String firstLine = clangResult.stdout.split('\n').first.trim();
      final String versionString = RegExp(r'[0-9]+\.[0-9]+\.[0-9]+').firstMatch(firstLine).group(0);
      final Version version = Version.parse(versionString);
      if (version >= minimumClangVersion) {
        messages.add(ValidationMessage('clang++ $version'));
      } else {
        validationType = ValidationType.partial;
        messages.add(ValidationMessage.error('clang++ $version is below minimum version of $minimumClangVersion'));
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
      messages.add(ValidationMessage.error('make is not installed'));
    } else {
      final String firstLine = makeResult.stdout.split('\n').first.trim();
      messages.add(ValidationMessage(firstLine));
    }

    return ValidationResult(validationType, messages);
  }
}
