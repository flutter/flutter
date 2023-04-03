// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/io.dart';
import '../doctor_validator.dart';

/// Flutter only supports development on Windows host machines version 10 and greater.
const List<String> kUnsupportedVersions = <String>[
  '6',
  '7',
  '8',
];

/// Regex pattern for identifying line from systeminfo stdout with windows version
/// (ie. 10.5.4123)
const String kWindowsOSVersionSemVerPattern =
    r'^(OS Version:\s*)([0-9]+\.[0-9]+\.[0-9]+)(.*)$';

/// Validator for supported Windows host machine operating system version.
class WindowsVersionValidator extends DoctorValidator {
  const WindowsVersionValidator({required ProcessManager processManager})
      : _processManager = processManager,
        super('Windows Version');

  final ProcessManager _processManager;

  @override
  Future<ValidationResult> validate() async {
    final ProcessResult result =
        await _processManager.run(<String>['systeminfo']);

    if (result.exitCode != 0) {
      return const ValidationResult(
        ValidationType.missing,
        <ValidationMessage>[],
        statusInfo: 'Exit status from running `systeminfo` was unsuccessful',
      );
    }

    final String resultStdout = result.stdout as String;

    final RegExp regex =
        RegExp(kWindowsOSVersionSemVerPattern, multiLine: true);
    final Iterable<RegExpMatch> matches = regex.allMatches(resultStdout);

    // Use the string split method to extract the major version
    // and check against the [kUnsupportedVersions] list
    final ValidationType windowsVersionStatus;
    final String statusInfo;
    if (matches.length == 1 &&
        !kUnsupportedVersions
            .contains(matches.elementAt(0).group(2)?.split('.').elementAt(0))) {
      windowsVersionStatus = ValidationType.installed;
      statusInfo = 'Installed version of Windows is version 10 or higher';
    } else {
      windowsVersionStatus = ValidationType.missing;
      statusInfo =
          'Unable to confirm if installed Windows version is 10 or greater';
    }

    return ValidationResult(
      windowsVersionStatus,
      const <ValidationMessage>[],
      statusInfo: statusInfo,
    );
  }
}
