// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:process/process.dart';

import '../base/io.dart';
import '../doctor_validator.dart';

class WindowsVersionValidator extends DoctorValidator {
  const WindowsVersionValidator({required ProcessManager processManager})
      : _processManager = processManager,
        super('Windows Version');

  final ProcessManager _processManager;

  @override
  Future<ValidationResult> validate() async {
    final ProcessResult result = _processManager.runSync(<String>['systeminfo']);
    final String resultStdout = result.stdout as String;

    // Define the major versions that are not supported
    const List<String> unsupportedVersions = <String>[
      '7',
      '8',
    ];

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
    // we report back a valid version
    bool versionText = false;
    bool versionSemver = false;
    String? version;
    for (int i = 0; i < systemInfoElements.length; i++) {
      final String curLine = systemInfoElements.elementAt(i);
      final List<String> lineElems = curLine.split(' ');

      for (int j = 0; j < lineElems.length; j++) {
        final String elem = lineElems.elementAt(j);
        final bool match = regex.hasMatch(lineElems.elementAt(j));

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

    ValidationType windowsVersionStatus = ValidationType.missing;
    String statusInfo;
    if (versionList.length == 1 &&
        !unsupportedVersions
            .contains(versionList.elementAt(0).split('.').elementAt(0))) {
      windowsVersionStatus = ValidationType.installed;
      statusInfo = 'Installed version of Windows is version 10 or higher';
    } else {
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
