// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/io.dart';
import '../doctor_validator.dart';

const List<String> unsupportedVersions = <String>[
  '6',
  '7',
  '8',
];

/// Validator to be run with `flutter doctor` to check
/// Windows host machines if they are running supported versions.
class WindowsVersionValidator extends DoctorValidator {
  const WindowsVersionValidator({required ProcessManager processManager})
      : _processManager = processManager,
        super('Windows Version');

  final ProcessManager _processManager;

  @override
  Future<ValidationResult> validate() async {
    final ProcessResult result;
    try {
      result = await _processManager.run(<String>['systeminfo']);
    } on ProcessException {
      return const ValidationResult(
        ValidationType.missing,
        <ValidationMessage>[],
        statusInfo:
            'Unable to run Windows version check using built-in `systeminfo`',
      );
    }

    if (result.exitCode != 0) {
      return const ValidationResult(
        ValidationType.missing,
        <ValidationMessage>[],
        statusInfo: 'Exit status from running `systeminfo` was unsuccessful',
      );
    }

    final String resultStdout = result.stdout as String;

    final List<String> systemInfoElements = resultStdout.split('\n');

    // Regular expression pattern for identifying
    // semantic versioned strings
    // (ie. 10.5.4123)
    final RegExp regex = RegExp(r'^([0-9]+)\.([0-9]+)\.([0-9]+)$');

    // Define the list that will contain the matches;
    // if ran successfully, this list should have only
    // one item
    final List<String> versionList = <String>[];

    // Use two booleans to identify when you have found
    // the word 'version' and a version number that matches
    // the regex pattern above; only once both are found do
    // we add that version to the [versionList]
    bool versionText = false;
    bool versionSemver = false;
    String? version;
    for (final String curLine in systemInfoElements) {
      final List<String> lineElems = curLine.split(' ');

      for (final String elem in lineElems) {
        final bool match = regex.hasMatch(elem);

        if (match) {
          versionSemver = true;
          version = elem;
        }

        if (elem.toLowerCase().contains('version')) {
          versionText = true;
        }
      }

      // Once both booleans are true, add
      // the version to the list that will contain
      // at most, one element if ran as anticipated
      if (versionText && versionSemver && version != null) {
        versionList.add(version);
      }

      // Reset the boolean values for the next line
      versionText = false;
      versionSemver = false;
      version = null;
    }

    final ValidationType windowsVersionStatus;
    String statusInfo;
    if (versionList.length == 1 &&
        !unsupportedVersions
            .contains(versionList.elementAt(0).split('.').elementAt(0))) {
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
